let template_start = {|(lang dune 3.16)

(name |}

let template_mid =
  {|)

(generate_opam_files true)

(source
 (github username/reponame))

(authors "Author Name")

(maintainers "Maintainer Name")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (name |}
;;

let template_end =
  {|)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends
   ocaml dune lwt stdio base cmdliner core core_unix
 )
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
|}
;;
