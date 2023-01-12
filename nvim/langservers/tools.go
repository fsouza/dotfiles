// go:build tools

package langservers

import (
	_ "github.com/bazelbuild/buildtools/buildifier"
	_ "github.com/hashicorp/terraform-ls"
	_ "github.com/mattn/efm-langserver"
)
