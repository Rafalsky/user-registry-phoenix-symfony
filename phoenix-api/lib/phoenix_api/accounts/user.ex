defmodule PhoenixApi.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :first_name, :string
    field :last_name, :string
    field :birthdate, :date
    field :gender, Ecto.Enum, values: [:male, :female]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :birthdate, :gender])
    |> validate_required([:first_name, :last_name, :birthdate, :gender])
    |> validate_birthdate()
  end

  defp validate_birthdate(changeset) do
    validate_change(changeset, :birthdate, fn :birthdate, date ->
      cond do
        Date.compare(date, ~D[2024-12-31]) == :gt -> [birthdate: "must be on or before 2024-12-31"]
        Date.compare(date, ~D[1900-01-01]) == :lt -> [birthdate: "must be after 1900-01-01"]
        true -> []
      end
    end)
  end
end
