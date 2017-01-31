defmodule Rumbl.Permalink do
  # cast,dump,load,typeの実装を要求するbehaviour
  @behaviour Ecto.Type

  def type, do: :id

  # changesetのcast関数が呼び出される時とかクエリを構築する時とかに使われる
  # 文字列の場合
  def cast(binary) when is_binary(binary) do
    # Integer.parseは文字列中が数字から始まっているときなどに数字と文字を分離する?
    case Integer.parse(binary) do
      {int, _} when int > 0 -> {:ok, int}
      _ -> :error
    end
  end

  def cast(integer) when is_integer(integer) do
    {:ok, integer}
  end

  def cast(_) do
    :error
  end

  # データがデータベースに送信される時に呼び出される
  def dump(integer) when is_integer(integer) do
    {:ok, integer}
  end

  # データがデータベースからロードされる時に呼び出される
  def load(integer) when is_integer(integer) do
    {:ok, integer}
  end
end