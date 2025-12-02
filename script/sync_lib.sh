#!/bin/bash

elapse="1:00:00"
group_name=

while [ ! $# -eq 0 ]; do
  case "$1" in
    -g | --group_name)
      if [ "$2" ]; then
	group_name=$2
	shift
      else
	 echo "Please fill the group name"
	 exit 1
       fi
      ;;
    --alloc_time)
      if [ "$2" ]; then
	elapse=$2
	shift
      else
	echo "Please fill the allocation time"
	exit 1
      fi
      ;;
  esac
  shift
done

if [ -z $group_name ]; then
  echo "Please provide the group name"
  exit 1
fi

echo "Syncing libraries"

echo "========================================"
echo "Load Spack Python module"
. /vol0004/apps/oss/spack/share/spack/setup-env.sh
spack load /ogthatq # set py-uv

echo "========================================"
echo "Save requirements.txt file"
env_dir="${HOME}/workflow_env"
server_dir="${env_dir}/wf_server"
server_bin="${server_dir}/bin"
export VIRTUAL_ENV=$server_dir
#uv pip install prefect --no-cache-dir
uv pip freeze >> requirements.txt
unset VIRTUAL_ENV

echo "========================================"
echo "Execute the Python libraries sync on Fugaku"
pjsub --no-check-directory -g $group_name -L "elapse=$elapse" sync_fugaku.sh
sleep 1
pjstat
echo "Please wait for the initilize Fugaku compute node to finished by checking with pjstat command"
echo "To use the workflow, activate the Python virual environment in ${server_bin}/activate"

echo "==================== Sync Successful ===================="
