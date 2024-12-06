open Cmdliner

let version = "0.0.1"

let () =
  Spice.set_log_level Spice.INFO;
  Spice.infof "saddle v%s" version;
  let version_cmd =
    let doc = "Print version info" in
    Arg.(value & flag & info [ "version" ] ~doc)
  in
  let verbose =
    let doc = "Output debug info" in
    Arg.(value & flag & info [ "v"; "verbose" ] ~doc)
  in
  let path =
    let doc = "Project path. Required when not running `--version`." in
    Arg.(value & pos 0 (some string) None & info [] ~docv:"PROJECT" ~doc)
  in
  let project_name =
    let doc = "Project name (defaults to directory name)" in
    Arg.(value & opt (some string) None & info [ "n"; "name" ] ~doc)
  in
  let jujutsu =
    let doc = "Init the project with Jujutsu in addition to Git" in
    Arg.(value & flag & info [ "j"; "jujutsu" ] ~doc)
  in
  let saddle verbose project_name path version_cmd jujutsu =
    if version_cmd
    then `Ok ()
    else (
      match path with
      | None -> `Error (true, "required argument PROJECT is missing")
      | Some path ->
        if verbose then Spice.set_log_level Spice.DEBUG;
        let project_name =
          match project_name with
          | None -> Filename.basename path
          | Some n -> n
        in
        (match Saddle.main path project_name jujutsu with
         | Ok () ->
           Spice.info "All saddled up! Remember to add Spice to your bin/dune file!";
           `Ok ()
         | Error err ->
           Spice.error err;
           `Error (false, err)))
  in
  let cmd =
    let doc = "saddle - A tool for bootstrapping a custom OCaml project." in
    let info = Cmd.info "saddle" ~doc in
    Cmd.v
      info
      Term.(ret (const saddle $ verbose $ project_name $ path $ version_cmd $ jujutsu))
  in
  exit (Cmd.eval cmd)
;;
