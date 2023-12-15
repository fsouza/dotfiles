package main

import (
	"compress/gzip"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"

	"github.com/fsouza/dotfiles/tools"
	"golang.org/x/sync/errgroup"
)

func setupLangervers(nv *Neovim) error {
	langserversDir := filepath.Join(nv.CacheDir, "langservers")
	dirServers := []func(string) error{
		installGopls,
		installRustAnalyzer,
	}

	var g errgroup.Group
	g.Go(installServersFromNpm)

	for _, dirServer := range dirServers {
		dirServer := dirServer
		g.Go(func() error {
			return dirServer(langserversDir)
		})
	}

	return g.Wait()
}

func installGopls(langserversDir string) error {
	if _, err := exec.LookPath("go"); err != nil {
		log.Print("skipping gopls")
		return nil
	}

	repoDir := filepath.Join(langserversDir, "tools")
	err := gitCloneOrUpdate("https://github.com/golang/tools.git", repoDir)
	if err != nil {
		return err
	}

	return tools.Run(&tools.RunOptions{
		Cmd:  "go",
		Args: []string{"install"},
		Cwd:  filepath.Join(repoDir, "gopls"),
		Env: map[string]string{
			"GOBIN":   filepath.Join(langserversDir, "bin"),
			"GOPROXY": "https://proxy.golang.org",
		},
	})
}

func installRustAnalyzer(langserversDir string) error {
	if _, err := exec.LookPath("rustup"); err != nil {
		log.Print("skipping rust-analyzer")
		return nil
	}

	var arch string
	var manufacturer string
	osName := runtime.GOOS
	if osName == "linux" {
		manufacturer = "unknown"
		osName = "linux-gnu"
	} else {
		// assume linux or macos
		manufacturer = "apple"
	}

	switch runtime.GOARCH {
	case "arm64":
		arch = "aarch64"
	case "amd64":
		arch = "x86_64"
	}

	downloadURL := fmt.Sprintf("https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/rust-analyzer-%s-%s-%s.gz", arch, manufacturer, osName)
	resp, err := http.Get(downloadURL)
	if err != nil {
		return fmt.Errorf("[rust-analyzer] failed to connect to the download server: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode > 299 {
		data, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("[rust-analyzer] unexpected response from the server at %q:\n%d\n%s", downloadURL, resp.StatusCode, data)
	}

	gzReader, err := gzip.NewReader(resp.Body)
	if err != nil {
		return fmt.Errorf("[rust-analyzer] failed to create gzip reader: %v", err)
	}

	targetBin := filepath.Join(langserversDir, "bin", "rust-analyzer")
	err = os.MkdirAll(filepath.Dir(targetBin), 0o755)
	if err != nil {
		return fmt.Errorf("[rust-analyzer] %v", err)
	}

	bin, err := os.OpenFile(targetBin, os.O_CREATE|os.O_RDWR|os.O_TRUNC, 0o755)
	if err != nil {
		return fmt.Errorf("[rust-analyzer] %v", err)
	}
	defer bin.Close()
	_, err = io.Copy(bin, gzReader)
	if err != nil {
		return fmt.Errorf("[rust-analyzer] failed to write binary: %v", err)
	}
	return nil
}

func installServersFromNpm() error {
	fnmDir := filepath.Join(dotfilesDir, "nvim", "langservers")
	err := tools.Run(&tools.RunOptions{
		Cmd:  "fnm",
		Args: []string{"install"},
		Cwd:  fnmDir,
	})
	if err != nil {
		return err
	}

	return tools.Run(&tools.RunOptions{
		Cmd: "fnm",
		Args: []string{
			"exec",
			"npx",
			"--yes",
			"yarn",
			"install",
			"--frozen-lockfile",
		},
		Cwd: fnmDir,
	})
}

func setupFnlfmt(nv *Neovim, hererocksDir string) error {
	repoDir := filepath.Join(nv.CacheDir, "fnlfmt")
	err := gitCloneOrUpdate("https://git.sr.ht/~technomancy/fnlfmt", repoDir)
	if err != nil {
		return err
	}

	return tools.Run(&tools.RunOptions{
		Cmd:  "make",
		Args: []string{"-C", repoDir},
		Env: map[string]string{
			"PATH": fmt.Sprintf("%s/bin:%s", hererocksDir, os.Getenv("PATH")),
		},
	})
}
