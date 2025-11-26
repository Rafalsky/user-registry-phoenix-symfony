defmodule PhoenixApiWeb.ImportController do
  use PhoenixApiWeb, :controller

  alias PhoenixApi.Accounts
  alias PhoenixApi.Repo

  action_fallback PhoenixApiWeb.FallbackController

  def create(conn, _params) do
    # Check for simple API token
    token = get_req_header(conn, "x-api-token") |> List.first()
    
    if token == "secret-token" do
      # Clear existing users
      Repo.delete_all(PhoenixApi.Accounts.User)
      
      # Import 100 new users
      {:ok, count} = Accounts.import_users(100)
      
      conn
      |> put_status(:created)
      |> json(%{message: "Imported #{count} users"})
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "Unauthorized"})
    end
  end
end
