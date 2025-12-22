#!/bin/bash
#SBATCH -p ondemand-reserved
#SBATCH -c 8
#SBATCH --time 400:00:00
#SBATCH --mem 30g

#while [ ! $# -eq 0 ]; do
#  case "$1" in
#    -g | --group_name)
#      if [ "$2" ]; then
#	group_name=$2
#	shift
#      else
#	echo "Please fill the group name"
#	exit 1
#      fi
#      ;;
#    -q | --queue)
#      if [ "$2" ]; then
#	queue=$2
#	shift
#      else
#	echo "Please fill the queue name"
#	exit 1
#      fi
#      ;;
#    --python_version)
#      if [ "$2" ]; then
#	py_version=$2
#	shift
#      else
#	echo "Please fill the Python version"
#	exit 1
#      fi
#      ;;
#    --alloc_time)
#      if [ "$2" ]; then
#	elapse=$2
#	shift
#      else
#	 echo "Please fill the allocation time"
#	 exit 1
#      fi
#      ;;
#  esac
#  shift
#done

echo "========================================"
echo "Activate Python"

env_dir="${HOME}/workflow_env"
server_dir="${env_dir}/wf_server"
server_bin="${server_dir}/bin"
activate_bin="${server_bin}/activate"
python_bin="${server_bin}/python"
. $(echo $activate_bin | tr -d '\r')

#host=0.0.0.0
host=$(hostname -f)
port=$(python -c "import socket; s = socket.socket( socket.AF_INET, socket.SOCK_STREAM ); s.bind(('', 0)); addr = s.getsockname(); print( addr[1] ); s.close()")

echo $SLURM_JOB_ID > "$env_dir/server_info"
echo "$host:$port" >> "$env_dir/server_info"

prefect server start --host $host --port $port
