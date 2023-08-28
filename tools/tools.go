package tools

import (
	"fmt"
	"io"
	"io/fs"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"syscall"
)

func Exec(argv []string) {
	executable, err := exec.LookPath(argv[0])
	if err != nil {
		log.Fatal(err)
	}
	argv[0] = executable
	err = syscall.Exec(executable, argv, os.Environ())
	if err != nil {
		log.Fatal(err)
	}
}

type RunOptions struct {
	Cmd  string
	Args []string
	Cwd  string
	Env  map[string]string
}

// Run executes a command forwarding stdout, stderr and stdin.
func Run(opts *RunOptions) error {
	var env []string
	if len(opts.Env) > 0 {
		for k, v := range opts.Env {
			env = append(env, fmt.Sprintf("%s=%s", k, v))
		}
		env = append(env, os.Environ()...)
	}

	c := exec.Command(opts.Cmd, opts.Args...)
	c.Stderr = os.Stderr
	c.Stdout = os.Stdout
	c.Stdin = os.Stdin
	c.Dir = opts.Cwd
	c.Env = env
	err := c.Run()
	if err != nil {
		return fmt.Errorf("failed to run command '%s %s': %v", opts.Cmd, strings.Join(opts.Args, " "), err)
	}
	return err
}

func DownloadFile(url, path string, perm fs.FileMode) error {
	resp, err := http.Get(url)
	if err != nil {
		return fmt.Errorf("failed to download %q: %v", url, err)
	}
	defer resp.Body.Close()
	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("failed to download %q: got error while reading the body: %v", url, err)
	}
	if resp.StatusCode > 299 {
		return fmt.Errorf("failed to download %q: server returned %d - %s", url, resp.StatusCode, data)
	}
	return os.WriteFile(path, data, perm)
}
