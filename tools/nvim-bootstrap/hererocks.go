package main

import (
	"os"
	"path/filepath"

	"github.com/fsouza/dotfiles/tools"
)

func ensureHererocks(nv *Neovim) (string, error) {
	hrDir := filepath.Join(nv.CacheDir, "hr")
	if _, err := os.Stat(hrDir); os.IsNotExist(err) {
		hererocksPy, err := downloadHererocksPy(nv)
		if err != nil {
			return "", err
		}

		const luajitVersion = "@v2.1"
		err = tools.Run(&tools.RunOptions{
			Cmd:  python(),
			Args: []string{hererocksPy, "-j", luajitVersion, "-r", "latest", hrDir},
		})
		if err != nil {
			return "", err
		}
	}

	rocksDir := os.Getenv("HOMEBREW_PREFIX")
	if rocksDir == "" {
		rocksDir = "/usr/local"
	}

	luarocks := filepath.Join(hrDir, "bin", "luarocks")
	return hrDir, tools.Run(&tools.RunOptions{
		Cmd:  luarocks,
		Args: []string{"make", "--force", "PCRE_DIR=" + rocksDir},
		Cwd:  filepath.Join(dotfilesDir, "nvim"),
	})
}

func downloadHererocksPy(nv *Neovim) (string, error) {
	hererocksPy := filepath.Join(nv.CacheDir, "hererocks.py")
	if _, err := os.Stat(hererocksPy); os.IsNotExist(err) {
		const hererocksURL = "https://raw.githubusercontent.com/luarocks/hererocks/master/hererocks.py"
		err = tools.DownloadFile(hererocksURL, hererocksPy, 0o644)
		return hererocksPy, err
	}
	return hererocksPy, nil
}
