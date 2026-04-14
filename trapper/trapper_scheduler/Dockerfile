FROM python:3.12.11-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
LABEL org.opencontainers.image.authors="Hystax"

WORKDIR /usr/src/app/
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/usr/src/app

COPY optscale_client optscale_client

COPY trapper/__init__.py ./trapper/
COPY trapper/trapper_scheduler/pyproject.toml ./trapper/trapper_scheduler/
COPY trapper/trapper_scheduler/uv.lock ./trapper/trapper_scheduler/
COPY trapper/trapper_scheduler/*.py ./trapper/trapper_scheduler/

RUN uv --project trapper/trapper_scheduler sync --locked --no-dev --no-install-project
CMD ["uv", "run", "--project", "trapper/trapper_scheduler", "python", "-u","/usr/src/app/trapper/trapper_scheduler/main.py"]
