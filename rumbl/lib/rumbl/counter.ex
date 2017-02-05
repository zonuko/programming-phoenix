defmodule Rumbl.Counter do
  use GenServer
  
  # listenにメッセージを送信する
  def inc(pid), do: send(pid, :inc)
  
  def dec(pid), do: send(pid, :dec)

  # listenで保持されている状態を取得する
  def val(pid, timeout \\ 5000) do
    # プロセスにリファレンスという形でマークを付ける
    # リクエストに対してレスポンスを紐付ける
    ref = make_ref()
    send(pid, {:val, self(), ref})
    receive do
      {^ref, val} -> val
    after
      timeout -> exit(:timeout)
    end
  end

  # エントリポイント
  def start_link(initial_val) do
    {:ok, spawn_link(fn -> listen(initial_val) end)}
  end

  # 無限ループでval状態を保持する
  defp listen(val) do
    receive do
      :inc -> listen(val + 1)
      :dec -> listen(val - 1)
      {:val, sender, ref} ->
        send sender, {ref, val}
        listen(val)
    end
  end
end