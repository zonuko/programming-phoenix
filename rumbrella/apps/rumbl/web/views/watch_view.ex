defmodule Rumbl.WatchView do
  use Rumbl.Web, :view

  def player_id(video) do
    # URLのパラメータ以前の部分を集合化してパラメータ以降を取り出す正規表現
    # パラメータは必ず?から始まるか&で結合されるかハッシュで#で結合されるかによる
    # [^]は括弧に含まれない物になる
    ~r{^.*(?:youtu\.be/|\w+/|v=)(?<id>[^#&?]*)}
    |> Regex.named_captures(video.url)
    |> get_in(["id"])
  end
end