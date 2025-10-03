#!/bin/bash

if [ -z "$1" ]; then
  echo "Please provide the group name"
  exit 1
fi

echo "Initialize the workflow setup"

echo "========================================"
echo "Load Spack Python module"
. /vol0004/apps/oss/spack/share/spack/setup-env.sh
spack load /so5pyv6 # python@3.11.6@gcc

echo "========================================"
echo "Check uv is instlled. If not, exit"
if ! uv --version; then
  echo "Please run the initialize script first"
  exit 1
fi


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
pjsub -g $1 sync_fugaku.sh --no-check-directory
sleep 1
pjstat
echo "Please wait for the initilize Fugaku compute node to finished by checking with pjstat command"
echo "To use the workflow, activate the Python virual environment in ${server_bin}/activate"

echo "==================== Initilize Successful ===================="
