package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"text/template"
)

type TemplateData struct {
	FontSize         float64
	DotfilesDir      string
	DotfilesCacheDir string
	Shell            string
}

func main() {
	fontSize := flag.Float64("font-size", 12.0, "font size")
	flag.Parse()

	dotfilesDir, ok := os.LookupEnv("FSOUZA_DOTFILES_DIR")
	if !ok {
		log.Fatal("missing FSOUZA_DOTFILES_DIR")
	}

	dotfilesCacheDir, ok := os.LookupEnv("FSOUZA_DOTFILES_CACHE_DIR")
	if !ok {
		dotfilesCacheDir = os.ExpandEnv("${HOME}/.cache/fsouza-dotfiles")
	}

	zsh, err := findZsh()
	if err != nil {
		log.Fatalf("couldn't find zsh: %v", err)
	}
	configFile := os.ExpandEnv("${HOME}/.config/alacritty.toml")
	stat, err := os.Lstat(configFile)
	if err == nil && stat.Mode()&os.ModeSymlink != 0 {
		err = os.Remove(configFile)
		if err != nil {
			log.Fatalf("failed to remove symlink: %v", err)
		}
	}

	file, err := os.OpenFile(configFile, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0o644)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	err = config.Execute(file, TemplateData{
		FontSize:         *fontSize,
		DotfilesDir:      dotfilesDir,
		DotfilesCacheDir: dotfilesCacheDir,
		Shell:            zsh,
	})
	if err != nil {
		log.Fatal(err)
	}
}

func findZsh() (string, error) {
	output, err := exec.Command("brew", "--prefix", "zsh").CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("error: %v, output: %s", err, output)
	}
	prefix := strings.TrimSpace(string(output))
	return filepath.Join(prefix, "bin", "zsh"), nil
}

var config = template.Must(template.New("config").Parse(`
[colors.bright]
black = "#000000"
blue = "#2c8ef8"
cyan = "#07a689"
green = "#23aa00"
magenta = "#cc4685"
red = "#f2201f"
white = "#c7c7c7"
yellow = "#999902"

[colors.normal]
black = "#000000"
blue = "#0225c7"
cyan = "#00c5c7"
green = "#00c200"
magenta = "#c930c6"
red = "#c91b00"
white = "#c7c7c7"
yellow = "#606000"

[colors.primary]
background = "#f0f0eb"
foreground = "#000000"

[cursor]
unfocused_hollow = true

[cursor.style]
blinking = "Never"
shape = "Block"

[env]
FSOUZA_DOTFILES_DIR = "{{.DotfilesDir}}"
FSOUZA_DOTFILES_CACHE_DIR = "{{.DotfilesCacheDir}}"
SHELL = "{{.Shell}}"
TERM = "alacritty-direct"
ZDOTDIR = "{{.DotfilesDir}}/zsh"

[font]
size = {{.FontSize}}

[font.bold]
style = "Medium"

[font.normal]
family = "Office Code Pro"
style = "Regular"

[[keyboard.bindings]]
action = "CreateNewWindow"
key = "N"
mods = "Command"

[[keyboard.bindings]]
chars = "\u001Bt"
key = "T"
mods = "Command"

[[keyboard.bindings]]
chars = "\u001Ba"
key = "A"
mods = "Command"

[[keyboard.bindings]]
chars = "\u001Bj"
key = "J"
mods = "Command"

[[keyboard.bindings]]
chars = "\u001Bk"
key = "K"
mods = "Command"

[[keyboard.bindings]]
chars = "\u0000"
key = "Space"
mods = "Control"

[[keyboard.bindings]]
action = "None"
key = "Space"
mods = "Shift|Control"

[[keyboard.bindings]]
chars = "\u001E"
key = "Key6"
mods = "Control"

[[keyboard.bindings]]
chars = "\u001E"
key = "Key7"
mods = "Control"

[scrolling]
history = 50000
multiplier = 3

[shell]
program = "{{.Shell}}"
args = ["--login"]

[window]
dynamic_padding = true
option_as_alt = "OnlyLeft"

[window.padding]
x = 2
y = 2
`))
