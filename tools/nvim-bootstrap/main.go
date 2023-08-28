package main

import (
	"log"
	"os"

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

	var g errgroup.Group
	g.Go(func() error { return setupLangervers(nv) })
	g.Go(func() error { return ensureVirtualenv(nv) })
	g.Go(func() error { return updateNeovimPlugins(nv) })

	var hererocksDir string
	g.Go(func() error {
		var err error
		hererocksDir, err = ensureHererocks(nv)
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
