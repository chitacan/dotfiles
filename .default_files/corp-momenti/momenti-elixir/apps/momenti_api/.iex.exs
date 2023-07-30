import_file_if_available("~/.iex.exs")

use MomentiDomain
use MomentiDomain.V4.Studio
use MomentiDomain.V4.Content
use MomentiDomain.V4.Accounts

:dbg.start()

:dbg.tracer(:process, {
  fn
    {:trace, _pid, :call,
     {Studio, :update_file_info_of_moment_model_info,
      [project_id, %{md5: _, ext: _} = file_info]}, _parrent},
    _ ->
      T.decode_giv(file_info, %{project_id: project_id})
      |> IO.inspect(label: "Trace matched")

    {:trace, _pid, :call,
     {Studio, :update_file_info_of_moment_model_info,
      [project_id, %MomentiMedia.Draft.DraftMoment{} = moment]}, _parrent},
    _ ->
      inspected = inspect(moment, pretty: true, limit: :infinity)

      file =
        moment
        |> MomentiMedia.Draft.DraftMoment.encode()
        |> MomentiCore.Md5.hash()
        |> MomentiCore.Md5.encode_url64()

      path = T.giv_path("#{file}.givd.#{project_id}.exs")
      File.write(path, inspected)
      IO.inspect(path, label: "Trace matched")

    msg, _ ->
      IO.inspect(msg, label: "Trace not matched")
  end,
  0
})

:dbg.tpl(Studio, :update_file_info_of_moment_model_info, 2, :c)
:dbg.p(:all, :c)
