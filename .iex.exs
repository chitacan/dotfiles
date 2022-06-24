IEx.configure(
  inspect: [limit: 5_000],
  history_size: 100
)

defmodule Tool do
  def decode_cookie(cookie) do
    [_, payload, _] = String.split(cookie, ".", parts: 3)
    {:ok, encoded_term} = Base.url_decode64(payload, padding: false)
    :erlang.binary_to_term(encoded_term)
  end

  def list_lv(selector) when selector in [:id, :pid, :ref, :state] do
    list_lv() |> Enum.map(fn channel -> Map.get(channel, selector) end)
  end

  def list_lv(selector) when is_list(selector) do
    list_lv() |> Enum.map(fn channel -> Map.take(channel, selector) end)
  end

  def list_lv do
    Process.whereis(:ranch_server)
    |> :sys.get_state()
    |> elem(1)
    |> Enum.find(fn
      {_, {:conns_sup, _}} -> true
      _ -> false
    end)
    |> elem(0)
    |> elem(1)
    |> Process.info(:dictionary)
    |> elem(1)
    |> Enum.filter(fn
      {_, :removed} -> true
      _ -> false
    end)
    |> Enum.map(&(&1 |> elem(0) |> :sys.get_state() |> elem(1)))
    |> Enum.map(fn [_ | {%{channels: c}, _}] -> c end)
    |> Enum.filter(fn
      %{"phoenix:live_reload" => _} -> false
      _ -> true
    end)
    |> Enum.reduce(%{}, &Map.merge/2)
    |> Enum.map(fn {key, val} ->
      channel_id = String.replace(key, "lv:", "")
      Tuple.insert_at(val, 0, channel_id)
      %{id: channel_id, pid: elem(val, 0), ref: elem(val, 1), state: elem(val, 2)}
    end)
  end

  def find_lv(channel_id, :pid) do
    find_lv(channel_id) |> Map.get(:pid)
  end

  def find_lv(channel_id) do
    list_lv()
    |> Enum.find(fn channel -> Map.get(channel, :id) == channel_id end)
  end

  def get_assigns(%{pid: pid}) do
    get_assigns(pid)
  end

  def get_assigns(pid) do
    pid
    |> :sys.get_state()
    |> get_in([:socket, Access.key(:assigns)])
  end

  def start_node(sname) do
    {:ok, pid} = Node.start(:"#{sname}@cmmn.chitacan.io")
    pid
  end

  def start_node(sname, cookie) when is_binary(cookie) do
    start_node(sname, String.to_atom(cookie))
  end

  def start_node(sname, cookie) do
    pid = start_node(sname)
    Node.set_cookie(cookie)
    pid
  end

  def logger(level), do: Logger.configure(level: level)
  def logger, do: Logger.configure(level: :warn)
end

alias Tool, as: T
