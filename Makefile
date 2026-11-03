.PHONY: db-up db-down db-logs db-shell db-reset db-schema-dump setup run-server migrate make-migrations create-superuser

DB_NAME=anonymiser-tester-db
DB_USER=testuser
DB_PASSWORD=testpass
DB_CONTAINER=anonymiser-tester
DB_PORT=5432

db-up:
	docker run -d \
		--name $(DB_CONTAINER) \
		-e POSTGRES_DB=$(DB_NAME) \
		-e POSTGRES_USER=$(DB_USER) \
		-e POSTGRES_PASSWORD=$(DB_PASSWORD) \
		-p $(DB_PORT):5432 \
		postgres:17

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
