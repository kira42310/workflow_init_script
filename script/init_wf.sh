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
echo "Check uv is instlled. If not, this script will install uv"
if ! uv --version; then
  echo "Install UV"
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

echo "========================================"
echo "Create Virtual Environment for Server"
env_dir="${HOME}/workflow_env"
if ! [ -d $env_dir ]; then
  ( mkdir $(echo $env_dir | tr -d '\r') ) 
fi
server_dir="${env_dir}/wf_server"
server_bin="${server_dir}/bin"
(cd $(echo $env_dir | tr -d '\r')  && uv venv wf_server)

echo "========================================"
echo "Install Prefect Workflow, Integration, Wrapper, and PSI/J"
export VIRTUAL_ENV=$server_dir
uv pip install prefect --no-cache-dir
uv pip install cloudpickle --no-cache-dir
uv pip install psij-python --no-cache-dir
uv pip install "git+https://github.com/kira42310/prefect-psij-integration" --no-cache-dir
uv pip install "git+https://github.com/kira42310/psij_wrapper" --no-cache-dir
unset VIRTUAL_ENV
git clone https://github.com/kira42310/psij_pjsub_template.git
( cd ./psij_pjsub_template && bash modify_psij.sh $(echo $server_dir | tr -d '\r') )
rm -rf psij_pjsub_template

echo "========================================"
echo "Execute the Python Envionment Setup on Fugaku"
pjsub -g $1 init_wf_fugaku.sh --no-check-directory
sleep 1
pjstat
echo "Please wait for the initilize Fugaku compute node to finished by checking with pjstat command"
echo "To use the workflow, activate the Python virual environment in ${server_bin}/activate"

echo "==================== Initilize Successful ===================="
