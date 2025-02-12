local function setup_term_mapping(term_id)
  vim.keymap.set("n", "<a-t>" .. term_id, function()
    local t = require("fsouza.lib.terminal")
    t.open(term_id)
  end)
end

setup_term_mapping("j")
setup_term_mapping("k")
setup_term_mapping("l")
