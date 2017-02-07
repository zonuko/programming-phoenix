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
    |> Enum.map(&spawn_query(&1, query, limit))
    |> await_results(opts)
    |> Enum.sort(&(&1.score >= &2.score))
    |> Enum.take(limit)
  end

  defp spawn_query(backend, query, limit) do
    query_ref = make_ref()
    # 送り返される時に自分のPIDが必要なので第4引数はself()
    opts = [backend, query, query_ref, self(), limit]
    # 起動済みのSupervisorに自分自身のプロセスを子として監視してもらう
    # これを呼び出すと自動でstart_linkが呼び出されてプロセス開始する
    {:ok, pid} = Supervisor.start_child(Rumbl.InfoSys.Supervisor, opts)

    # プロセスの死活監視
    monitor_ref = Process.monitor(pid)

    {pid, monitor_ref, query_ref}
  end

  defp await_results(children, _opts) do
    await_results(children, [], :infinity)
  end

  defp await_results([head|tail], acc, timeout) do
    {pid, monitor_ref, query_ref} = head

    # wolframなどでsendされた結果を待ち受けてパターンマッチする
    receive do
      {:results, ^query_ref, results} ->
        Process.demonitor(monitor_ref, [:flush])
        # 再帰でmapの結果を処理する
        await_results(tail, results ++ acc, timeout)
      {:DOWN, ^monitor_ref, :process, ^pid, _reason} ->
        # モニタリングの結果失敗していた時
        await_results(tail, acc, timeout)
    end
  end

  defp await_results([], acc, _) do
    # 最終的には結果を合体したものを返す
    acc
  end
end