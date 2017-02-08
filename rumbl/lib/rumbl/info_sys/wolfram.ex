defmodule Rumbl.InfoSys.Wolfram do
  import SweetXml
  alias Rumbl.InfoSys.Result

  def start_link(query, query_ref, owner, limit) do
    Task.start_link(__MODULE__, :fetch, [query, query_ref, owner, limit])
  end

  def fetch(query_str, query_ref, owner, _limit) do
    query_str
    |> fetch_xml()
    |> xpath(~x"/queryresult/pod[contains(@title, 'Result') or
                                 contains(@title, 'Definitions')]
                            /subpod/plaintext/text()")
    |> send_result(query_ref, owner)
  end

  # xml解析結果を元々のプロセスに送り返す(失敗時)
  defp send_result(nil, query_ref, owner) do
    send(owner, {:results, query_ref, []})
  end

  # xml解析結果を元々のプロセスに送り返す(成功時)
  defp send_result(answer, query_ref, owner) do
    # タイマー実験用
    # :timer.sleep(5001)
    results = [%Result{backend: "wolfram", score: 95, text: to_string(answer)}]
    send(owner, {:results, query_ref, results})
  end

  defp fetch_xml(query_str) do
    {:ok, {_, _, body}} = :httpc.request(
      String.to_char_list("http://api.wolframalpha.com/v2/query" <> "?appid=#{app_id()}" <>
                                                                    "&input=#{URI.encode(query_str)}&format=plaintext"))
    body
  end

  defp app_id, do: Application.get_env(:rumbl, :wolfram)[:app_id]
end