FROM golang:1.23-bullseye

ARG UID=1000
ARG GID=1000

RUN apt update \
 && apt install -y curl openssh-server rsync qemu-system netcat ssh-tools jq \
 && apt clean \
 && groupadd -g $GID student \
 && useradd student -u $UID -g student -d /home/student \
 && mkdir /home/student /var/run/sshd /app \
 && chown student /home/student \
 && echo 'student:student' | chpasswd \
 && echo "export PATH=/go/bin:\$PATH" >> /home/student/.profile \
 && echo "/app/runner.sh" >> /home/student/.profile \
 && echo "exit" >> /home/student/.profile \
 && rm /etc/motd \
 && go install github.com/charmbracelet/gum@latest

COPY runner.sh /app
RUN chmod +x /app/runner.sh \
 && chown student /app/runner.sh

COPY first.nix /app

ENTRYPOINT ["/usr/sbin/sshd", "-D"]
