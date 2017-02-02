defmodule Rumbl.VideoChannel do
  use Rumbl.Web, :channel

  def join("videos:" <> video_id, _params, socket) do
    # 5秒ごとにクライアントにメッセージを送る
    # send_interval/2関数は最終的にはsend_interval(Time, self(), Message)という形で呼び出される
    # :timer.send_interval(5_000, :ping)
    # socket.assignsにvideo_idを保存
    {:ok, socket}
  end

  # クライアントから直接送信された時に受け取るコールバック
  def handle_in("new_annotation", params, socket) do
    # 接続しているクライアント全てにブロードキャストする
    # ユーザが任意のメッセージを送れないようにparamsを分解する
    broadcast! socket, "new_annotation", %{
      user: %{username: "anon"},
      body: params["body"],
      at: params["at"]
    }

    {:reply, :ok, socket}
  end

  # OTPのコールバックhandle_castやhandle_callの仲間
  # castやcallで処理される以外のメッセージを処理するらしい
  # def handle_info(:ping, socket) do
  #   count = socket.assigns[:count] || 1
  #   push socket, "ping", %{count: count}

  #   {:noreply, assign(socket, :count, count + 1)}
  # end
end