package main

import (
	"encoding/json"
	"flag"
	"log"
	"os"
	"path/filepath"

	"golang.org/x/exp/maps"
)

var nvimVenvDir string

func main() {
	flag.StringVar(&nvimVenvDir, "venv", "", "path to the neovim virtualenv")
	flag.Parse()

	if nvimVenvDir == "" {
		flag.Usage()
		os.Exit(2)
	}

	pythonBin := filepath.Join(nvimVenvDir, "bin", "python3")
	if _, err := os.Stat(pythonBin); err != nil {
		log.Fatalf("invalid value for -venv: %v", err)
	}

	var languages []Language
	if precommitConfig, err := FindPrecommitConfig(); err == nil {
		languages, err = EFMConfigFromPrecommit(precommitConfig)
		if err != nil {
			log.Fatalf("failed to load languages from %q: %v", precommitConfig, err)
		}
	} else {
		for _, factory := range []Factory{ruff, black, addTrailingComma, reorderPythonImports} {
			languages = append(languages, factory(nil)...)
		}
	}

	languages = removeDuplicates(languages)
	err := json.NewEncoder(os.Stdout).Encode(languages)
	if err != nil {
		log.Fatal(err)
	}
}

func removeDuplicates(langs []Language) []Language {
	m := map[string]Language{}
	for _, lang := range langs {
		if lang.FormatCommand != "" {
			m["format#"+lang.FormatCommand] = lang
		} else if lang.LintCommand != "" {
			m["lint#"+lang.LintCommand] = lang
		}
	}

	return maps.Values(m)
}
