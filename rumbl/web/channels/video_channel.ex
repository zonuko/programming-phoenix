defmodule Rumbl.VideoChannel do
  use Rumbl.Web, :channel
  alias Rumbl.AnnotationView

  def join("videos:" <> video_id, params, socket) do
    # 5秒ごとにクライアントにメッセージを送る
    # send_interval/2関数は最終的にはsend_interval(Time, self(), Message)という形で呼び出される
    # :timer.send_interval(5_000, :ping)
    last_seen_id = params["last_seen_id"] || 0 # nilにする場合クエリ構築中にis_nilで確かめる必要がある
    video_id = String.to_integer(video_id)
    video = Repo.get!(Rumbl.Video, video_id)

    annotations = Repo.all(
      # videoに紐づくannotationsを取得
      from a in assoc(video, :annotations),
        where: a.id > ^last_seen_id,
        order_by: [asc: a.at, asc: a.id],
        limit: 200,
        preload: [:user]
    )
    
    resp = %{annotations: Phoenix.View.render_many(annotations, AnnotationView, "annotation.json")}

    # socket.assignsにvideo_idを保存
    {:ok, resp, assign(socket, :video_id, video_id)}
  end

  def handle_in(event, params, socket) do
    user = Repo.get(Rumbl.User, socket.assigns.user_id)
    handle_in(event, params, user, socket)
  end

  # クライアントから直接送信された時に受け取るコールバック
  def handle_in("new_annotation", params, user, socket) do
    changeset =
      user
      |> build_assoc(:annotations, video_id: socket.assigns.video_id)
      |> Rumbl.Annotation.changeset(params)

    case Repo.insert(changeset) do
      {:ok, annotation} ->
        # 接続しているクライアント全てにブロードキャストする
        # ユーザが任意のメッセージを送れないようにparamsを分解する
        broadcast! socket, "new_annotation", %{
          id: annotation.id,
          user: Rumbl.UserView.render("user.json", %{user: user}),
          body: annotation.body,
          at: annotation.at
        }
        {:reply, :ok, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  # OTPのコールバックhandle_castやhandle_callの仲間
  # castやcallで処理される以外のメッセージを処理するらしい
  # def handle_info(:ping, socket) do
  #   count = socket.assigns[:count] || 1
  #   push socket, "ping", %{count: count}

  #   {:noreply, assign(socket, :count, count + 1)}
  # end
end