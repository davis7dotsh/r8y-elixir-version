defmodule R8yV4Web.PageControllerTest do
  use R8yV4Web.ConnCase

  test "GET /", %{conn: conn} do
    conn = conn |> log_in() |> get(~p"/")
    assert html_response(conn, 200) =~ "Dashboard"
  end
end
