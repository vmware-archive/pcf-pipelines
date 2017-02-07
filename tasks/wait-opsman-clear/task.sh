#!/bin/bash -u
#This script polls ops mgr waiting for pending changes and running installs to be empty before beginning
#POLL_INTERVAL controls how quickly the script will poll ops mgr for changes to pending changes/running installs

POLL_INTERVAL=30
function main() {

  chmod +x tool-om/om-linux
  CMD_PATH="./tool-om/om-linux"

  local cwd
  cwd="${1}"

  while :
  do

      ${CMD_PATH} --target "${OPSMAN_URI}" \
           --skip-ssl-validation \
           --username "${OPSMAN_USERNAME}" \
           --password "${OPSMAN_PASSWORD}" \
            curl -path /api/v0/staged/pending_changes > changes-status.txt

      if [[ $? -ne 0 ]]; then
        echo "Could not login to ops man"
        cat changes-status.txt
        exit 1
      fi

      ${CMD_PATH} --target "${OPSMAN_URI}" \
           --skip-ssl-validation \
           --username "${OPSMAN_USERNAME}" \
           --password "${OPSMAN_PASSWORD}" \
           curl -path /api/v0/installations > running-status.txt

      if [[ $? -ne 0 ]]; then
        echo "Could not login to ops man"
        cat running-status.txt
        exit 1
      fi

      grep "action" changes-status.txt
      ACTION_STATUS=$?
      grep "\"status\": \"running\"" running-status.txt
      RUNNING_STATUS=$?

      if [[ ${ACTION_STATUS} -ne 0 && ${RUNNING_STATUS} -ne 0 ]]; then
          echo "No pending changes or running installs detected. Proceeding"
          exit 0
      fi
      echo "Pending changes or running installs detected. Waiting"
      sleep $POLL_INTERVAL
  done
}

main "${PWD}"
