package main

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"

	"gopkg.in/yaml.v3"
)

type PrecommitRepo struct {
	Name  string `yaml:"repo"`
	Hooks []PrecommitHook
}

type PrecommitHook struct {
	ID   string
	Args []string
}

func FindPrecommitConfig() (string, error) {
	currentDir, err := os.Getwd()
	if err != nil {
		return "", fmt.Errorf("couldn't determine current working dir: %v", err)
	}

	for currentDir != "/" {
		candidate := filepath.Join(currentDir, ".pre-commit-config.yaml")
		if _, err := os.Stat(candidate); err == nil {
			return candidate, nil
		}

		currentDir = filepath.Dir(currentDir)
	}

	return "", errors.New("couldn't find a pre-commit config")
}

func EFMConfigFromPrecommit(filename string) ([]Language, error) {
	repos, err := readPrecommitConfig(filename)
	if err != nil {
		return nil, err
	}

	repoMapping := map[string]Factory{
		"https://github.com/pycqa/flake8":                    flake8,
		"https://github.com/pycqa/autoflake":                 autoflake,
		"https://github.com/myint/autoflake":                 autoflake,
		"https://github.com/psf/black":                       black,
		"https://github.com/psf/black-pre-commit-mirror":     black,
		"https://github.com/ambv/black":                      black,
		"https://github.com/asottile/add-trailing-comma":     addTrailingComma,
		"https://github.com/asottile/reorder-python-imports": reorderPythonImports,
		"https://github.com/asottile/reorder_python_imports": reorderPythonImports,
		"https://github.com/asottile/pyupgrade":              pyupgrade,
		"https://github.com/pre-commit/mirrors-autopep8":     autopep8,
		"https://github.com/pre-commit/mirrors-isort":        isort,
		"https://github.com/pycqa/isort":                     isort,
		"https://github.com/timothycrosley/isort":            isort,
		"https://github.com/charliermarsh/ruff-pre-commit":   ruff,
		"https://github.com/omnilib/ufmt":                    ufmt,
	}
	var output []Language
	for _, repo := range repos {
		if factory, ok := repoMapping[strings.ToLower(repo.Name)]; ok {
			var args []string
			idx := slices.IndexFunc(repo.Hooks, func(h PrecommitHook) bool { return len(h.Args) > 0 })
			if idx > -1 {
				args = repo.Hooks[idx].Args
			}
			output = append(output, factory(args)...)
		}
	}

	return output, nil
}

func readPrecommitConfig(filename string) ([]PrecommitRepo, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	decoder := yaml.NewDecoder(file)
	var config struct {
		Repos []PrecommitRepo
	}
	err = decoder.Decode(&config)
	return config.Repos, err
}
