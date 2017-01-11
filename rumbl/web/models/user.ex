defmodule Rumbl.User do
  use Rumbl.Web, :model

  schema "users" do
    field :name, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_hash, :string

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:name, :username]) # 更新予定のパラメータカラムを第三引数でとる(?)
    |> validate_required([:name, :username]) # このリストがcastが返すchangesetに存在するか検証
    |> validate_length(:username, min: 1, max: 20)
  end
end