defmodule Rumble.VideoChannel do
  use Rumbl.Web, :channel

  def join("videos:" <> video_id, _params, socket) do
    # socket.assignsにvideo_idを保存
    {:ok, assign(socket, :video_id, String.to_integer(video_id))}
  end
end