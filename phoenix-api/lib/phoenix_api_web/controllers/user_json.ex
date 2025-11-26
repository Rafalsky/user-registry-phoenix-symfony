defmodule PhoenixApiWeb.UserJSON do
  alias PhoenixApi.Accounts.User

  @doc """
  Renders a list of users.
  """
  def index(%{page: page}) do
    %{
      data: for(user <- page.data, do: data(user)),
      meta: %{
        total_count: page.total_count,
        page: page.page,
        page_size: page.page_size
      }
    }
  end

  @doc """
  Renders a single user.
  """
  def show(%{user: user}) do
    %{data: data(user)}
  end

  defp data(%User{} = user) do
    %{
      id: user.id,
      first_name: user.first_name,
      last_name: user.last_name,
      birthdate: user.birthdate,
      gender: user.gender
    }
  end
end
