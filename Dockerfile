FROM golang:1.23-bullseye

ARG UID=1000
ARG GID=1000

RUN apt update \
 && apt install -y sudo curl xz-utils \
 && apt clean \
 && groupadd -g $GID builder \
 && useradd builder -u $UID -g builder -d /home/builder \
 && mkdir /home/builder \
 && chown builder /home/builder \
 && echo "builder ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/user \
 && chmod 0440 /etc/sudoers.d/user \
 && (su builder --login -c 'curl -L https://nixos.org/nix/install | sh') \
 && apt remove -y curl xz-utils \
 && apt autoremove -y \
 && apt clean \
 && echo '. /home/builder/.nix-profile/etc/profile.d/nix.sh' >> /home/builder/.bashrc \
 && mkdir /etc/nix \
 && echo "system-features = kvm" > /etc/nix/nix.conf

COPY . /app

RUN go build -o /app/main /app/main.go \
 && chown -R builder /app

USER builder
ENV USER=builder
ENV PATH="/home/builder/.nix-profile/bin:$PATH"
ENV NIX_PROFILES=/nix/var/nix/profiles/default=/home/builder/.nix-profile
ENV NIX_PATH=/home/builder/.nix-defexpr/channels
ENV NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

WORKDIR /app
ENTRYPOINT ["/app/main"]
