defmodule Rumbl.UserRepoTest do
  use Rumbl.ModelCase
  alias Rumbl.User

  @valid_attrs %{name: "A User", username: "eva"}

  test "converts unique_constraint on username to error" do
    insert_user(username: "eric")
    attrs = Map.put(@valid_attrs, :username, "eric")
    changeset = User.changeset(%User{}, attrs)

    assert {:error, changeset} = Repo.insert(changeset)
    # changeset.errorsはキーワードリストになっている
    # キーワードリストの各要素は最初の値がアトムとなるタプルとしても認識される
    assert {:username, {"has already been taken", []}} in changeset.errors
  end
end