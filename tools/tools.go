package tools

import (
	"log"
	"os"
	"os/exec"
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
