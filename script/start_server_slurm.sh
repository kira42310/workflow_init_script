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
database_dir="${env_dir}/database"
db_tmp_dir="${env_dir}/db_tmp"
container_dir="${env_dir}/container"
server_dir="${env_dir}/wf_server"
server_bin="${server_dir}/bin"
activate_bin="${server_bin}/activate"
python_bin="${server_bin}/python"
. $(echo $activate_bin | tr -d '\r')

# host=$(hostname -f)
host=0.0.0.0
apihost=$(hostname -f)
dbhost=0.0.0.0
dbuser="postgres"
dbpass="prefectpass"
dbname="prefect"
#postgres_img=/home/u13266/container_file/postgres_16.11-alpine.sif

dbport=$(python -c "import socket; s = socket.socket( socket.AF_INET, socket.SOCK_STREAM ); s.bind(('', 0)); addr = s.getsockname(); print( addr[1] ); s.close()")
# singularity exec $container_dir/postgres.sif initdb -c unix_socket_directories=$db_tmp_dir --pgdata=$database_dir --username=$dbuser -A password --pwfile=<(echo $dbpass)
# singularity exec -e --env PGDATA=$database_dir,POSTGRES_USER=$dbuser,POSTGRES_PASSWORD=$dbpass,PGDATABASE=$dbname $container_dir/postgres.sif postgres -h 0.0.0.0 -p $dbport -c unix_socket_directories=$db_tmp_dir &
singularity exec -e --env PGDATA=$database_dir $container_dir/postgres.sif postgres -h $dbhost -p $dbport -c unix_socket_directories=$db_tmp_dir &
sleep 15
#export PREFECT_API_DATABASE_CONNECTION_URL="postgresql+asyncpg://$dbuser:$dbpass@$host:$dbport/$dbname"
export PREFECT_API_DATABASE_CONNECTION_URL="postgresql+asyncpg://$dbuser@$dbhost:$dbport/$dbname"

port=$(python -c "import socket; s = socket.socket( socket.AF_INET, socket.SOCK_STREAM ); s.bind(('', 0)); addr = s.getsockname(); print( addr[1] ); s.close()")

echo $SLURM_JOB_ID > "$env_dir/server_info"
echo "$apihost:$port" >> "$env_dir/server_info"
echo $PREFECT_API_DATABASE_CONNECTION_URL >> "$env_dir/server_info"

prefect config set PREFECT_API_URL=http://$apihost:$port/api
prefect server start --host $host --port $port
