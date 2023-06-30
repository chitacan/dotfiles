import_file_if_available("~/.iex.exs")

use MomentiDomain
use MomentiDomain.V4.Studio
use MomentiDomain.V4.Content
use MomentiDomain.V4.Accounts

:dbg.start()

:dbg.tracer(:process, {
  fn
    {:trace, _pid, :call,
     {Studio.ContentLogic, :update_file_info_of_moment_model_info, [project_id, file_info, _env]},
     _parrent},
    _ ->
      T.decode_giv(file_info, %{project_id: project_id})
      |> IO.inspect(label: "Trace matched")

    msg, _ ->
      IO.inspect(msg, label: "Trace not matched")
  end,
  0
})

:dbg.tpl(Studio.ContentLogic, :update_file_info_of_moment_model_info, 3, :c)
:dbg.p(:all, :c)
