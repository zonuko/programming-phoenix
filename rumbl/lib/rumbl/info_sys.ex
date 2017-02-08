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
    |> await_result(opts)
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

  defp await_result(children, opts) do
    timeout = opts[:timeout] || 5000
    # 非同期で起動して決められた時間のあとメッセージを送信してくる
    timer = Process.send_after(self(), :timedout, timeout)
    IO.puts("timer start")
    results = await_result(children, [], :infinity)
    IO.puts("get results")
    # タイマー実験用
    # :timer.sleep(5001)
    cleanup(timer)
    results
  end

  defp await_result([head|tail], acc, timeout) do
    {pid, monitor_ref, query_ref} = head
    IO.puts("await")
    IO.inspect head
    IO.inspect tail

    # wolframなどでsendされた結果を待ち受けてパターンマッチする
    # メッセージが来るまで待ち続ける
    receive do
      {:results, ^query_ref, results} ->
        Process.demonitor(monitor_ref, [:flush])
        # 再帰でmapの結果を処理する
        await_result(tail, results ++ acc, timeout)
      {:DOWN, ^monitor_ref, :process, ^pid, _reason} ->
        # モニタリングの結果失敗していた時
        await_result(tail, acc, timeout)
      # Process.send_afterによって送られるメッセージ
      :timedout ->
        IO.puts("timedout")
        kill(pid, monitor_ref)
        await_result(tail, acc, 0)
    after
      timeout ->
        IO.puts("after")
        kill(pid, monitor_ref)
        # ひたすらここにはいることになるのでタイムアウト後は何もせずに終わる
        await_result(tail, acc, 0)
    end
  end

  defp await_result([], acc, _) do
    IO.puts "end await"
    # 最終的には結果を合体したものを返す
    acc
  end

  defp kill(pid, ref) do
    IO.puts "kill"
    Process.demonitor(ref, [:flush])
    Process.exit(pid, :kill)
  end

  defp cleanup(timer) do
    :erlang.cancel_timer(timer)
    IO.puts("timer cleanup")
    receive do
      # ここでもタイムアウトメッセージが来る可能性があるため？
      :timedout ->
        IO.puts("cleanup timedout")
        :ok
    after
      0 ->
        IO.puts("cleanup 0")
        :ok
    end
  end
end