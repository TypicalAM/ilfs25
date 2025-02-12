package main

import (
	"bytes"
	"crypto/sha256"
	"embed"
	"encoding/hex"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"

	"fmt"
	"net/http"
)

//go:embed build-qcow2.nix
var qcowDir embed.FS
var qcowBuilderFilename = "build-qcow2.nix"

var instantiateCommand = []string{"nix-instantiate", "--parse", "--readonly-mode", "--timeout", "5", "-"}
var outputPath = "./output"
var buildMtx = sync.Mutex{}

// https://stackoverflow.com/questions/21060945/simple-way-to-copy-a-file
func Copy(src, dst string) (err error) {
	r, err := os.Open(src)
	if err != nil {
		return err
	}
	defer r.Close() // ignore error: file was opened read-only.

	w, err := os.Create(dst)
	if err != nil {
		return err
	}

	defer func() {
		// Report the error, if any, from Close, but do so
		// only if there isn't already an outgoing error.
		if c := w.Close(); err == nil {
			err = c
		}
	}()

	_, err = io.Copy(w, r)
	return err
}

func validateConfig(cfg string) (string, error) {
	out := bytes.Buffer{}
	cmd := exec.Command(instantiateCommand[0], instantiateCommand[1:]...)
	cmd.Stdin = strings.NewReader(cfg)
	cmd.Stdout = &out
	if err := cmd.Run(); err != nil {
		return "", err
	}
	return string(out.Bytes()), nil
}

func createImage(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	cfg, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Provide a config", http.StatusBadRequest)
		return
	}

	if _, err := validateConfig(string(cfg)); err != nil {
		log.Println(err)
		http.Error(w, "Invalid config, validate it with 'nix-instantiate --parse'", http.StatusBadRequest)
		return
	}

	hash := sha256.New()
	hash.Write(cfg)
	sum := hex.EncodeToString(hash.Sum(nil))

	if _, err = os.Stat(filepath.Join(outputPath, sum+".qcow2")); err == nil {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, "{\"filename\": \"%s.qcow2\"}", sum)
		return
	}

	builderCfg, err := qcowDir.ReadFile(qcowBuilderFilename)
	if err != nil {
		log.Println(err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	buildMtx.Lock()
	defer buildMtx.Unlock()

	if err = os.WriteFile("/tmp/machine-config.nix", cfg, 0600); err != nil {
		log.Println(err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	log.Println("Building", sum)
	out := bytes.Buffer{}
	errBuf := bytes.Buffer{}
	buildCmd := exec.Command("nix-build", "<nixpkgs/nixos>", "-A", "config.system.build.qcow2", "--out-link", "vm", "--arg", "configuration", string(builderCfg))
	buildCmd.Stdout = &out
	buildCmd.Stderr = &errBuf
	if err := buildCmd.Run(); err != nil {
		http.Error(w, "Server error", http.StatusInternalServerError)
		log.Println(string(out.Bytes()))
		log.Println(string(errBuf.Bytes()))
		return
	}

	log.Println(string(out.Bytes()))
	log.Println(string(errBuf.Bytes()))

	srcPath := "/app/vm/nixos.qcow2"
	dstPath := filepath.Join(outputPath, sum+".qcow2")
	if err = Copy(srcPath, dstPath); err != nil {
		log.Println(err)
		http.Error(w, "Copy error", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	fmt.Fprintf(w, "{\"filename\": \"%s.qcow2\"}", sum)
}

func main() {
	http.HandleFunc("/", createImage)
	fmt.Println("Starting server on :8080...")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		fmt.Println("Error starting server:", err)
	}
}
