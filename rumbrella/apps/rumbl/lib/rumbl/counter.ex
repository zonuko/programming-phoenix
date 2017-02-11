defmodule Rumbl.Counter do
  use GenServer

  # listenにメッセージを送信する
  def inc(pid), do: GenServer.cast(pid, :inc)
  
  def dec(pid), do: GenServer.cast(pid, :dec)

  def val(pid) do
    # 値が返ってくるのを待つ必要があるため同期呼び出し
    GenServer.call(pid, :val)
  end

  # エントリポイント
  def start_link(initial_val) do
    GenServer.start_link(__MODULE__, initial_val)
  end

  def init(initial_val) do
    # :tickメッセージを1000ミリ秒後に自分自身に送信
    Process.send_after(self(), :tick, 1000)
    {:ok, initial_val}
  end

  def handle_cast(:inc, val) do
    {:noreply, val + 1}
  end

  def handle_cast(:dec, val) do
    {:noreply, val - 1}
  end

  def handle_call(:val, _from, val) do
    {:reply, val, val}
  end
  
  # valが0以下になったらわざとクラッシュさせる
  def handle_info(:tick, val) when val <= 0, do: raise "boom!"
  # send_afterで自分自身に送られたものを受け取る
  def handle_info(:tick, val) do
    IO.puts "tick #{val}"
    Process.send_after(self(), :tick, 1000)
    {:noreply, val - 1}
  end
end