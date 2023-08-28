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
	FontSize    float64
	DotfilesDir string
	Shell       string
}

func main() {
	fontSize := flag.Float64("font-size", 12.0, "font size")
	flag.Parse()

	dotfilesDir, ok := os.LookupEnv("FSOUZA_DOTFILES_DIR")
	if !ok {
		log.Fatal("missing FSOUZA_DOTFILES_DIR")
	}

	zsh, err := findZsh()
	if err != nil {
		log.Fatalf("couldn't find zsh: %v", err)
	}
	configFile := os.ExpandEnv("${HOME}/.config/alacritty.yml")
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
		FontSize:    *fontSize,
		DotfilesDir: dotfilesDir,
		Shell:       zsh,
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
window:
  padding:
    x: 2
    y: 2

  dynamic_padding: true
  option_as_alt: OnlyLeft

scrolling:
  history: 50000
  multiplier: 3

font:
  normal:
    family: SauceCodePro Nerd Font Mono
    style: Regular

  bold:
    style: Semibold

  size: {{.FontSize}}

colors:
  primary:
    background: "#ececec"
    foreground: "#000000"

  normal:
    black: "#000000"
    red: "#c91b00"
    green: "#00c200"
    yellow: "#606000"
    blue: "#0225c7"
    magenta: "#c930c6"
    cyan: "#00c5c7"
    white: "#c7c7c7"

  bright:
    black: "#000000"
    red: "#f2201f"
    green: "#23aa00"
    yellow: "#efef00"
    blue: "#1a8fff"
    magenta: "#fd28ff"
    cyan: "#00c5c7"
    white: "#c7c7c7"

env:
  FSOUZA_DOTFILES_DIR: {{.DotfilesDir}}
  ZDOTDIR: {{.DotfilesDir}}/zsh

mouse:
  double_click:
    threshold: 100
  triple_click:
    threshold: 100

cursor:
  style:
    shape: Block
    blinking: Never
  unfocused_hollow: true

shell:
  program: {{.Shell}}
  args:
    - --login

key_bindings:
  - key: N
    mods: Command
    action: CreateNewWindow
  - key: T
    mods: Command
    chars: "\x1bt"
  - key: A
    mods: Command
    chars: "\x1ba"
  - key: J
    mods: Command
    chars: "\x1bj"
  - key: K
    mods: Command
    chars: "\x1bk"
  - key: Space
    mods: Control
    chars: "\x00"
  - key: Space
    mods: Shift|Control
    action: None
  - key: Key6
    mods: Control
    chars: "\x1e"
  - key: Key7
    mods: Control
    chars: "\x1e"
`))
