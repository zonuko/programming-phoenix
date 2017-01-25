defmodule Rumbl.VideoControllerTest do
  use Rumbl.ConnCase

  test "requires user authentication on all actions", %{conn: conn} do
    Enum.each([
      get(conn, video_path(conn, :new)),
      get(conn, video_path(conn, :index)),
      get(conn, video_path(conn, :show, "123")),
      get(conn, video_path(conn, :edit, "123")),
      put(conn, video_path(conn, :update, "123", %{})),
      post(conn, video_path(conn, :create, %{})),
      delete(conn, video_path(conn, :delete, "123")),
    ], fn conn ->
      assert html_response(conn, 302) # ユーザ認証が必要なので全部設定されたパスにリダイレクトされる
      assert conn.halted # 認証が行われていないのでhaltedはtrueになる
    end)
  end
end