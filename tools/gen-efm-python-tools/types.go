package main

import "github.com/mattn/efm-langserver/langserver"

type Factory = func(args []string) []langserver.Language
