(lang dune 3.16)

(name saddle)

(generate_opam_files true)

(source
 (github max-legrand/saddle))

(authors "Maxwell Legrand")

(maintainers "Maxwell Legrand")

(license MIT)

(package
 (name saddle)
 (synopsis "A tool for bootstrapping a custom OCaml project.")
 (description "A small CLI tool for setting up and bootstrapping an OCaml project. Heavily tailored towards my personal preferences")
 (depends
   ocaml dune lwt stdio base cmdliner core core_unix
   ocaml-lsp-server 
   ocamlformat)
 (tags
  (topics "CLI" "project management" "build system")))

