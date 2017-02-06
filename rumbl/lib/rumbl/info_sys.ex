defmodule Rumbl.InfoSys do
  # デフォルトのバックエンドサービス
  @backends [Rumbl.InfoSys.Wolfram]

  defmodule Result do
    defstruct score: 0, text: nil, url: nil, backend: nil
  end

  # バックエンドサービスのプロセスを開始する
  def start_link(backend, query, query_ref, owner, limit) do
    backend.start_link(query, query_ref, owner, limit)
  end

  def compute(query, opts \\ []) do
    limit = opts[:limit] || 10
    # 引数でバックエンドサービスが提示されてなければデフォルトを使う
    backends = opts[:backends] || @backends

    # 各バックエンドサービスに関してプロセスを開始する
    backends
    |> Enum.map(&spawn_query(&1, query, limit)
  end

  defp spawn_query(backend, query, limit) do
    query_ref = make_ref()
    opts = [backend, query, query_ref, self(), limit]
    # 起動済みのSupervisorに自分自身のプロセスを子として監視してもらう
    # これを呼び出すと自動でstart_linkが呼び出されてプロセス開始する
    {:ok, pid} = Supervisor.start_child(Rumbl.InfoSys.Supervisor, opts)
    {pid, query_ref}
  end
end