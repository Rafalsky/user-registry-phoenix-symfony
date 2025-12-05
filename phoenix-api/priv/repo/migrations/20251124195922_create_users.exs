defmodule PhoenixApi.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :first_name, :string
      add :last_name, :string
      add :birthdate, :date
      add :gender, :string

      timestamps(type: :utc_datetime)
    end

    create index(:users, [:first_name])
    create index(:users, [:last_name])
    create index(:users, [:birthdate])
    create index(:users, [:gender])
  end
end
