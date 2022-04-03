function! fsouza#CompleteFilter(prefix, entry)
	return luaeval('require("fsouza.plugin.completion").filter(_A[1], _A[2])', [a:prefix, a:entry])
endfunction
