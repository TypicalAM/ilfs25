# Basic CTF image builder for ILFS25

## Presentation

```sh
go install github.com/maaslalani/slides@latest
slides presentation.md
```

## Running

```sh
docker network create magic-network
docker run --rm -it --name builder -p 8080:8080 --network magic-network --device /dev/kvm:/dev/kvm -v ./blueprints:/app/output typicalam/basic-builder:latest
```

and

```sh
docker run --rm -it -p 22:22 --network magic-network --device /dev/kvm:/dev/kvm -v ./blueprints:/blueprint -v ./working-machines:/output typicalam/basic-runner:latest-first # kill with pkill sshd since sshd doesn't like ctrl+c
```

or

```sh
docker run --rm -it -p 22:22 --network magic-network --device /dev/kvm:/dev/kvm -v ./blueprints:/blueprint -v ./working-machines:/output typicalam/basic-runner:latest-second # kill with pkill sshd since sshd doesn't like ctrl+c

```

and then ssh into it:

```sh
ssh student@localhost # pass: student
```

You can also use the builder directly with a NixOS system module, for example with `curl`:

```sh
curl --data-binary @basic-runner/first.nix localhost:8080
# {"filename": "20927e1cd4b9b4a730ae6b96904d3802a847f5c36ffae74ab556b5308d7c6c96.qcow2"}
```
