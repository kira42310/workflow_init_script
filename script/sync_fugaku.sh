#!/bin/bash -x
#PJM -L "node=1"
#PJM -L "rscgrp=small"
#PJM -L "elapse=00:10:00"
#PJM -x PJM_LLIO_GFSCACHE=/vol0004:/vol0003:/vol0002
#PJM -s
#

echo "Initialize the workflow setup on Fugaku compute node"

echo "========================================"
echo "Load Spack module"
. /vol0004/apps/oss/spack/share/spack/setup-env.sh
spack load /s46kiy2 # python@3.11.6@fj4.11.2

echo "========================================"
echo "Create Virtual Environment for Server"
env_dir="${HOME}/workflow_env"
compute_dir="${env_dir}/wf_compute"
compute_bin="${compute_dir}/bin"

echo "========================================"
echo "Install Prefect Workflow, Integration, Wrapper, and PSI/J"
#export VIRTUAL_ENV=$compute_dir
#uv pip install cloudpickle --no-cache-dir
target="${compute_dir}/lib/python3.11/site-packages"
$compute_bin/python -m pip install -r requirements.txt --no-cache-dir
#$compute_bin/python -m pip install cloudpickle --no-cache-dir --target $target
#unset VIRTUAL_ENV

echo "==================== Initilize Fugaku Successful ===================="
