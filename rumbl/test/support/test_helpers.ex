defmodule Rumbl.TestHelpers do
  alias Rumbl.Repo

  def insert_user(attrs \\ %{}) do
    # Dictをマージする キーが被っている時は第二引数のものが優先される
    changes = Dict.merge(%{
      name: "Some User",
      username: "user#{Base.encode16(:crypt.rand_bytes(8))}",
      password: "supersecret",
    }, attrs)

    %Rumbl.User{}
    |> Rumbl.User.registration_changeset(changes)
    |> Repo.insert!()
  end

  def insert_video(user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:video, attrs)
    |> Repo.insert!()
  end
end