package main

import (
	"flag"
	"log"
	"os"

	"golang.org/x/sync/errgroup"
)

var dotfilesDir string

func init() {
	flag.StringVar(&dotfilesDir, "dotfiles-dir", "", "path to the dotfiles config")
}

func main() {
	flag.Parse()
	if dotfilesDir == "" {
		flag.Usage()
		os.Exit(2)
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
