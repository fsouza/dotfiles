package main

import (
	"io"
	"maps"
	"os"
	"path/filepath"
	"strings"

	"github.com/fsouza/dotfiles/tools"
	"golang.org/x/sync/errgroup"
)

func updateNeovimPlugins(nv *Neovim) error {
	basePackDir := filepath.Join(nv.DataDir, "site", "pack")
	mrconfigFiles := map[string]string{
		"mr": filepath.Join(dotfilesDir, "nvim", "mrconfig"),
	}
	maps.Copy(mrconfigFiles, parseExtraMrconfig(os.Getenv("FSOUZA_NVIM_EXTRA_MRCONFIG")))

	var group errgroup.Group
	for dirname, mrconfig := range mrconfigFiles {
		packDir := filepath.Join(basePackDir, dirname)
		mrconfig := mrconfig
		group.Go(func() error {
			return doUpdateNeovimPlugins(packDir, mrconfig)
		})
	}

	return group.Wait()
}

func doUpdateNeovimPlugins(packDir, mrconfigPath string) error {
	err := os.MkdirAll(packDir, 0o755)
	if err != nil {
		return err
	}
	err = copyFile(mrconfigPath, filepath.Join(packDir, ".mrconfig"))
	if err != nil {
		return err
	}
	return tools.Run(&tools.RunOptions{
		Cmd:  "mr",
		Args: []string{"-t", "-j", "update"},
		Cwd:  packDir,
	})
}

func copyFile(srcPath, dstPath string) error {
	src, err := os.Open(srcPath)
	if err != nil {
		return err
	}
	defer src.Close()
	dst, err := os.Create(dstPath)
	if err != nil {
		return err
	}
	defer dst.Close()
	_, err = io.Copy(dst, src)
	return err
}

func parseExtraMrconfig(extraMrconfig string) map[string]string {
	if extraMrconfig == "" {
		return nil
	}

	result := map[string]string{}
	parts := strings.Split(extraMrconfig, ":")
	for _, part := range parts {
		subparts := strings.SplitN(part, "=", 2)
		if len(subparts) == 2 {
			result[subparts[0]] = subparts[1]
		}
	}
	return result
}
