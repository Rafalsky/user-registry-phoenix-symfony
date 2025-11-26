.PHONY: up down test-phoenix test-symfony test-all import-users

up:
	docker-compose up --build -d

down:
	docker-compose down

test-phoenix:
	docker-compose run --rm phoenix sh -c "mix ecto.create && mix ecto.migrate && mix test"

test-symfony:
	docker-compose run --rm symfony php bin/phpunit

test-all: test-phoenix test-symfony

import-users:
	curl -X POST http://localhost:4000/api/import -H "x-api-token: secret-token"
