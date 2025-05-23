#!/bin/sh

whoami_txt=$(who am i)
login_ip=$(echo "$whoami_txt" | awk -F"[()]" '{print $2}')
login_user=$(echo "$whoami_txt" | awk '{print $1}')
login_tty=$(echo "$whoami_txt" | awk '{print $2}')

> ~/.bash_history

export PROMPT_COMMAND='{
  cmd=$(history 1 | { read x c; echo "$c"; });
  pid=$$;
  pname=$(ps -p $pid -o comm=);
  net=$(lsof -nP -p $pid 2>/dev/null | grep TCP | tr "\n" " ");
  echo "$(date "+%b %e %T") $(hostname) sudo: '"$login_user"': TTY='"$login_tty"' ; LOGIN_IP='"$login_ip"' ; PWD=$(pwd) ; USER=$(whoami) ; COMMAND=$cmd ; PROCESS=$pname ; PID=$pid ; NET=$net"
} >> /var/log/.histlog'

if [ -z "$(readonly -p | grep PROMPT_COMMAND)" ]; then
  readonly PROMPT_COMMAND
fi
