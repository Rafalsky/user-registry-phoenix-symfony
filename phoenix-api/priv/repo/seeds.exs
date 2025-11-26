# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     PhoenixApi.Repo.insert!(%PhoenixApi.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias PhoenixApi.Repo
alias PhoenixApi.Accounts.User
import Ecto.Query

users = [
  %{
    first_name: "Jan",
    last_name: "Kowalski",
    birthdate: ~D[1980-01-01],
    gender: :male
  },
  %{
    first_name: "Anna",
    last_name: "Nowak",
    birthdate: ~D[1990-05-15],
    gender: :female
  },
  %{
    first_name: "Piotr",
    last_name: "Wiśniewski",
    birthdate: ~D[1985-11-20],
    gender: :male
  }
]

Enum.each(users, fn user_attrs ->
  # Check if user already exists
  existing = Repo.one(
    from u in User,
    where: u.first_name == ^user_attrs.first_name and u.last_name == ^user_attrs.last_name,
    limit: 1
  )

  if is_nil(existing) do
    case Repo.insert(%User{
      first_name: user_attrs.first_name,
      last_name: user_attrs.last_name,
      birthdate: user_attrs.birthdate,
      gender: user_attrs.gender
    }) do
      {:ok, _user} -> IO.puts("Inserted user: #{user_attrs.first_name} #{user_attrs.last_name}")
      {:error, changeset} -> IO.puts("Failed to insert user: #{inspect(changeset.errors)}")
    end
  else
    IO.puts("User already exists: #{user_attrs.first_name} #{user_attrs.last_name}")
  end
end)

