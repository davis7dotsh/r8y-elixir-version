defmodule R8yV4Web.Auth do
  @moduledoc """
  Simple password-based authentication plug.

  Checks if the user is authenticated via session. If not, redirects to login page.
  Password is checked against the AUTH_PASSWORD environment variable.
  """
  import Plug.Conn
  import Phoenix.Controller

  @doc """
  Plug that requires authentication.
  Redirects to login page if not authenticated.
  """
  def require_auth(conn, _opts) do
    if get_session(conn, :authenticated) do
      conn
    else
      conn
      |> put_flash(:error, "Please log in to continue")
      |> redirect(to: "/login")
      |> halt()
    end
  end

  @doc """
  Plug that redirects authenticated users away from login page.
  """
  def redirect_if_authenticated(conn, _opts) do
    if get_session(conn, :authenticated) do
      conn
      |> redirect(to: "/")
      |> halt()
    else
      conn
    end
  end

  @doc """
  Checks if the given password matches the configured AUTH_PASSWORD.
  """
  def valid_password?(password) do
    expected = Application.get_env(:r8y_v4, :auth_password)

    if expected && expected != "" do
      Plug.Crypto.secure_compare(password, expected)
    else
      false
    end
  end

  @doc """
  Logs in the user by setting the authenticated session.
  """
  def log_in(conn) do
    conn
    |> configure_session(renew: true)
    |> put_session(:authenticated, true)
  end

  @doc """
  Logs out the user by clearing the session.
  """
  def log_out(conn) do
    conn
    |> configure_session(drop: true)
  end
end
