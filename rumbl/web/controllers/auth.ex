defmodule Rumbl.Auth do
  import Phoenix.Controller
  alias Rumbl.Router.Helpers
  import Plug.Conn
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]

  def init(opts) do
    # キーワードリストから:repoの箇所の値を取得する
    # 無ければexception(つまりは必須)
    Keyword.fetch!(opts, :repo)
  end

  def call(conn, repo) do
    user_id = get_session(conn, :user_id)
    cond do
      user = conn.assigns[:current_user] ->
        conn
      user = user_id && repo.get(Rumbl.User, user_id) ->
        # assignでconnを変更する(importされた関数)
        # これによって:current_userがコントローラやビューで使えるようになる
        assign(conn, :current_user, user)
      true ->
        assign(conn, :current_user, nil)
    end
  end

  def login(conn, user) do
    conn
    |> assign(:current_user, user)
    |> put_session(:user_id, user.id)
    |> configure_session(renew: true) # セッションキーとかを新しくしている(セキュリティのため)
  end

  def logout(conn) do
    configure_session(conn, drop: true)
  end

  def login_by_username_add_pass(conn, username, given_pass, opts) do
    repo = Keyword.fetch!(opts, :repo)
    user = repo.get_by(Rumbl.User, username: username)

    # 複数の値で分岐しているためcaseではなくcond(caseは与えられた1つの値に対する分岐)
    cond do
      user && checkpw(given_pass, user.password_hash) ->
        {:ok, login(conn, user)}
      user ->
        {:error, :unauthorized, conn}
      true ->
        dummy_checkpw()
        {:error, :not_found, conn}
    end
  end

  def authenticate_user(conn, _opts) do
    # Plugで追加したassignの呼び出しが可能かどうか
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access that page")
      |> redirect(to: Helpers.page_path(conn, :index))
      |> halt()
    end
  end
end