function! fsouza#CompleteFilter(prefix, entry) abort
	if a:prefix ==# ''
		return 999
	endif

	let score = luaeval('require("fzy").score(_A[1], _A[2])', [a:prefix, a:entry])
	if score < 0
		return 0
	endif

	return score
endfunction
