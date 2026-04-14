FROM python:3.12.11-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
LABEL org.opencontainers.image.authors="Hystax"

WORKDIR /usr/src/app/
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/usr/src/app

COPY optscale_client optscale_client

COPY metroculus/__init__.py metroculus/
COPY metroculus/metroculus_scheduler/pyproject.toml metroculus/metroculus_scheduler/
COPY metroculus/metroculus_scheduler/uv.lock metroculus/metroculus_scheduler/
COPY metroculus/metroculus_scheduler/*.py ./metroculus/metroculus_scheduler/

RUN uv --project metroculus/metroculus_scheduler sync --locked --no-dev --no-install-project

CMD ["uv", "run", "--project", "metroculus/metroculus_scheduler", "python", "-u","/usr/src/app/metroculus/metroculus_scheduler/main.py"]
