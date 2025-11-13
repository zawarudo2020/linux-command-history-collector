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

  echo "$(date +"%Y-%m-%dT%H:%M:%S%:z") $(hostname) USER=$(whoami) ; TTY='"$login_tty"' ; LOGIN_IP='"$login_ip"' ; PROCESS=$pname ; PID=$pid ; COMMAND=$cmd ; PWD=$(pwd) ;"
} >> /opt/logs/.histlog'
