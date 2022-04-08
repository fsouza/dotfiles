function! fsouza#CompleteFilter(prefix, entry) abort
	return luaeval('require("fsouza.lib.completion").filter(_A[1], _A[2])', [a:prefix, a:entry])
endfunction
