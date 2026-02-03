#!/bin/bash
#SBATCH -p ondemand-reserved
#SBATCH -c 8
#SBATCH --time 1:00:00
#SBATCH --mem 30g

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

host=0.0.0.0
apihost=$(hostname -f)
dbhost=0.0.0.0
dbuser="postgres"
#dbpass="prefectpass"
dbname="prefect"

echo "Setup PostgreSQL Database"

# Check the directories exist and if it not exist, create a new directories
if ! [ -d $database_dir ]; then
  ( mkdir $(echo $database_dir | tr -d '\r') ) 
fi
if ! [ -d $db_tmp_dir ]; then
  ( mkdir $(echo $db_tmp_dir | tr -d '\r') ) 
fi
if ! [ -d $container_dir ]; then
  ( mkdir $(echo $container_dir | tr -d '\r') ) 
fi

# Download postgres image from docker hub and convert to singularity image
singularity pull $container_dir/postgres.sif docker://postgres:alpine 
# Initialize Postgres database
singularity exec $container_dir/postgres.sif initdb --username=$dbuser -c unix_socket_directories=$db_tmp_dir --pgdata=$database_dir
# Find a free port to host Postgres database
dbport=$(python -c "import socket; s = socket.socket( socket.AF_INET, socket.SOCK_STREAM ); s.bind(('', 0)); addr = s.getsockname(); print( addr[1] ); s.close()")
# Start Postgres database for create the Prefect database and put to background
singularity exec -e --env PGDATA=$database_dir $container_dir/postgres.sif postgres -h $dbhost -p $dbport -c unix_socket_directories=$db_tmp_dir &
# Wait for Postgres database to start up
sleep 15
# Create the empty Prefect database
singularity exec $container_dir/postgres.sif psql --username=$dbuser -h $dbhost -p $dbport -c "CREATE DATABASE prefect"

# For Prefect to connect to database
export PREFECT_API_DATABASE_CONNECTION_URL="postgresql+asyncpg://$dbuser@$dbhost:$dbport/$dbname"

# Initialize the Prefect database
prefect server database reset -y

# For killing the job along with the Postgres database background process
scancel $SLURM_JOB_ID
