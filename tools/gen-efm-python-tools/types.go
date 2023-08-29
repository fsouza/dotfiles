package main

// Language is a copy of the struct from efm-langserver.
//
// We copy it for two reasons:
//
//  1. to omit empty values
//  2. a little copying is better than a little dependency
type Language struct {
	LintFormats        []string `json:"lintFormats,omitempty"`
	LintStdin          bool     `json:"lintStdin,omitempty"`
	LintCommand        string   `json:"lintCommand,omitempty"`
	LintIgnoreExitCode bool     `json:"lintIgnoreExitCode,omitempty"`
	LintSource         string   `json:"lintSource,omitempty"`
	LintWorkspace      bool     `json:"lintWorkspace,omitempty"`
	LintOnSave         bool     `json:"lintOnSave,omitempty"`
	FormatCommand      string   `json:"formatCommand,omitempty"`
	FormatStdin        bool     `json:"formatStdin,omitempty"`
	Env                []string `json:"env,omitempty"`
	RootMarkers        []string `json:"rootMarkers,omitempty"`
	RequireMarker      bool     `json:"requireMarker,omitempty"`
}

type Factory = func(args []string) []Language
