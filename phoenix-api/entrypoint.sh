#!/bin/bash
# entrypoint.sh

# Wait for Postgres to be ready (although depends_on handles this mostly, double check is good)
# But we rely on docker-compose depends_on condition: service_healthy

echo "Installing dependencies..."
mix deps.get

echo "Running migrations..."
mix ecto.create
mix ecto.migrate

echo "Running seeds..."
mix run priv/repo/seeds.exs

echo "Importing initial users from gov.pl..."
# Import 100 users if database is empty or has only seed users
USER_COUNT=$(mix run -e "IO.puts PhoenixApi.Repo.aggregate(PhoenixApi.Accounts.User, :count, :id)")
if [ "$USER_COUNT" -le 3 ]; then
  echo "Database empty or has only seed users, importing 100 users..."
  mix run -e "PhoenixApi.Accounts.import_users(100) |> elem(1) |> IO.inspect(label: \"Imported\")"
else
  echo "Database already populated with $USER_COUNT users, skipping import"
fi

echo "Starting Phoenix server..."
exec mix phx.server
