package main

import (
	"os"

	"github.com/fsouza/dotfiles/tools"
)

func gitCloneOrUpdate(url, dir string) error {
	_, err := os.Stat(dir)
	if os.IsNotExist(err) {
		return gitClone(url, dir)
	}
	return gitUpdate(dir)
}

func gitClone(url, dir string) error {
	return git("clone", "--recurse-submodules", url, dir)
}

func gitUpdate(dir string) error {
	err := git("-C", dir, "pull")
	if err != nil {
		return err
	}
	return git("-C", dir, "submodule", "update", "--init", "--recursive")
}

func git(args ...string) error {
	return tools.Run(&tools.RunOptions{
		Cmd:  "git",
		Args: args,
	})
}
