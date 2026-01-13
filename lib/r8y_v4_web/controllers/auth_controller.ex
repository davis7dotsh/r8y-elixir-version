defmodule R8yV4Web.AuthController do
  use R8yV4Web, :controller

  alias R8yV4Web.Auth

  @doc """
  Handles the login callback - sets the session if password is valid.
  """
  def callback(conn, %{"password" => password}) do
    if Auth.valid_password?(password) do
      conn
      |> Auth.log_in()
      |> put_flash(:info, "Logged in successfully")
      |> redirect(to: ~p"/")
    else
      conn
      |> put_flash(:error, "Invalid password")
      |> redirect(to: ~p"/login")
    end
  end

  def callback(conn, _params) do
    conn
    |> put_flash(:error, "Invalid request")
    |> redirect(to: ~p"/login")
  end

  @doc """
  Logs out the user.
  """
  def logout(conn, _params) do
    conn
    |> Auth.log_out()
    |> put_flash(:info, "Logged out successfully")
    |> redirect(to: ~p"/login")
  end
end
