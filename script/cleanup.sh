#!/bin/bash

env_dir="${HOME}/workflow_env"
server_dir="${env_dir}/wf_server"
compute_dir="${env_dir}/wf_compute"
database_dir="${env_dir}/database"
db_tmp_dir="${env_dir}/db_tmp"
container_dir="${env_dir}/container"

rm -rf $database_dir
rm -rf $db_tmp_dir
rm -rf $container_dir
rm -rf $server_dir
rm -rf $compute_dir
rm $env_dir/start_server_slurm.sh
