defmodule Rumbl.UserView do
  use Rumbl.Web, :view
  alias Rumbl.User

  def first_name(%User{name: name}) do
    name
    |> String.split(" ")
    |> Enum.at(0)
  end

  # json版のrender関数を定義 元々のテンプレート名を受け付けるものとのパターンマッチ
  def render("user.json", %{user: user}) do
    %{id: user.id, username: user.username}
  end
end