defmodule PhoenixApiWeb.ImportControllerTest do
  use PhoenixApiWeb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create import" do
    test "imports users when token is valid", %{conn: conn} do
      conn = put_req_header(conn, "x-api-token", "secret-token")
      conn = post(conn, ~p"/api/import")
      assert json_response(conn, 201)["message"] =~ "Imported"
    end

    test "returns unauthorized when token is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/import")
      assert json_response(conn, 401)["error"] == "Unauthorized"
    end
  end
end
