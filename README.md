# workflow_init_script
Initilize script for setup the workflow

# How to use the script

## Initialize workflow software environment script

### Executing the initialize script

```sh
bash ./init_wf.sh -g <group_name> 
```

### Flags

| <div style="width:140px">Flags</div> | Explain |
| ---- | ---- |
| `-g`, `--group_name` | [Mandatory] This flag configures the group name for validate the the use of a Fugaku node to set up the computing environment on Fugaku |
| `-q`, `--queue` | [Optional] This flag configures the queue/partition to use with Fugaku job scheduler for set up the computing environment on Fugaku node |
| `--alloc_time` | [Optional] This flag configures the wall time on allocate the Fugaku node |
| `--python_verion` | [Optional] This flag configures the script to set up the Python virtual environment with specific version |

### Remark
The main script `init_wf.sh` will set up the workflow server environment first and execute the `init_wf_fugaku.sh` file for set up the compute environment on Fugaku node.

## Sync libraries

### Executing the sync libraries script

```sh
bash ./sync_lib.sh -g <group_name>
```

### Flags

| <div style="width:140px">Flags</div> | Explain |
| ---- | ---- |
| `-g`, `--group_name` | [Mandatory] This flag configures the group name for validate the the use of a Fugaku node to set up the computing environment on Fugaku |
| `-q`, `--queue` | [Optional] This flag configures the queue/partition to use with Fugaku job scheduler for set up the computing environment on Fugaku node |
| `--alloc_time` | [Optional] This flag configures the wall time on allocate the Fugaku node |

### Remark
The main script `sync_lib.sh` will create the `requirement.txt` from the libraries on workflow server environment first and execute the `sync_fugaku.sh` to install the libraries on the Fugaku node from `requirement.txt` file.

## To run the workflow

### Run the workflow

```sh
bash ./run_workflow.sh <python_file> <flags>
```

### Flags

| <div style="width:140px">Flags</div> | Explain |
| ---- | ---- |
| `-t`, `--walltime` | [Optional] This flag configures the wall time for the Pre-post node to run the Prefect server |
| `-c`, `--cpu` | [Optional] This flag configures the number of cpu allocation |
| `-m`, `--mem` | [Optional] This flag configures the memory allocation |
| `--python_bin` | [Optional] This flag configures the Python binary location to execute the Python that should installed with Prefect workflow. The default is the Python binary set up through the initialize script |

### Remark
This script will allocate the Pre-post node and run the instant Prefect server with the user Python file that contain the Prefect workflow code.
