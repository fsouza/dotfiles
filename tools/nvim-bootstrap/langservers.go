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
		installKLS,
		installGroovyLS,
		installJDTLS,
		installZLS,
	}

	var g errgroup.Group
	g.Go(installServersFromNpm)
	g.Go(installOcamlLSP)

	for _, dirServer := range dirServers {
		dirServer := dirServer
		g.Go(func() error {
			return dirServer(langserversDir)
		})
	}

	return g.Wait()
}

func installGopls(langserversDir string) error {
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

func installKLS(langserversDir string) error {
	const javaVersion = "corretto-17"
	javaHome, err := getJavaHome(javaVersion)
	if err != nil {
		log.Printf("skipping kotlin-language-server. cannot find JAVA_HOME for %q: %v", javaVersion, err)
		return nil
	}

	repoDir := filepath.Join(langserversDir, "kotlin-language-server")
	err = gitCloneOrUpdate("https://github.com/fwcd/kotlin-language-server.git", repoDir)
	if err != nil {
		return fmt.Errorf("[kotlin-language-server] failed to update Git repo: %v", err)
	}

	return tools.Run(&tools.RunOptions{
		Cmd:  filepath.Join(repoDir, "gradlew"),
		Args: []string{"-PjavaVersion=17", ":server:installDist"},
		Cwd:  repoDir,
		Env:  map[string]string{"JAVA_HOME": javaHome},
	})
}

func installGroovyLS(langserversDir string) error {
	const javaVersion = "corretto-11"
	javaHome, err := getJavaHome(javaVersion)
	if err != nil {
		log.Printf("skipping groovy-language-server. cannot find JAVA_HOME for %q: %v", javaVersion, err)
		return nil
	}

	repoDir := filepath.Join(langserversDir, "groovy-language-server")
	err = gitCloneOrUpdate("https://github.com/GroovyLanguageServer/groovy-language-server.git", repoDir)
	if err != nil {
		return fmt.Errorf("[groovy-language-server] failed to update Git repo: %v", err)
	}

	return tools.Run(&tools.RunOptions{
		Cmd:  filepath.Join(repoDir, "gradlew"),
		Args: []string{"build"},
		Cwd:  repoDir,
		Env:  map[string]string{"JAVA_HOME": javaHome},
	})
}

func installJDTLS(langserversDir string) error {
	if _, err := exec.LookPath("rtx"); err != nil {
		log.Print("cannot find rtx, skipping jdtls")
		return nil
	}

	currentSnapshot := currentJDTLSSnapshot(langserversDir)
	latestSnapshot, err := latestJDTLSSnapshot()
	if err != nil {
		log.Printf("cannot determine latest snapshot of jdtls, skipping. error: %v", err)
		return nil
	}

	targetDir := filepath.Join(langserversDir, "jdtls")
	if currentSnapshot != latestSnapshot {
		if _, err := os.Stat(targetDir); err == nil {
			err = os.RemoveAll(targetDir)
			if err != nil {
				return fmt.Errorf("[jdtls] %v", err)
			}
		}

		err = os.MkdirAll(targetDir, 0o755)
		if err != nil {
			return fmt.Errorf("[jdtls] %v", err)
		}

		const lombokURL = "https://projectlombok.org/downloads/lombok.jar"

		var g errgroup.Group

		g.Go(func() error { return tools.DownloadFile(lombokURL, filepath.Join(targetDir, "lombok.jar"), 0o644) })
		g.Go(func() error { return downloadJDTLS(targetDir, latestSnapshot) })

		err = g.Wait()
		if err != nil {
			return fmt.Errorf("[jdtls] %v", err)
		}
	}

	return gitCloneOrUpdate(
		"https://github.com/dgileadi/vscode-java-decompiler.git",
		filepath.Join(targetDir, "vscode-java-decompiler"),
	)
}

func installZLS(langserversDir string) error {
	if _, err := exec.LookPath("zig"); err != nil {
		log.Print("cannot find zig, skipping zls")
		return nil
	}

	repoDir := filepath.Join(langserversDir, "zls")
	err := gitCloneOrUpdate("https://github.com/zigtools/zls.git", repoDir)
	if err != nil {
		return err
	}

	return tools.Run(&tools.RunOptions{
		Cmd:  "zig",
		Args: []string{"build", "-Doptimize=ReleaseSafe"},
		Cwd:  repoDir,
	})
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

func installOcamlLSP() error {
	if _, err := exec.LookPath("opam"); err != nil {
		log.Print("skipping ocaml-lsp")
		return nil
	}

	return tools.Run(&tools.RunOptions{
		Cmd: "opam",
		Args: []string{
			"install",
			"-y",
			"ocaml-lsp-server",
			"ocamlformat",
		},
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
