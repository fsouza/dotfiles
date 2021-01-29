def filter_deps:
  .[] | if .installed[].installed_on_request then . else empty end
;

def head_option:
  if (.installed[].version | test("^HEAD-")) then "--HEAD" else empty end
;

def from_source_option:
  if (.versions.bottle) and (.installed[].poured_from_bottle | not) then "--build-from-source" else empty end
;

def parts:
  [.name, head_option, from_source_option]
;

def raw_line:
  parts | join(" ")
;

filter_deps | raw_line
