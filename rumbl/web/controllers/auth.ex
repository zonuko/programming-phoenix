defmodule Rumbl.Auth do
  import Plug.Conn

  def init(opts) do
    # キーワードリストから:repoの箇所の値を取得する
    # 無ければexception(つまりは必須)
    Keyword.fetch!(opts, :repo)
  end

  def call(conn, repo) do
    user_id = get_session(conn, :user_id)
    user = user_id && repo.get(Rumbl.User, user_id)
    # assignでconnを変更する(importされた関数)
    # これによって:current_userがコントローラやビューで使えるようになる
    assign(conn, :current_user, user)
  end

  def login(conn, user) do
    conn
    |> assign(:current_user, user)
    |> put_session(:user_id, user.id)
    |> configure_session(renew: true) # セッションキーとかを新しくしている(セキュリティのため)
  end
end