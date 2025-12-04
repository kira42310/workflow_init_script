#!/bin/bash

python_file=$1; shift
if [[ "$python_file" != *.py ]]; then
  echo "Please provide a python file"
  exit 1
fi

python_bin=$HOME/workflow_env/wf_server/bin/python
wtime="168:00:00" # 7 days
ncpu="4"
mem="16g"

while [ ! $# -eq 0 ]; do
  case $1 in
    -t | --walltime)
      if [ "$2" ]; then
	wtime=$2
	shift
      else
	echo "Please fill the wall time"
	exit 1
      fi
      ;;
    -c | --cpu)
      if [ "$2" ]; then
	ncpu=$2
	shift
      else
	echo "Please fill the number of cpu"
	exit 1
      fi
      ;;
    -m | --mem)
      if [ "$2" ]; then
	mem=$2
	shift
      else
	echo "Please fill the memory"
	exit 1
      fi
      ;;
    --python_bin)
      if [ "$2" ]; then
	python_bin=$2
	shift
      else
	echo "Please locate the Python binary"
	exit 1
      fi
      ;;
    *)
      echo "Found unknow flag(s)"
      exit 1
      ;;
  esac
  shift
done

execute="$python_bin $python_file"

srun -p ondemand-reserved -c $ncpu --time=$wtime --mem $mem --pty $execute
