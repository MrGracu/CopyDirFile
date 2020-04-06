#!/bin/bash

#################
# +--------------------------------------------------+
# |  Copyright by Gracjan Mika ( https://gmika.pl )  |
# |              CopyDirFile for Linux               |
# +--------------------------------------------------+
# 
#  I am not responsible for any damage or loss of data suffered as a result of using this program.
#  By using this, you confirm that you agree with the above.
#  If you disagree with the above, you must do not use this.
# 
#  This script is created in spare time and may contain bugs or be underdeveloped.
#  If you found any bugs that I could miss or you would like to give advice, I would be grateful for this information.
#################

VERSION="1.0"

# Set CHECK_IF_DESTINATION_EXISTS value to "false" if you do not want to check that the destination path exists
# Default: CHECK_IF_DESTINATION_EXISTS=true
CHECK_IF_DESTINATION_EXISTS=true

SCRIPT_NAME="$( basename $0 )"
SCRIPT_DIR="$( dirname "${BASH_SOURCE[0]}" )"
FILE_TASKS="$( realpath ~/.CopyDirFile.tasks )"
FILE_TASKS_RUNNING="$( realpath ~/.CopyDirFile_running.tasks )"
FILE_TASKS_LOGS_DIR="$( realpath ~/ )/CopyDirFile_Logs"

if [[ ! -d "$FILE_TASKS_LOGS_DIR" ]]; then
  mkdir "$FILE_TASKS_LOGS_DIR"
fi

declare -a TASKS=()

if test -f "$FILE_TASKS" ; then
  while IFS= read -r line
  do
    eval "for command in $line; do TASKS+=( \"\$command\" ); done"
  done < "$FILE_TASKS"
fi

declare -a RUNNING_TASKS=()

if test -f "$FILE_TASKS_RUNNING" ; then
  while IFS= read -r line
  do
    TEMP_ARRAY=()
    eval "for command in $line; do TEMP_ARRAY+=( \"\$command\" ); done"
    ps -p ${TEMP_ARRAY[0]} > /dev/null && RUNNING_TASKS+=( "${TEMP_ARRAY[0]}" "${TEMP_ARRAY[1]}" )
  done < "$FILE_TASKS_RUNNING"

  > "$FILE_TASKS_RUNNING"
  for (( i=0; i<$((${#RUNNING_TASKS[@]}/2)); i++ ))
  do
    echo "${RUNNING_TASKS[$(($i*2))]} ${RUNNING_TASKS[$(($i*2+1))]}" >> "$FILE_TASKS_RUNNING"
  done
fi

USAGE_ADD="
USAGE:

  $SCRIPT_NAME add <source> <destination> <refresh_time> [<two_directions>]

DESCRIPTION:
  
  Creates a new copy task

- source - file or dir which you want to copy
- destination - file or dir where you want to copy source
- refresh_time - sets the time after which the task is executed again. The syntax can be as follows: <number><time_prefix>
  Time prefixes:
    s - seconds (recommended if changes need to be saved frequently)
    m - minutes (recommended for normal usage)
    h - hours (recommended if changes are rarely made)
- two_directions - (optional) parameter can only be used if the source and destination paths are the same type (DIR <--> DIR, File <--> File)!
  Type \"true\" if you want program to copy in two directions (from source to destination and from destination to source), if not, type \"false\". Default value if not specified is \"false\"

EXAMPLES:

 If you want to copy the contents of the directory without the folder itself, add the \".\" to the end of the path

   $SCRIPT_NAME add /home/user/. /home/copy/ 1h true

 If the path contains spaces, insert it between quotation marks

   $SCRIPT_NAME add /home/user/. \"/home/user/t e s t/.\" 30m

 If you want to copy the file to another place:

   $SCRIPT_NAME add /home/user/file.txt /home/copy/ 1h
"
USAGE_SHOW="
USAGE:
  
  $SCRIPT_NAME show <all|running|task_ID>

DESCRIPTION:
  
  Displays a list of created or running copy tasks

- all - displays all created copy tasks
- running - displays all copy tasks which are already running
- task_ID - display created copy task with given ID
"
USAGE_START="
USAGE:

  $SCRIPT_NAME start <all|task_ID>

DESCRIPTION:

  Runs copy tasks

- all - starts all the copy tasks that are in the program
- task_ID - starts the copy task with specified ID
"
USAGE_STOP="
USAGE:

  $SCRIPT_NAME stop <all|task_ID>

DESCRIPTION:

  Stops all or specified running copy tasks

- all - stops all copy tasks that are currently running
- task_ID - stops the copy task with specified ID which is currently running
"
USAGE_DEL="
USAGE:

  $SCRIPT_NAME del <all|task_ID>

DESCRIPTION:

  Deletes all or specified copy tasks

- all - deletes all copy tasks that are in the program and are NOT CURRENTLY RUNNING
- task_ID - deletes the copy task with specified ID (CAN NOT BE CURRENTLY RUNNING)
"

help_function ()
{
  echo "
This is HELP page of program CopyDirFile.

CopyDirFile is used to create tasks for copying files or folders to a given location every specified time period.
The program can be operated using commands whose syntax is as follows:

  add <source> <destination> <refresh_time> [<two_directions>]  - creates a new copy task
  show <all|running|task_ID>  - displays a list of created copy tasks
  start <all|task_ID>  - runs copy tasks
  del <all|task_ID>  - deletes all or specified copy tasks
  stop <all|task_ID>  - stops all or specified running copy tasks
  help  - display this help page
  about  - display information about this program
"
}

about_function ()
{
  echo "========================================"
  echo ""
  echo "         CopyDirFile for Linux"
  echo ""
  echo "             Version: $VERSION"
  echo ""
  echo "       Copyright by Gracjan Mika"
  echo "          ( https://gmika.pl )"
  echo ""
  echo "========================================"
}

add_function ()
{
  local ERROR=true
  local TWO_DIRECTIONS=false

  if [ "$#" -eq "4" ] || [ "$#" -eq "5" ] || [ "$#" -eq "2" ]; then
    if [ "$#" -eq "2" ]; then
      if [[ "$2" == "--help" ]] || [[ "$2" == "-help" ]] || [[ "$2" == "help" ]]; then
        echo "$USAGE_ADD"
        exit 0
      fi
    else
      if [[ -f "$( realpath "$2" )" || -d "$( realpath "$2" )" ]] && [[ -f "$( realpath "$3" )" || -d "$( realpath "$3" )" || "$CHECK_IF_DESTINATION_EXISTS" == "false" ]]; then
        if [[ "$4" =~ ^([0-9]{1,3}[smh])$ ]]; then
          if [[ -d "$( realpath "$2" )" && -f "$( realpath "$3" )" ]]; then
            echo "[ERROR] Can not copy DIR to FILE!"
            exit 3
          else
            if [[ "$( realpath "$2" )" != "$( realpath "$3" )" ]]; then
              if [ "$#" -eq "5" ]; then
                if [[ -d "$( realpath "$2" )" && -d "$( realpath "$3" )" ]] || [[ -f "$( realpath "$2" )" && -f "$( realpath "$3" )" ]]; then
                  if [[ "$5" =~ ^true$ ]] || [[ "$5" =~ ^false$ ]]; then
                    TWO_DIRECTIONS="$5"
                    ERROR=false
                  fi
                else
                  echo "[ERROR] two_directions (optional) parameter can only be used if paths exists and the source and destination paths are the same type (DIR <--> DIR, File <--> File)!"
                fi
              else
                ERROR=false
              fi
            else
              echo "[ERROR] Source and destination can not be the same!"
            fi
          fi
        fi
      else
        echo "[ERROR] One of the paths is invalid!"
      fi
    fi
  fi

  if [[ "$ERROR" == true ]]; then
    echo "$USAGE_ADD"
    exit 4
  fi

  local NUMBER="$((${#TASKS[@]}/5))"

  local SOURCE_PATH="$( realpath "$2" )"
  if [[ "$2" =~ \/\.$ ]] && [[ -d "$SOURCE_PATH" ]]; then
    SOURCE_PATH="$( realpath "$2" )/."
  fi

  local DESTINATION_PATH="$3"
  if [ "$CHECK_IF_DESTINATION_EXISTS" != "false" ]; then
    DESTINATION_PATH="$( realpath "$3" )"
    if [[ "$3" =~ \/\.$ ]] && [[ -d "$DESTINATION_PATH" ]]; then
      DESTINATION_PATH="$( realpath "$3" )/."
    fi
  fi

  local MAXIMUM=0
  for (( i=0; i<$NUMBER; i++ ))
  do
    if [[ "$SOURCE_PATH" == "${TASKS[$((i*5+1))]}" ]] && [[ "$DESTINATION_PATH" == "${TASKS[$((i*5+2))]}" ]]; then
      echo "[ERROR] Task with the given paths already exists!"
      exit 5
    fi

    if [ "${TASKS[$((i*5))]}" -gt "$MAXIMUM" ]; then
      MAXIMUM="${TASKS[$((i*5))]}"
    fi
  done

  let MAXIMUM++

  TASKS+=( "$MAXIMUM" )
  TASKS+=( "$SOURCE_PATH" )
  TASKS+=( "$DESTINATION_PATH" )
  TASKS+=( "$4" )
  TASKS+=( "$TWO_DIRECTIONS" )

  echo "${TASKS[$(($NUMBER*5))]} \"${TASKS[$(($NUMBER*5+1))]}\" \"${TASKS[$(($NUMBER*5+2))]}\" ${TASKS[$(($NUMBER*5+3))]} ${TASKS[$(($NUMBER*5+4))]}" >> "$FILE_TASKS"

  if [ $? ]; then 
    echo "[INFO] New task created with ID: $MAXIMUM"
  else
    echo "[ERROR] An error occurred while adding task!"
  fi
}

show_function ()
{
  local ERROR=true

  if [ "$#" -eq "2" ]; then
    if [[ "$2" == "--help" ]] || [[ "$2" == "-help" ]] || [[ "$2" == "help" ]]; then
      echo "$USAGE_SHOW"
      exit 0
    fi
    if [[ "$2" =~ ^all$ ]] || [[ "$2" =~ ^running$ ]] || [[ "$2" =~ ^[0-9]{1,3}$ ]]; then
      if [[ "$2" =~ ^all$ ]] || [[ "$2" =~ ^running$ ]]; then
        ERROR=false
      else
        if [[ "$2" =~ ^[0-9]{1,3}$ ]]; then
          local FOUND=false
          for (( i=0; i<$((${#TASKS[@]}/5)); i++ ))
          do
            if [[ "$2" == "${TASKS[$((i*5))]}" ]]; then
              FOUND=true
            fi
          done

          if [[ "$FOUND" == "true" ]]; then
            ERROR=false
          else
            echo "[ERROR] Entered task ID does not exist!"
            exit 6
          fi
        fi
      fi
    fi
  fi

  if [[ "$ERROR" == true ]]; then
    echo "$USAGE_SHOW"
    exit 7
  fi

  DIVIDER="================================="
  DIVIDER=$DIVIDER$DIVIDER$DIVIDER$DIVIDER$DIVIDER
  if [[ "$2" =~ ^running$ ]]; then
    printf "\n%10s  %3s  %-40s  %-40s  %7s  %13s\n" "PROCESS ID" "ID" "SOURCE" "DESTINATION" "REFRESH" "TWO DIRECTION"
    printf "%-123.123s\n" "$DIVIDER"

    for (( i=0; i<$((${#TASKS[@]}/5)); i++ ))
    do
      if [ "${#RUNNING_TASKS[@]}" -gt "0" ]; then
        for (( j=0; j<$((${#RUNNING_TASKS[@]}/2)); j++ ))
        do
          if [ "${TASKS[$((i*5))]}" -eq "${RUNNING_TASKS[$((j*2+1))]}" ]; then
            printf "%10s  %3s  %-40s  %-40s  %7s  %13s\n" "${RUNNING_TASKS[$((j*2))]}" "${TASKS[$((i*5))]}" "${TASKS[$((i*5+1))]}" "${TASKS[$((i*5+2))]}" "${TASKS[$((i*5+3))]}" "${TASKS[$((i*5+4))]}"
          fi
        done
      fi
    done
  else
    printf "\n%3s  %-40s  %-40s  %7s  %13s\n" "ID" "SOURCE" "DESTINATION" "REFRESH" "TWO DIRECTION"
    printf "%-111.111s\n" "$DIVIDER"

    for (( i=0; i<$((${#TASKS[@]}/5)); i++ ))
    do
      if [[ "$2" =~ ^all$ ]] || [[ "$2" == "${TASKS[$((i*5))]}" ]]; then
        printf "%3s  %-40s  %-40s  %7s  %13s\n" "${TASKS[$((i*5))]}" "${TASKS[$((i*5+1))]}" "${TASKS[$((i*5+2))]}" "${TASKS[$((i*5+3))]}" "${TASKS[$((i*5+4))]}"
      fi
    done
  fi
  echo ""
}

del_function ()
{
  local ERROR=true

  if [ "$#" -eq "2" ]; then
    if [[ "$2" == "--help" ]] || [[ "$2" == "-help" ]] || [[ "$2" == "help" ]]; then
      echo "$USAGE_DEL"
      exit 0
    fi
    if [[ "$2" =~ ^all$ ]] || [[ "$2" =~ ^[0-9]{1,3}$ ]]; then
      if [[ "$2" =~ ^all$ ]]; then
        SURE="n"
        read -p "Are you sure you want to delete all tasks? [y/n] " SURE
        if [[ "$SURE" =~ ^y$ ]]; then
          ERROR=false
        else
          echo "[ERROR] Operation canceled"
          exit 8
        fi
      else
        if [[ "$2" =~ ^[0-9]{1,3}$ ]]; then
          local FOUND=false
          for (( i=0; i<$((${#TASKS[@]}/5)); i++ ))
          do
            if [ "$2" -eq "${TASKS[$((i*5))]}" ]; then
              FOUND=true
            fi
          done

          if [[ "$FOUND" == "true" ]]; then
            ERROR=false
          else
            echo "[ERROR] Entered task ID does not exist!"
            exit 9
          fi
        fi
      fi
    fi
  fi

  if [[ "$ERROR" == true ]]; then
    echo "$USAGE_DEL"
    exit 10
  fi

  > "$FILE_TASKS"
  local REMOVED=false
  local PROBLEM=false

  for (( i=0; i<$((${#TASKS[@]}/5)); i++ ))
  do
    local TASK_ID=${TASKS[$(($i*5))]}
    local FOUND=false
    for (( j=0; j<$((${#RUNNING_TASKS[@]}/2)); j++ ))
    do
      if [ "$TASK_ID" -eq "${RUNNING_TASKS[$(($j*2+1))]}" ]; then
        FOUND=true
        break
      fi
    done
    if [[ "$FOUND" == true ]]; then
      echo "[ERROR] Task with ID $TASK_ID can not be deleted because is already running!"
      PROBLEM=true
    else
      if [[ "$2" == "$TASK_ID" ]]; then
        REMOVED=true
      fi
    fi

    if [[ "$2" == "$TASK_ID" && "$FOUND" == false ]] || [[ "$2" =~ ^all$ && "$FOUND" == false ]]; then
      if [ "$i" -eq "0" ]; then
        TASKS=( "${TASKS[@]:$(($i*5+5))}" )
      else
        TASKS=( "${TASKS[@]:0:$(($i*5))}" "${TASKS[@]:$(($i*5+5))}" )
      fi
      let i--
      echo "[INFO] Task with ID $TASK_ID deleted"
    else
      echo "${TASKS[$(($i*5))]} \"${TASKS[$(($i*5+1))]}\" \"${TASKS[$(($i*5+2))]}\" ${TASKS[$(($i*5+3))]} ${TASKS[$(($i*5+4))]}" >> "$FILE_TASKS"
    fi
  done
  if [[ "$PROBLEM" == true ]]; then
    exit 11
  fi
  if [[ "$2" =~ ^[0-9]{1,3}$ ]] && [[ "$REMOVED" == false ]]; then
    exit 12
  fi
}

create_new_task ()
{
  local TASK_PROCESS_ID=""
  local FILE_TASKS_LOGS="$FILE_TASKS_LOGS_DIR/Task_$1.log"
  local SOURCE="${TASKS[$(($2*5+1))]}"
  local DESTINATION="${TASKS[$(($2*5+2))]}"
  local REFRESH="${TASKS[$(($2*5+3))]}"
  local TWO_DIRECTIONS="${TASKS[$(($2*5+4))]}"

  while true; \
  do \
    if [[ -f "$SOURCE" || -d "$SOURCE" ]] && [[ -f "$DESTINATION" || -d "$DESTINATION" || "$CHECK_IF_DESTINATION_EXISTS" == "false" ]]; then \
      cp -au "$SOURCE" "$DESTINATION" >> "$FILE_TASKS_LOGS" 2>&1 || echo "[$(date +'%d/%m/%Y %R:%S')] ERROR: An error occurred while copying! The copy has not been made" >> "$FILE_TASKS_LOGS"; \
      if [[ "$TWO_DIRECTIONS" =~ ^true$ ]]; then \
        cp -au "$DESTINATION" "$SOURCE" >> "$FILE_TASKS_LOGS" 2>&1 || echo "[$(date +'%d/%m/%Y %R:%S')] ERROR: An error occurred while copying into second direction! The copy has not been made" >> "$FILE_TASKS_LOGS"; \
      fi; \
    else \
      echo "[$(date +'%d/%m/%Y %R:%S')] ERROR: One of the paths is invalid! The copy has not been made" >> "$FILE_TASKS_LOGS"; \
    fi; \
    sleep $REFRESH; \
  done &

  TASK_PROCESS_ID=$!
  RUNNING_TASKS+=( "$TASK_PROCESS_ID" "$1" )
  echo "$TASK_PROCESS_ID $1" >> "$FILE_TASKS_RUNNING"
  echo "[INFO] Task with ID $1 started with process ID: $TASK_PROCESS_ID"
}

start_function ()
{
  local ERROR=true

  if [ "$#" -eq "2" ]; then
    if [[ "$2" == "--help" ]] || [[ "$2" == "-help" ]] || [[ "$2" == "help" ]]; then
      echo "$USAGE_START"
      exit 0
    fi
    if [[ "$2" =~ ^all$ ]] || [[ "$2" =~ ^[0-9]+$ ]]; then
      if [[ "$2" =~ ^all$ ]]; then
        ERROR=false
      else
        local FOUND=false
        for (( i=0; i<$((${#TASKS[@]}/5)); i++ ))
        do
          if [[ "$2" == "${TASKS[$((i*5))]}" ]]; then
            FOUND=true
          fi
        done

        if [[ "$FOUND" == "true" ]]; then
          ERROR=false
        else
          echo "[ERROR] Entered task ID does not exist!"
          exit 13
        fi
      fi
    fi
  fi

  if [[ "$ERROR" == true ]]; then
    echo "$USAGE_START"
    exit 14
  fi

  for (( i=0; i<$((${#TASKS[@]}/5)); i++ ))
  do
    local TASK_ID=${TASKS[$((i*5))]}
    local FOUND=false
    if [[ "$2" =~ ^all$ ]] || [[ "$2" == "$TASK_ID" ]]; then
      if [ "${#RUNNING_TASKS[@]}" -gt "0" ]; then
        for (( j=0; j<$((${#RUNNING_TASKS[@]}/2)); j++ ))
        do
          if [ "$TASK_ID" -eq "${RUNNING_TASKS[$((j*2+1))]}" ]; then
            FOUND=true
            break
          fi
        done
      fi
      if [[ "$FOUND" == true ]]; then
        echo "[ERROR] Task with ID $TASK_ID is already running!"
        if [[ "$2" == "$TASK_ID" ]]; then
          exit 15
        fi
      else
        create_new_task "$TASK_ID" "$i"
        if [[ "$2" == "$TASK_ID" ]]; then
          exit 0
        fi
      fi
    fi
  done
}

stop_function ()
{
  local ERROR=true

  if [ "$#" -eq "2" ]; then
    if [[ "$2" == "--help" ]] || [[ "$2" == "-help" ]] || [[ "$2" == "help" ]]; then
      echo "$USAGE_STOP"
      exit 0
    fi
    if [[ "$2" =~ ^all$ ]] || [[ "$2" =~ ^[0-9]{1,3}$ ]]; then
      if [[ "$2" =~ ^all$ ]]; then
        ERROR=false
      else
        if [[ "$2" =~ ^[0-9]{1,3}$ ]]; then
          local FOUND=false
          for (( i=0; i<$((${#RUNNING_TASKS[@]}/2)); i++ ))
          do
            if [ "$2" -eq "${RUNNING_TASKS[$((i*2+1))]}" ]; then
              FOUND=true
            fi
          done

          if [[ "$FOUND" == "true" ]]; then
            ERROR=false
          else
            echo "[ERROR] The entered task ID is not currently running or does not exist!"
            exit 16
          fi
        fi
      fi
    fi
  fi

  if [[ "$ERROR" == true ]]; then
    echo "$USAGE_STOP"
    exit 17
  fi

  > "$FILE_TASKS_RUNNING"
  local TASK_ID=0
  local PROCESS_ID=0
  local PROBLEM=false
  for (( i=0; i<$((${#RUNNING_TASKS[@]}/2)); i++ ))
  do
    PROCESS_ID=${RUNNING_TASKS[$(($i*2))]}
    TASK_ID=${RUNNING_TASKS[$(($i*2+1))]}

    if [[ "$2" == "$TASK_ID" ]] || [[ "$2" =~ ^all$ ]]; then
      kill $PROCESS_ID

      if [ $? ]; then
        echo "[INFO] Running task $TASK_ID with process ID $PROCESS_ID has been stopped"
        if [ "$i" -eq "0" ]; then
          RUNNING_TASKS=( "${RUNNING_TASKS[@]:$(($i*2+2))}" )
        else
          RUNNING_TASKS=( "${RUNNING_TASKS[@]:0:$(($i*2))}" "${RUNNING_TASKS[@]:$(($i*2+2))}" )
        fi
        let i--
      else
        echo "[ERROR] An error occurred closing the copy task $TASK_ID with the given process ID $PROCESS_ID!"
        echo "$PROCESS_ID $TASK_ID" >> "$FILE_TASKS_RUNNING"
        PROBLEM=true
      fi
    else
      echo "$PROCESS_ID $TASK_ID" >> "$FILE_TASKS_RUNNING"
    fi
  done

  if [[ "$PROBLEM" == true ]]; then
    exit 18
  fi
}

if [ "$#" -eq "0" ]; then
  help_function
  exit 1
else
  case $1 in
    add )
      add_function "$@"
      ;;
    show )
      show_function "$@"
      ;;
    start )
      start_function "$@"
      ;;
    stop )
      stop_function "$@"
      ;;
    help | -h | --help )
      help_function
      exit 0
      ;;
    about | version )
      about_function
      ;;
    del | delete )
      del_function "$@"
      ;;
    * )
      echo "[ERROR] Command not found!"
      help_function
      exit 2
  esac
fi
exit 0