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
	g.Go(func() error { return ensureVirtualenv(venvDir) })

	err = g.Wait()
	if err != nil {
		log.Fatal(err)
	}

	g = errgroup.Group{}
	g.Go(func() error { setupLangervers(nv, venvDir); return nil })
	g.Go(func() error {
		return ensureHererocks(nv, venvDir)
	})
	err = g.Wait()
	if err != nil {
		log.Fatal(err)
	}
}
