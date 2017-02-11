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
      {:ok, ann} ->
        # コメントを取り敢えず保存
        broadcast_annotation(socket, ann)
        # コメントに対するInfoSysの結果を取得する(非同期)
        # 取得結果はwolframユーザのannotationとして保存される
        Task.start_link(fn -> compute_additional_info(ann, socket) end)
        {:reply, :ok, socket}
      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  defp compute_additional_info(ann, socket) do
    # computeには結果をスコア順で先頭一つだけ取るように指示
    # googleとかの結果もほしいならlimit2とかにすれば良いはず 
    # 結果は要らないのでリスト内包表記の結果は呼び出し元でも受け取っていない
    for result <- InfoSys.compute(ann.body, limit: 1, timeout: 10_000) do
      attrs = %{url: result.url, body: result.text, at: ann.at}

      info_changeset = 
        Repo.get_by!(Rumbl.User, username: result.backend) # ユーザを取得
        |> build_assoc(:annotations, video_id: ann.video_id) # ユーザに紐づくannotationを作成
        |> Rumbl.Annotation.changeset(attrs) # annotationのchangesetを作成

      case Repo.insert(info_changeset) do
        # インサート出来たらInfoSysの結果を共通関数でブロードキャストする
        {:ok, info_ann} -> broadcast_annotation(socket, info_ann)
        {:error, _changeset} -> :ignore
      end
    end
  end
  
  defp broadcast_annotation(socket, annotation) do
    annotation = Repo.preload(annotation, :user)
    rendered_ann = Phoenix.View.render(AnnotationView, "annotation.json", %{
      annotation: annotation
    })
    broadcast! socket, "new_annotation", rendered_ann
  end
end