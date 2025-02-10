# Basic image builder using NixOS

Run with:

```sh
docker run --rm -it -p 8080:8080 --device /dev/kvm:/dev/kvm -v ./output:/app/output typicalam/basic-builder:latest
```

And query using a NixOS system module, for example with `curl`:

```sh
curl -X POST -d @my_module.nix localhost:8080
```
