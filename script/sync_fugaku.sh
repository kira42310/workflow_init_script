#!/bin/bash -x

echo "Sync libraries on Fugaku compute node"

echo "========================================"
echo "Load Spack module"
. /vol0004/apps/oss/spack/share/spack/setup-env.sh
spack load /dgkbxzl # py-uv

echo "========================================"
echo "Create Virtual Environment for Server"
env_dir="${HOME}/workflow_env"
compute_dir="${env_dir}/wf_compute"
compute_bin="${compute_dir}/bin"

echo "========================================"
echo "Install Prefect Workflow, Integration, Wrapper, and PSI/J"
export VIRTUAL_ENV=$compute_dir
uv pip install -r requirements.txt --no-cache-dir
rm requirements.txt
#target="${compute_dir}/lib/python3.11/site-packages"
#$compute_bin/python -m pip install -r requirements.txt --no-cache-dir
#$compute_bin/python -m pip install cloudpickle --no-cache-dir --target $target
#unset VIRTUAL_ENV

echo "==================== Sync Fugaku Successful ===================="
