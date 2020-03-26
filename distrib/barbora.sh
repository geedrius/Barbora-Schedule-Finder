#!/bin/sh
## $PROG 1.0 - Barbora notification container and service
## 
## Usage: $PROG [OPTION...] [COMMAND]...
## Options:
##   -s, --status           Print service status
##   -c, --create           Create container
##   -p, --pull             Pull latest container image
##   -u, --update           Pull, stop, remove, create, start
##   -t, --tail             Tail service/container logs
## Commands:
##   -h, --help             Displays this help and exists
##   -v, --version          Displays output version and exists
## Examples:
##   $PROG --status
##   $PROG --update

# Skripto ideja: https://stackoverflow.com/a/47339704
PROG=${0##*/}

die() { echo $@ >&2; exit 2; }
help() {
  grep "^##" "$0" | sed -e "s/^...//" -e "s/\$PROG/$PROG/g"; exit 0
}
version() {
  help | head -1
}

# custom commands
NAME=barbora
SERVICE=${NAME}.service
IMAGE=barbora:latest
TELEGRAM_TOKEN=my-telegram-token

status() {
  /usr/bin/systemctl status ${SERVICE}
}
create() {
  /usr/bin/podman create --name ${NAME} \
    -e TELEGRAM_TOKEN=${TELEGRAM_TOKEN} \
    ${IMAGE}
}
pull() {
  echo "Manual build required"
}
update() {
  pull
  /usr/bin/systemctl stop ${SERVICE}
  /usr/bin/podman rm ${NAME}
  create
  /usr/bin/systemctl start ${SERVICE}
}
tail() {
  /usr/bin/journalctl -u ${SERVICE} -n 20 -f
}


[ $# = 0 ] && help
while [ $# -gt 0 ]; do
  CMD=$(grep -m 1 -Po "^## *$1, --\K[^= ]*|^##.* --\K${1#--}(?:[= ])" /pool1/containers/barbora.sh | sed -e "s/-/_/g")
  if [ -z "$CMD" ]; then echo "ERROR: Command '$1' not supported"; exit 1; fi
  shift; eval "$CMD" $@ || shift $? 2> /dev/null
done
