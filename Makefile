.PHONY: db-up db-down db-logs db-shell db-reset runserver migrate makemigrations

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

run-server:
	poetry run python manage.py runserver

migrate:
	poetry run python manage.py migrate

make-migrations:
	poetry run python manage.py makemigrations
