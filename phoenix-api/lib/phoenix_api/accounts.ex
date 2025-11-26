defmodule PhoenixApi.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias PhoenixApi.Repo

  alias PhoenixApi.Accounts.User


  alias PhoenixApi.Accounts.DataImport

  @doc """
  Returns the list of users with filtering, sorting and pagination.
  """
  def list_users(params \\ %{}) do
    query =
      User
      |> filter_by_first_name(params)
      |> filter_by_last_name(params)
      |> filter_by_gender(params)
      |> filter_by_birthdate(params)
      |> sort_users(params)

    total_count = Repo.aggregate(query, :count, :id)
    
    users = 
      query
      |> paginate_users(params)
      |> Repo.all()

    %{data: users, total_count: total_count, page: get_page(params), page_size: get_page_size(params)}
  end

  defp filter_by_first_name(query, %{"first_name" => name}) when is_binary(name) and name != "" do
    where(query, [u], ilike(u.first_name, ^"%#{name}%"))
  end
  defp filter_by_first_name(query, _), do: query

  defp filter_by_last_name(query, %{"last_name" => name}) when is_binary(name) and name != "" do
    where(query, [u], ilike(u.last_name, ^"%#{name}%"))
  end
  defp filter_by_last_name(query, _), do: query

  defp filter_by_gender(query, %{"gender" => gender}) when gender in ["male", "female"] do
    where(query, [u], u.gender == ^String.to_existing_atom(gender))
  end
  defp filter_by_gender(query, _), do: query

  defp filter_by_birthdate(query, params) do
    query
    |> filter_birthdate_from(params)
    |> filter_birthdate_to(params)
  end

  defp filter_birthdate_from(query, %{"birthdate_from" => date}) when is_binary(date) and date != "" do
    where(query, [u], u.birthdate >= ^Date.from_iso8601!(date))
  rescue
    _ -> query
  end
  defp filter_birthdate_from(query, _), do: query

  defp filter_birthdate_to(query, %{"birthdate_to" => date}) when is_binary(date) and date != "" do
    where(query, [u], u.birthdate <= ^Date.from_iso8601!(date))
  rescue
    _ -> query
  end
  defp filter_birthdate_to(query, _), do: query

  defp sort_users(query, %{"sort" => sort, "direction" => direction}) 
       when sort in ["first_name", "last_name", "birthdate", "gender", "id"] and direction in ["asc", "desc"] do
    order_by(query, [u], [{^String.to_existing_atom(direction), field(u, ^String.to_existing_atom(sort))}])
  end
  defp sort_users(query, _), do: order_by(query, [u], asc: u.id)

  defp paginate_users(query, params) do
    page = get_page(params)
    page_size = get_page_size(params)
    offset = (page - 1) * page_size

    query
    |> limit(^page_size)
    |> offset(^offset)
  end

  defp get_page(%{"page" => page}) do
    case Integer.parse(to_string(page)) do
      {p, _} when p > 0 -> p
      _ -> 1
    end
  end
  defp get_page(_), do: 1

  defp get_page_size(%{"page_size" => size}) do
    case Integer.parse(to_string(size)) do
      {s, _} when s > 0 -> s
      _ -> 10
    end
  end
  defp get_page_size(_), do: 10

  def import_users(count \\ 100) do
    users_data = DataImport.generate_users(count)
    
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    users_data = Enum.map(users_data, fn u -> 
      Map.merge(u, %{inserted_at: now, updated_at: now})
    end)

    {count, _} = Repo.insert_all(User, users_data)
    {:ok, count}
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end
end
