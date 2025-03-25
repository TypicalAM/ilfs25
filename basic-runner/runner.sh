#!/usr/bin/env bash

MEMORY=2048M
CPUS=4
NUM_MACHINES=5

USER_IP=$(echo "$SSH_CLIENT" | awk '{ print $1 }')
LAST_OCTET=$(echo "$USER_IP" | awk -F. '{print $NF}')
MACHINE_ID=$((LAST_OCTET % NUM_MACHINES))
MACHINE_PORT="2137$MACHINE_ID"

echof() {
	local color="$1"
	shift
	local text="$1"
	shift
	local command=("$@")
	gum spin \
		--spinner="dot" \
		--title="$text" \
		--spinner.foreground="$color" \
		--show-error \
		-- "${command[@]}"
}

# If a scanner catches that its going to be so funny lol
SSH_KEYFILE=$(mktemp)
cat >"$SSH_KEYFILE" <<EOF
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACC2T0pRaj9HBZ03DD1OAC6gQPKiVRCkylxrPrpZEuMW8AAAAJB9VCEBfVQh
AQAAAAtzc2gtZWQyNTUxOQAAACC2T0pRaj9HBZ03DD1OAC6gQPKiVRCkylxrPrpZEuMW8A
AAAECe5tJOc1cedLIr02d0PHrif2PDOc67v44ITokrY6ln1LZPSlFqP0cFnTcMPU4ALqBA
8qJVEKTKXGs+ulkS4xbwAAAAC2FkYW1AZmVkb3JhAQI=
-----END OPENSSH PRIVATE KEY-----
EOF

echof "#c6a0f6" "Building your machine" curl --silent --data-binary @/app/blueprint.nix builder:8080

BLUEPRINT_HASH="$(curl --silent --data-binary @/app/blueprint.nix builder:8080 | jq -r '.filename')"
BLUEPRINT_FILENAME="/blueprint/$BLUEPRINT_HASH"
FINAL_FILENAME="/output/$MACHINE_ID-$BLUEPRINT_HASH"

if [[ ! -e "$FINAL_FILENAME" ]]; then
	echof "#f5a97f" "Copying your machine" cp "$BLUEPRINT_FILENAME" "$FINAL_FILENAME"
	chmod 777 "$FINAL_FILENAME"
fi

# Check if this specific machine port, power it on
if ! nc -z localhost "$MACHINE_PORT" >/dev/null; then
	qemu-system-x86_64 \
		-m "$MEMORY" \
		-smp "$CPUS" \
		-drive file="$FINAL_FILENAME",format=qcow2 \
		-netdev "user,id=net0,hostfwd=tcp::$MACHINE_PORT-:22" \
		-device e1000,netdev=net0 \
		-nographic \
		>/dev/null 2>&1 &
fi

echof "#7dc4e4" "Waiting for SSH" sh -c "ssh-ping -p \"$MACHINE_PORT\" student@localhost | grep -m 1 Reply"
ssh \
	-p "$MACHINE_PORT" \
	-i "$SSH_KEYFILE" \
	-o "ConnectTimeout 5" \
	-o "UserKnownHostsFile /dev/null" \
	-o "StrictHostKeyChecking no" \
	student@localhost
