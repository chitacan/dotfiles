IEx.configure(
  inspect: [limit: 5_000, charlists: :as_lists],
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

  def logger(app, level), do: Logger.put_application_level(app, level)
  def logger(level), do: Logger.configure(level: level)
  def logger, do: Logger.configure(level: :info)

  def pid("pid=" <> rest), do: __MODULE__.pid(rest)

  def pid(pid) do
    pid
    |> String.replace(~r/<|>/, "")
    |> IEx.Helpers.pid()
  end

  def context_path() do
    File.cwd!()
    |> then(fn cwd ->
      rest =
        if Mix.Project.umbrella?(),
          do: ".context",
          else: "../../.context"

      Path.join(cwd, rest)
    end)
    |> Path.expand()
    |> then(fn path ->
      if not File.exists?(path), do: File.mkdir_p(path)
      path
    end)
  end

  def context_path(file) do
    context_path() |> Path.join(file)
  end

  @required [HTTPoison, MomentiCore.Gcp.ContentStorage]
  if Enum.map(@required, &Code.ensure_loaded/1) |> Enum.all?(&match?({:module, _}, &1)) do
    def decode_giv("(\\x" <> <<md5::binary-size(32)>> <> ",giv)", opts) do
      case MomentiCore.Md5.decode_hex(md5) do
        {:ok, hex} ->
          hex
          |> MomentiCore.Md5.encode_url64()
          |> Kernel.<>(".giv")
          |> decode_giv(opts)

        error ->
          error
      end
    end

    def decode_giv("(\\x" <> <<md5::binary-size(32)>> <> ",givd)", opts) do
      case MomentiCore.Md5.decode_hex(md5) do
        {:ok, hex} ->
          hex
          |> MomentiCore.Md5.encode_url64()
          |> Kernel.<>(".givd")
          |> decode_giv(opts)

        error ->
          error
      end
    end

    def decode_giv(file_name, env)
        when is_binary(file_name) and env in [:integ, :staging, :prod] do
      "https://media.integ.momenti.dev/content/#{file_name}"
      |> decode_giv(%{})
    end

    def decode_giv(file_name, %{env: :integ}) when is_binary(file_name) do
      "https://media.integ.momenti.dev/content/#{file_name}"
      |> decode_giv(%{})
    end

    def decode_giv(file_name, %{env: :staging}) when is_binary(file_name) do
      "https://media.staging.momenti.dev/content/#{file_name}"
      |> decode_giv(%{})
    end

    def decode_giv(file_name, %{env: :prod}) when is_binary(file_name) do
      "https://media.momenti.tv/content/#{file_name}"
      |> decode_giv(%{})
    end

    def decode_giv(%{file_info: %{md5: _, ext: _} = key}, opts) do
      key |> MomentiCore.Gcp.ContentStorage.get_cdn_url() |> decode_giv(opts)
    end

    def decode_giv(%{md5: _, ext: _} = key, opts) do
      struct(MomentiCore.HashStorage.HashKey, key)
      |> MomentiCore.Gcp.ContentStorage.get_cdn_url()
      |> decode_giv(opts)
    end

    def decode_giv(url, opts) when is_binary(url) do
      ext = Path.extname(url)
      file = Path.basename(url)

      project_id =
        opts
        |> Map.get(:project_id)
        |> case do
          nil -> ""
          project_id -> ".#{project_id}"
        end

      target_path = context_path("#{file}#{project_id}.exs")

      with {:ok, %{body: body}} <- HTTPoison.get(url),
           module <- decoder_module(ext),
           decoded <- apply(module, :decode, [body]) |> inspect(pretty: true, limit: :infinity),
           :ok <- File.write(target_path, decoded) do
        target_path
      rescue
        error ->
          error
      end
    end

    def decode_giv(file_name), do: decode_giv(file_name, :integ)

    defp decoder_module(".giv"), do: MomentiMedia.Moment
    defp decoder_module(".givd"), do: MomentiMedia.Draft.DraftMoment
  end

  @required [MomentiCore.Gcp.ContentStorage, MomentiDomain.Repo]
  if Enum.map(@required, &Code.ensure_loaded/1) |> Enum.all?(&match?({:module, _}, &1)) do
    def update_giv(project_id, path) when is_binary(path) do
      case path |> Path.absname() == path do
        true ->
          {moment, _} = Code.eval_file(path)
          update_giv(project_id, moment)

        false ->
          update_giv(project_id, context_path(path))
      end
    end

    def update_giv(project_id, %MomentiMedia.Moment{} = moment) do
      alias MomentiCore.HashStorage.HashFile
      alias MomentiCore.Gcp.ContentStorage
      alias MomentiDomain.V4.Content
      alias MomentiDomain.V4.Content.MomentInfo

      with %{meta: %{hash: content_hash}} = updated <-
             MomentiCore.Protobuf.Moment.update_moment_hash(moment),
           {:ok, %MomentInfo{} = moment_info} <- Content.create_empty_moment_info(project_id),
           {:ok, file_meta} <-
             %HashFile{data: MomentiMedia.Moment.encode(updated), ext: "giv"}
             |> ContentStorage.write_file(),
           {:ok, file_info} <- ContentStorage.Pure.meta_to_key(file_meta),
           {:ok, %MomentInfo{} = moment_info} <-
             MomentInfo.changeset_for_update_content(moment_info, %{
               file_info: file_info,
               content_hash: content_hash,
               status: "exported"
             })
             |> MomentiDomain.Repo.update() do
        moment_info
      end
    end

    def update_giv(project_id, %MomentiMedia.Draft.DraftMoment{} = moment) do
      alias MomentiDomain.V4.Studio.MomentModelInfo
      alias MomentiCore.HashStorage.HashFile
      alias MomentiCore.Gcp.ContentStorage

      with %MomentModelInfo{} = moment_model_info <-
             MomentModelInfo.get_by_project_id(project_id) |> MomentiDomain.Repo.one(),
           {:ok, file_meta} <-
             %HashFile{data: MomentiMedia.Draft.DraftMoment.encode(moment), ext: "givd"}
             |> ContentStorage.write_file(),
           {:ok, file_info} <- ContentStorage.Pure.meta_to_key(file_meta),
           {:ok, %MomentModelInfo{} = updated} <-
             MomentModelInfo.update_file_info(moment_model_info, file_info)
             |> MomentiDomain.Repo.update() do
        updated
      end
    end
  end
end

defmodule :_shortcuts do
  defdelegate c, to: IEx.Helpers, as: :clear
  defdelegate r, to: IEx.Helpers, as: :recompile
end

import :_shortcuts
alias Tool, as: T
