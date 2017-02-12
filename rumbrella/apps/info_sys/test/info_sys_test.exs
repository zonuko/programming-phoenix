defmodule InfoSysTest do
  use ExUnit.Case
  alias InfoSys.Result
  
  defmodule TestBackend do
    def start_link(query, ref, owner, limit) do
      Task.start_link(__MODULE__, :fetch, [query, ref, owner, limit])
    end

    def fetch("result", ref, owner, _limit) do
      send(owner, {:results, ref, [%Result{backend: "test", text: "result"}]})
    end

    def fetch("none", ref, owner, _limit) do
      send(owner, {:results, ref, []})
    end

    def fetch("timeout", _ref, owner, _limit) do
      # プロセス監視用にテスト実行元にpidを送る
      send(owner, {:backend, self()})
      :timer.sleep(:infinity)
    end

    def fetch("boom", _ref, _owner, _limit) do
      raise "boom!"
    end
  end

  test "compute/2 with backend results" do
    assert [%Result{backend: "test", text: "result"}] =
           InfoSys.compute("result", backends: [TestBackend])
  end

  test "compute/2 with no backend results" do
    assert [] = InfoSys.compute("none", backends: [TestBackend])
  end

  test "compute/2 with timeout returns no results and kills workers" do
    results = InfoSys.compute("timeout", backends: [TestBackend], timeout: 10)
    assert results == []
    # 上のfetch("timeout", 〜) 関数から送られてくるPID
    assert_receive {:backend, backend_pid}

    ref = Process.monitor(backend_pid)
    assert_receive {:DOWN, ^ref, :process, _pid, _reason}
    # receivedはすでに受信ボックスに入っているものを取り出す
    # 受信をまったりはしない
    refute_received {:DOWN, _, _, _, _}
    refute_received :timeout
  end

  @tag :capture_log
  test "compute/2 discards backend errors" do
    assert InfoSys.compute("boom", backends: [TestBackend]) == []
    
    refute_received {:DOWN, _, _, _, _}
    refute_received :timeout
  end
end
