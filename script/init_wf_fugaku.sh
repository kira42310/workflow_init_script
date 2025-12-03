#!/bin/bash -x
#PJM -L "node=1"
#PJM -L "rscgrp=small"
#PJM -x PJM_LLIO_GFSCACHE=/vol0004:/vol0003:/vol0002
#

py_version=$(cat python_version.tmp)
rm python_version.tmp

echo "Initialize the workflow setup on Fugaku compute node"

echo "========================================"
echo "Load Spack module"
. /vol0004/apps/oss/spack/share/spack/setup-env.sh
spack load /dgkbxzl # py-uv

#echo "========================================"
#echo "Check uv is instlled. If not, this script will install uv"
#if ! uv --version; then
#  echo "Install UV"
#  curl -LsSf https://astral.sh/uv/install.sh | sh
#fi

echo "========================================"
echo "Create Virtual Environment for Server"
env_dir="${HOME}/workflow_env"
compute_dir="${env_dir}/wf_compute"
compute_bin="${compute_dir}/bin"
activate_bin="${compute_bin}/activate"
#(cd $(echo $env_dir | tr -d '\r')  && uv venv wf_compute --allow-existing)
(cd $(echo $env_dir | tr -d '\r')  && uv venv --python $py_version wf_compute )

echo "========================================"
echo "Install Prefect Workflow, Integration, Wrapper, and PSI/J"
#export VIRTUAL_ENV=$compute_dir
. $(echo $activate_bin | tr -d '\r' )
uv pip install cloudpickle --no-cache-dir
#target="${compute_dir}/lib/python3.11/site-packages"
#$compute_bin/python -m pip install cloudpickle --no-cache-dir
#$compute_bin/python -m pip install cloudpickle --no-cache-dir --target $target
#unset VIRTUAL_ENV

echo "==================== Initilize Fugaku Successful ===================="
