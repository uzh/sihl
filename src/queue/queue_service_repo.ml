open Base
module Job = Queue_core.Job
module JobInstance = Queue_core.JobInstance

module MakeMemory (Repo : Data.Repo.Sig.SERVICE) : Queue_sig.REPO = struct
  let state = ref (Map.empty (module String))

  let ordered_ids = ref []

  let register_cleaner ctx =
    let cleaner _ =
      state := Map.empty (module String);
      ordered_ids := [];
      Lwt_result.return ()
    in
    Repo.register_cleaner ctx cleaner

  let register_migration _ = Lwt_result.return ()

  let enqueue _ ~job_instance =
    let id = JobInstance.id job_instance |> Data.Id.to_string in
    ordered_ids := List.cons id !ordered_ids;
    state := Map.add_exn !state ~key:id ~data:job_instance;
    Lwt_result.return ()

  let update _ ~job_instance =
    let id = JobInstance.id job_instance |> Data.Id.to_string in
    state := Map.set !state ~key:id ~data:job_instance;
    Lwt_result.return ()

  let find_workable _ =
    let all_job_instances =
      List.map !ordered_ids ~f:(fun id -> Map.find !state id)
    in
    let now = Ptime_clock.now () in
    let rec filter_pending all_job_instances result =
      match all_job_instances with
      | Some job_instance :: job_instances ->
          if JobInstance.should_run ~job_instance ~now then
            filter_pending job_instances (List.cons job_instance result)
          else filter_pending job_instances result
      | None :: job_instances -> filter_pending job_instances result
      | [] -> result
    in
    Lwt_result.return @@ filter_pending all_job_instances []
end
