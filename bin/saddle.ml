(* open Base *)
open Core_unix

let ( let* ) = Result.bind
let exists fp = access fp [ `Exists ]

let populate_template template_string name =
  let format = Scanf.format_from_string template_string "%s" in
  let contents = Printf.sprintf format name in
  contents
;;

let write_flake dir project_name =
  let new_path = Filename.concat dir "flake.nix" in
  let new_file = open_out new_path in
  let contents =
    String.cat
      (String.cat Flake_template.template_start project_name)
      Flake_template.template_end
  in
  contents |> output_string new_file;
  close_out new_file
;;

let write_window_run dir path =
  let new_path = Filename.concat dir "run.bat" in
  let new_file = open_out new_path in
  (* Get the path as an absolute path *)
  let cwd = Unix.getcwd () in
  let project_dir = Filename.concat cwd path in
  let bin = Filename.concat project_dir "_build/default/bin/main.exe" in
  (* We cannot include the `%*` to pass arguments since that is not a valid format identifier *)
  String.cat (populate_template Windows_template.template bin) "%*"
  |> output_string new_file;
  close_out new_file
;;

let write_envrc_ocamlfmt dir =
  let envrc_path = Filename.concat dir ".envrc" in
  let ocamlformat_path = Filename.concat dir ".ocamlformat" in
  let ocp_indent_path = Filename.concat dir ".ocp-indent" in
  let envrc_file = open_out envrc_path in
  let ocamlformat_file = open_out ocamlformat_path in
  let ocp_indent_file = open_out ocp_indent_path in
  let envrc_contents = "use flake" in
  let ocamlformat_contents = "profile=janestreet" in
  let ocp_indent_contents = "JaneStreet" in
  output_string envrc_file envrc_contents;
  output_string ocamlformat_file ocamlformat_contents;
  output_string ocp_indent_file ocp_indent_contents;
  close_out envrc_file;
  close_out ocamlformat_file
;;

let init_dune path project_name =
  let original_dir = Unix.getcwd () in
  let cmd = Printf.sprintf "dune init project %s %s" project_name path in
  let env = Unix.environment () in
  let process = open_process_full cmd ~env in
  let stderr_contents = In_channel.input_all process.stderr in
  let exit_status = Core_unix.close_process_full process in
  match exit_status with
  | Ok () ->
    (* Run `dune build`, this WILL fail though *)
    let new_path = Filename.concat path "dune-project" in
    let new_file = open_out new_path in
    let content =
      String.concat
        ""
        [ Dune_template.template_start
        ; project_name
        ; Dune_template.template_mid
        ; project_name
        ; Dune_template.template_end
        ]
    in
    output_string new_file content;
    close_out new_file;
    Unix.chdir path;
    let cmd = "dune build" in
    let env = Unix.environment () in
    let process = open_process_full cmd ~env in
    let _stderr_contents = In_channel.input_all process.stderr in
    let _exit_status = Core_unix.close_process_full process in
    Unix.chdir original_dir;
    Ok ()
  | Error _ ->
    Unix.chdir original_dir;
    Error stderr_contents
;;

let run_proc cmd =
  let env = Unix.environment () in
  let process = open_process_full cmd ~env in
  let stderr_contents = In_channel.input_all process.stderr in
  let exit_status = Core_unix.close_process_full process in
  match exit_status with
  | Ok () -> Ok ()
  | Error _ -> Error stderr_contents
;;

let setup_log_library path jujutsu =
  (* First init a git repo *)
  let cmd = "git init; git branch -M main" in
  let original_dir = Unix.getcwd () in
  Unix.chdir path;
  let* result = run_proc cmd in
  let* _ =
    match jujutsu with
    | true ->
      let cmd = "jj git init --colocate" in
      let* result = run_proc cmd in
      Ok result
    | false -> Ok ()
  in
  (* Set up the submodule *)
  let submodule_setup =
    "git submodule add https://github.com/max-legrand/spice.git lib/spice"
  in
  let* () = run_proc submodule_setup in
  (* Commit the change *)
  let cmd = "git add .; git commit -m 'Added spice submodule'" in
  let* () = run_proc cmd in
  Unix.chdir original_dir;
  Ok result
;;

let write_gitignore path =
  let new_path = Filename.concat path ".gitignore" in
  let new_file = open_out new_path in
  let gitignore_contents = "_build/\n.direnv/" in
  gitignore_contents |> output_string new_file;
  close_out new_file
;;

let init_flake path =
  Spice.debugf "Initializing flake";
  let original_dir = Unix.getcwd () in
  Unix.chdir path;
  let cmd = "nix flake update" in
  let* result = run_proc cmd in
  Unix.chdir original_dir;
  Ok result
;;

let main path name jujutsu =
  Spice.debugf "Saddling up %s @ %s" name path;
  (* Check if the project path already exists *)
  match exists path with
  | Ok () ->
    Spice.errorf "Project %s already exists" name;
    exit_immediately 1
  | Error _ ->
    ();
    (* Make the project directory *)
    (* Init the dune project *)
    (match init_dune path name with
     | Ok () -> ()
     | Error err -> failwith err);
    (* Write the flake *)
    write_flake path name;
    let* () = init_flake path in
    write_window_run path name;
    write_gitignore path;
    (match setup_log_library path jujutsu with
     | Ok () -> ()
     | Error err -> failwith err);
    (* Write the envrc and ocamlformat *)
    write_envrc_ocamlfmt path;
    Ok ()
;;
