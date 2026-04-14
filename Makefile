SHELL := /bin/sh

.PHONY: prepare build up down logs ps migrate migrate-auth migrate-restapi migrate-herald migrate-katara migrate-slacker migrate-jira-bus

prepare:
	@test -f .env || cp .env.example .env
	@set -a; . ./.env; set +a; python3 tools/render_local_config.py docker/local/config.yaml.tpl docker/local/config.yaml

build: prepare
	docker compose build

up: prepare
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f --tail=200

ps:
	docker compose ps

migrate: migrate-auth migrate-restapi migrate-herald migrate-katara migrate-slacker migrate-jira-bus

migrate-auth:
	docker compose exec auth sh -lc 'python -c "from auth.auth_server.migrate import ConfigTemplate; import os; ConfigTemplate().save(\"mariadb\", os.environ[\"MARIADB_USER\"], os.environ[\"MARIADB_PASSWORD\"], \"auth-db\")" && cd /usr/src/app/auth/auth_server && alembic -c alembic.ini upgrade head'

migrate-restapi:
	docker compose exec restapi sh -lc 'python -c "from rest_api.rest_api_server.migrate import ConfigTemplate; import os; ConfigTemplate().save(\"mariadb\", os.environ[\"MARIADB_USER\"], os.environ[\"MARIADB_PASSWORD\"], \"my-db\")" && cd /usr/src/app/rest_api/rest_api_server && alembic -c alembic.ini upgrade head'

migrate-herald:
	docker compose exec herald-api sh -lc 'python -c "from herald.herald_server.migrate import ConfigTemplate; import os; ConfigTemplate().save(\"mariadb\", os.environ[\"MARIADB_USER\"], os.environ[\"MARIADB_PASSWORD\"], \"herald\")" && cd /usr/src/app/herald/herald_server && alembic -c alembic.ini upgrade head'

migrate-katara:
	docker compose exec katara sh -lc 'python -c "from katara.katara_service.migrate import ConfigTemplate; import os; ConfigTemplate().save(\"mariadb\", os.environ[\"MARIADB_USER\"], os.environ[\"MARIADB_PASSWORD\"], \"katara\")" && cd /usr/src/app/katara/katara_service && alembic -c alembic.ini upgrade head'

migrate-slacker:
	docker compose exec slacker sh -lc 'python -c "from slacker.slacker_server.migrate import ConfigTemplate; import os; ConfigTemplate().save(\"mariadb\", os.environ[\"MARIADB_USER\"], os.environ[\"MARIADB_PASSWORD\"], \"slacker\")" && cd /src/slacker/slacker_server && alembic -c alembic.ini upgrade head'

migrate-jira-bus:
	docker compose exec jira-bus sh -lc 'python -c "from jira_bus.jira_bus_server.migrate import ConfigTemplate; import os; ConfigTemplate().save(\"mariadb\", os.environ[\"MARIADB_USER\"], os.environ[\"MARIADB_PASSWORD\"], \"jira-bus\")" && cd /usr/src/app/jira_bus/jira_bus_server && alembic -c alembic.ini upgrade head'
