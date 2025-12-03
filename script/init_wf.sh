#!/bin/bash

py_version="3.11"
elapse="1:00:00"
queue="q-IBM-S"
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
    -q | --queue)
      if [ "$2" ]; then
	queue=$2
	shift
      else
	echo "Please fill the queue name"
	exit 1
      fi
      ;;
    --python_version)
      if [ "$2" ]; then
	py_version=$2
	shift
      else
	echo "Please fill the Python version"
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

echo "Initialize the workflow setup"

echo "========================================"
echo "Load Spack Python module"
. /vol0004/apps/oss/spack/share/spack/setup-env.sh
spack load /ogthatq # set py-uv

echo "========================================"
echo "Create Virtual Environment for Server"
env_dir="${HOME}/workflow_env"
if ! [ -d $env_dir ]; then
  ( mkdir $(echo $env_dir | tr -d '\r') ) 
fi
server_dir="${env_dir}/wf_server"
server_bin="${server_dir}/bin"
activate_bin="${server_bin}/activate"
python_bin="${server_bin}/python"
(cd $(echo $env_dir | tr -d '\r')  && uv venv --python $py_version wf_server)

echo "========================================"
echo "Install Prefect Workflow, Integration, Wrapper, and PSI/J"
#export VIRTUAL_ENV=$server_dir
. $(echo $activate_bin | tr -d '\r')
uv pip install prefect --no-cache-dir
uv pip install cloudpickle --no-cache-dir
uv pip install psij-python --no-cache-dir
uv pip install "git+https://github.com/kira42310/prefect-psij-integration" --no-cache-dir
uv pip install "git+https://github.com/kira42310/psij_wrapper" --no-cache-dir
#unset VIRTUAL_ENV
git clone https://github.com/kira42310/psij_pjsub_template.git
( cd ./psij_pjsub_template && bash modify_psij.sh $(echo $python_bin | tr -d '\r') )
rm -rf psij_pjsub_template

echo "========================================"
echo "Execute the Python Envionment Setup on Fugaku"
echo $py_version > python_version.tmp
pjsub --no-check-directory -g $group_name -L "elapse=$elapse" -L "rscgrp=$queue" -L "node=1" -x PJM_LLIO_GFSCACHE=/vol0004:/vol0003:/vol0002 init_wf_fugaku.sh
sleep 1
pjstat
echo "Please wait for the initilize Fugaku compute node to finished by checking with pjstat command"
echo "To use the workflow, activate the Python virual environment in ${server_bin}/activate"
echo "To install Python libraries, please use 'uv pip install <library_name>'"

echo "==================== Initilize Successful ===================="
