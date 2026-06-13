FROM python:3.12-slim AS builder

RUN apt-get update && \
    apt-get install -y gcc libpq-dev && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip setuptools wheel

COPY requirements.txt /app/requirements.txt
RUN pip install --prefix=/install -r /app/requirements.txt

FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1

# pg_dump must be >= the server's major version. Targets are now PostgreSQL 18
# (Railway provisions PG 18.x), so Debian's default postgresql-client (17 on
# trixie) fails with "server version mismatch". Pull postgresql-client-18 from
# the official PGDG apt repo. Bump this when target servers move to PG 19+.
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates gnupg gzip && \
    install -d /usr/share/postgresql-common/pgdg && \
    curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc && \
    echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(. /etc/os-release && echo $VERSION_CODENAME)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client-18 && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /install /usr/local

COPY main.py /app/main.py

WORKDIR /app

CMD ["python", "main.py"]
