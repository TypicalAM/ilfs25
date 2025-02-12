---
author: Adam Piaseczny
date: dd.mm.YYYY
---

# Who needs an image? Creating a CTF platform with NixOS

Solving the most painful point of local CTF hosting using open source software.

## How can I see this with my own eyes?

```sh
go install github.com/maaslalani/slides@latest
curl -L piaseczny.dev/docs/ilfs25.md | slides
```

or bypassing `eduroam` entirely, without using `go`:

```sh
ssh -p imap relay.piaseczny.dev
```

## Meta

- Date: 13.02.2025
- Interrupt me - I like talking about this! (depends on how we are doing time-wise)

---

# whoami

I'm TypicalAM, also sometimes known as tpam:

- RED Team Leader @PUTrequest_
- Gentle lover
- [Open source contributor](https://github.com/TypicalAM)
- [Blogger](https://piaseczny.dev)

I've made my fair share of Capture The Flag (CTF) challenges in the past and solved a ton of them in recent years

---

# Hosting a CTF

As you might guess running a security-oriented academic circle sometimes makes you ask yourelf the big questions:

- Are we really alone in this universe?
- Am I really fit for this?
- How can we provide a CTF platform for students to solve homemade challenges locally?

Today I will try to answer the third one.

---

# CTF

## What is frustrating about competing in CTFs in the wild:

- You are on a machine with 40 people on it
- Someone deleted a flag (or a pivotal piece of info needed to capture it)
- Your machine reset, you lost all progress

## What is frustrating about hosting CTF systems:

- Letting people upload VM images gets really tedious really quickly 
- Handling formats of VM images and configs like OVA, libvirt, qcow, etc.
- Conservation of compute

We should try to build something that solves some of those problems

---

# Nix and NixOS

## Context

- Nix is a package manager that allows using a special language (also called nix) to declaratively build packages.
- NixOS allows for composing entire system configurations using the same language.
- Nix was designed to build for many platforms and systems, including `qcow2`, a file format for disk image files used by `qemu`.

## Idea

We can create a service which takes in a NixOS configuration module and spits out a `qcow2` image.

- Easy transport of files (just text)
- Faster iteration (author can just test it on a NixOS machine)
- Machine versions are now easily vcs-trackable

---

# Flow

- Host provides a config, gets an image
- Host finds out some way to ID the user, so the user gets connected to the same VM
- If a new ID arrives, the host sends a request to the image API, waits for building
- Copies the image for the new user and runs it with `qemu` on it
- Users with existing IDs get connected to the same machine

---

# Example

## Hosting a docker breakout CTF

We want the participant to:
- Connect to our server via SSH
- Wait until the machine has been built and copied (we can cache builds here)
- Be load balanced via the unique `SSH_CLIENT` environment variable

Since we do not want to require the host to run on NixOS, we provide a `qcow` builder using docker.

```sh
docker run --rm -it -p 8080:8080 \
    --device /dev/kvm:/dev/kvm -v ./output:/app/output typicalam/basic-builder:latest
```

You can find the code [here](https://github.com/TypicalAM/ilfs25):

---

# Example

## Creating the CTF part

The user should ideally:

- Notice that they are in a privileged container
- Escalate their privileges
- Get the flag in the root directory

We as the system designers should:

- Expose an SSH port for the users to connect to
- Drop them into a child SSH session inside of the VM
- Have the VM SSH session initialize a new privileged ubuntu contianer
- Drop them inside of the container TTY

---

# Example

## Creating the NixOS module part

Creating a guest SSH agent, letting the host connect to it using a known public and private keys.

## Advanced user identification and handling

The best and most secure way to handle arbitrary users connecting to your machine via SSH is obviously `bash`. So let's walk through the basic part. We can identify users based on the `SSH_CLIENT` env var and balance them using the last IPv4 byte.

## Small demo

---

# That's it!

Thanks for listening!

You can see and run everything [here](https://github.com/TypicalAM/ilfs25)
