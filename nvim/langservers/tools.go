//go:build tools

package langservers

import (
	_ "github.com/grafana/jsonnet-language-server"
	_ "github.com/hashicorp/terraform-ls"
	_ "github.com/mattn/efm-langserver"
)
