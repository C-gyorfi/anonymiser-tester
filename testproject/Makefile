.PHONY: db-up db-down db-logs db-shell db-reset db-schema-dump setup run-server migrate make-migrations create-superuser pagila-load gm-up gm-dump

DB_NAME=anonymiser-tester-db
DB_USER=testuser
DB_PASSWORD=testpass
DB_CONTAINER=anonymiser-tester
DB_PORT=5432

# Greenmask spike: a long-running container; gm-dump writes $(GM_DIR)/dump.sql
GM_DIR=greenmask-spike
GM_IMAGE=greenmask/greenmask:latest
GM_CONTAINER=greenmask-spike

db-up:
	docker run -d \
		--name $(DB_CONTAINER) \
		-e POSTGRES_DB=$(DB_NAME) \
		-e POSTGRES_USER=$(DB_USER) \
		-e POSTGRES_PASSWORD=$(DB_PASSWORD) \
		-p $(DB_PORT):5432 \
		pgvector/pgvector:pg18

db-down:
	docker stop $(DB_CONTAINER) || true
	docker rm $(DB_CONTAINER) || true

db-logs:
	docker logs -f $(DB_CONTAINER)

db-shell:
	docker exec -it $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME)

db-reset: db-down db-up

db-schema-dump:
	docker exec $(DB_CONTAINER) pg_dump -U $(DB_USER) -d $(DB_NAME) --schema-only --no-owner --no-privileges -T 'auth_*' -T 'django_*' > schema.sql

setup: db-up
	poetry install

run-server:
	poetry run python manage.py runserver

migrate:
	poetry run python manage.py migrate

make-migrations:
	poetry run python manage.py makemigrations

create-superuser:
	DJANGO_SUPERUSER_USERNAME=admin \
	DJANGO_SUPERUSER_PASSWORD=securepass \
	DJANGO_SUPERUSER_EMAIL=admin@example.com \
	poetry run python manage.py createsuperuser --noinput

pagila-load:
	@test -f pagila/pagila-schema.sql || bash scripts/download-pagila.sh
	bash scripts/load-pagila.sh

gm-up:
	-docker rm -f $(GM_CONTAINER)
	docker run -d --name $(GM_CONTAINER) \
		--add-host=host.docker.internal:host-gateway \
		-v $(CURDIR)/$(GM_DIR):/spike -w /spike \
		-e PGPASSWORD=$(DB_PASSWORD) -e DB_HOST=host.docker.internal \
		-e DB_PORT=$(DB_PORT) -e DB_USER=$(DB_USER) -e DB_NAME=$(DB_NAME) \
		--entrypoint sleep $(GM_IMAGE) infinity

gm-dump:
	docker exec $(GM_CONTAINER) mkdir -p /tmp/dumps
	docker exec $(GM_CONTAINER) greenmask --config config.yml dump
	docker exec $(GM_CONTAINER) sh -c 'pg_restore --no-owner --no-privileges -f /spike/dump.sql /tmp/dumps/$$(ls /tmp/dumps | tail -1)'
