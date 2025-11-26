defmodule PhoenixApi.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PhoenixApi.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        birthdate: ~D[2000-01-01],
        first_name: "some first_name",
        gender: :male,
        last_name: "some last_name"
      })
      |> PhoenixApi.Accounts.create_user()

    user
  end
end
