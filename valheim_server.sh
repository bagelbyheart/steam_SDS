#!/bin/sh
#
# Name: Valheim_Tool
# Auth: Stephen Ancona (steve@bagelbyheart.com)
# Vers: 0.0.8

# General Variables
PROCNAME="valheim_server.x86_64"
STEAMAPP="896660"
STEAMDIR="/home/steam"
SERVICE_NAME="Valheim server"
SERVERDIR="Dedicated_Servers/Valheim_Server"
SAVEDIR="Dedicated_Servers/Valheim_Worlds"

# Game Specific Variables
SERVERNAME="Vangard Gaming"
SERVERPORT='2456'
WORLDNAME="GoobaNew"
SERVERPASS="Welcome Home"
LATEST="Valheim.Latest.out"


updater () {
 PROCESSES=$(ps auxw)
 if PROCESS=$(echo "$PROCESSES" | grep "$PROCNAME"); then
  echo "${SERVICE_NAME} is currently running. Stop before updating."
  return 1
 else
 steamcmd\
 +@sSteamCmdForcePlatformType linux\
 +force_install_dir "$STEAMDIR"/"$SERVERDIR"\
 +login anonymous\
 +app_update "$STEAMAPP"\
 -beta none validate\
 +quit
 fi
 }


real_server_start () {
 export templdpath="$LD_LIBRARY_PATH"
 export LD_LIBRARY_PATH="./linux64:$LD_LIBRARY_PATH"
 export SteamAppId=892970
 cd "$STEAMDIR"/"$SERVERDIR"
 ./$PROCNAME\
 -name "$SERVERNAME"\
 -port "$SERVERPORT"\
 -savedir "$STEAMDIR"/"$SAVEDIR"\
 -world "$WORLDNAME"\
 -password "$SERVERPASS"\
 -crossplay
 export LD_LIBRARY_PATH="$templdpath"
 }


start_server () {
 PROCESSES=$(ps auxw)
 TSTAMP=$(date +%FT%H%M%S)
 LOGNAME="Valheim.${TSTAMP}.out"
 if PROCESS=$(echo "$PROCESSES" | grep "$PROCNAME"); then
  echo "${SERVICE_NAME} is already running."
  return 1
 else
  echo "Starting ${SERVICE_NAME}."
  # real_server_start 2>&1 > "$LOGNAME" &
  real_server_start
  # sleep 30
  # PROCESSES=$(ps auxw)
  # if PROCESS=$(echo "$PROCESSES" | grep "$PROCNAME"); then
  #  echo "Valheim appears to be running."
  #  ln -f -s "$LOGNAME" "$LATEST"
  #  return 0
  # else
  #  echo "It appears Valheim failed to start."
  #  echo "Check $LOGNAME for details."
  #  return 1
  #  fi
  fi
}


stop_server () {
 PROCESSES=$(ps auwx)
 if PROCESS=$(echo "$PROCESSES" | grep "$PROCNAME"); then
  PID=$(echo "$PROCESS" | awk '{print $2}')
  echo "Killing ${SERVICE_NAME} process at pid: $PID"
  kill -INT "$PID"
  echo "Waiting 30s then checking kill"
  sleep 30
  PROCESSES=$(ps auwx)
  if PROCESS=$(echo "$PROCESSES" | grep "$PROCNAME"); then
   echo "Failed to kill ${SERVICE_NAME}. Investigate below process:"
   echo "$PROCESS"
   return 1
  else
   echo "${SERVICE_NAME} is no longer running"
   return 0
   fi
 else
  echo "${SERVICE_NAME} is not running"
  return 0
  fi
 }


reboot_server () {
 if stop_server; then
  updater
  start_server
  fi
 }


# not used by current script
status_server () {
 PROCESSES=$(ps auwx)
 if PROCESS=$(echo "$PROCESSES" | grep "$PROCNAME"); then
  PID=$(echo "$PROCESS" | awk '{print $2}')
  echo "${SERVICE_NAME} is currently running on pid: $PID"
 else
  echo "${SERVICE_NAME} is not currently running."
  fi
 }


# not used by current script
monitor_server () {
 PROCESSES=$(ps auxw)
 if PROCESS=$(echo "$PROCESSES" | grep "$PROCNAME"); then
  echo "${SERVICE_NAME} is running, starting tail."
  tail -n 80 -F "${LATEST}"
 else
  echo "${SERVICE_NAME} is not currently running."
  fi
 }


case "$1" in
 "start")
  start_server
  ;;
 "stop")
  stop_server
  ;;
 "upgrade")
  reboot_server
  ;;
 *)
  echo "Run as: $0 [start|stop|upgrade]"
  ;;
 esac
