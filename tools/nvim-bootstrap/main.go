package main

import (
	"log"
	"os"
	"path/filepath"

	"golang.org/x/sync/errgroup"
)

var dotfilesDir string

func init() {
	dotfilesDir = os.Getenv("FSOUZA_DOTFILES_DIR")
}

func main() {
	if dotfilesDir == "" {
		log.Fatal("missing FSOUZA_DOTFILES_DIR")
	}

	nv, err := loadNeovimSettings()
	if err != nil {
		log.Fatal(err)
	}

	venvDir := filepath.Join(nv.CacheDir, "venv")
	var g errgroup.Group
	g.Go(func() error { return ensureVirtualenv(nv, venvDir) })
	g.Go(func() error { return updateNeovimPlugins(nv) })

	err = g.Wait()
	if err != nil {
		log.Fatal(err)
	}

	var hererocksDir string
	g = errgroup.Group{}
	g.Go(func() error { setupLangervers(nv, venvDir); return nil })
	g.Go(func() error {
		var err error
		hererocksDir, err = ensureHererocks(nv, venvDir)
		return err
	})
	err = g.Wait()
	if err != nil {
		log.Fatal(err)
	}

	err = setupFnlfmt(nv, hererocksDir)
	if err != nil {
		log.Fatal(err)
	}
}
