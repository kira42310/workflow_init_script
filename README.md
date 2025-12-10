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
User should copy `run_workflow.sh` to the directory that Python file located. 

### Flags

| <div style="width:140px">Flags</div> | Explain |
| ---- | ---- |
| `-t`, `--walltime` | [Optional] This flag configures the wall time for the Pre-post node to run the Prefect server |
| `-c`, `--cpu` | [Optional] This flag configures the number of cpu allocation |
| `-m`, `--mem` | [Optional] This flag configures the memory allocation |
| `--python_bin` | [Optional] This flag configures the Python binary location to execute the Python that should installed with Prefect workflow. The default is the Python binary set up through the initialize script |

### Remark
This script will allocate the Pre-post node and run the instant Prefect server with the user Python file that contain the Prefect workflow code.

## Example code

- ![#f03c15](https://placehold.co/15x15/f03c15/f03c15.png)  On Fugaku(`pjsub`), the node_count parameter resource from PSI/J is not utilize because it use int type, but the node parameter for Fugaku(`pjsub`) is a shape of the allocation node not just a number of allocate node. We use string for declared the node allocation on PSI/J Fugaku(`pjsub`) template. By declared it with `custom_attributes` and use `node_shape.node`  as key and node configuration as value.
- The unique parameters `pjsub` template has are:

| key | value type |
| ---- | ---- |
| `node_shape.node` | `str` |
| `mpi_shape.shape` | `str` |
| `group`* | `str` |
| `pjsub_env.key`** | `str` |
| `pjsub_others`* | `str` |

\* For now please use `group.a` and `pjsub_others.a`

\*\* This will create the `-x` flag according to Fugaku(`pjsub`) manual

- The basic PSI/J spec can check the it on PSI/J website [link](https://exaworks.org/psij-python/docs/v/0.9.9/.generated/tree.html#jobspec)
- The duration must declared with `datetime.timedelta` [link](https://docs.python.org/3/library/datetime.html#timedelta-objects)


### Simple code (No Quantum)

```python
from prefect import task, flow
from prefect_psij import PSIJTaskRunner
from datetime import timedelta
import os

spec = {
  'executable': '~/workflow_env/wf_compute/bin/python',
  'queue_name': 'small',
  'name': 'small_workflow_spec',
  'duration': timedelta( minutes = 4 ),
  'custom_attributes': {
    'group.a': '<group_name>',
    'pjsub_env.PJM_LLIO_GFSCACHE':'/vol0003:/vol0004:/vol0002:/vol0006',
    'node_shape.node': '1'
  }
}

@task
def n_add( a, b ):
  return a + b

@task
def n_mul( a, b ):
  return a * b

@flow
def small_test():
  cwd = os.getcwd()
  with PSIJTaskRunner( instance = 'pjsub', job_spec = spec, work_directory = cwd, keep_files = True ) as tr:
    job = tr.submit(
      task = n_add,
      parameters = { 'a': 1, 'b': 2 }
    )
    c = job.result()
  print( f'a+b: {c}' )
  with PSIJTaskRunner( instance = 'pjsub', job_spec = spec, work_directory = cwd, keep_files = True ) as tr:
    job = tr.submit(
      task = n_mul,
      parameters = { 'a': 2, 'b': c }
    )
    res = job.result()
  print( f'2x(a+b): {res}' )

if __name__ == '__main__':
  df = small_test()
```

### Quantum-HPC hybrid code with Shor's algorithm

```python
from qiskit import QuantumCircuit
from qiskit.transpiler import generate_preset_pass_manager
from qiskit_ibm_runtime import QiskitRuntimeService, SamplerV2

from fractions import Fraction

import pandas as pd
import numpy as np

from prefect import task, flow
from prefect_psij import PSIJTaskRunner
from datetime import timedelta

hpc_spec = {
  'executable': '~/workflow_env/wf_compute/bin/python',
  'queue_name': 'small',
  'name': 'hpc_workflow_spec',
  'custom_attributes': {
    'duration': timedelta( hours = 4 ),
    'group.a': '<group_name>',
    'pjsub_env.PJM_LLIO_GFSCACHE':'/vol0003:/vol0004:/vol0002:/vol0006',
    'node_shape.node': '1'
  }
}

qc_spec = {
  'executable': '~/workflow_env/wf_compute/bin/python',
  'queue_name': 'q-IBM-S',
  'name': 'qc_workflow_spec',
  'custom_attributes': {
    'duration': timedelta( hours = 4 ),
    'group.a': '<group_name>',
    'pjsub_env.PJM_LLIO_GFSCACHE':'/vol0003:/vol0004:/vol0002:/vol0006',
    'node_shape.node': '1'
  }
}

@flow
def shor_algorithm():
  with PSIJTaskRunner( instance = 'pjsub', job_spec = qc_spec ) as tr:
    qc_job = tr.submit(
      task = qc_task_func,
      parameters = {}
    )
    result = qc_job.result()
  print( result )
  with PSIJTaskRunner( instance = 'pjsub', job_spec = hpc_spec ) as tr:
    hpc_job = tr.submit(
      task = hpc_task_func,
      parameters = { 'result': result, 'qubits': 8 }
    )
    result = hpc_job.result()
  print( result )
  return result

@task
def qc_task_func( ):
  # setup backend, select the device
  service = QiskitRuntimeService(
    channel='ibm_quantum_platform',
    token='s5Ordaxv7UIEghpd_bEXXFPAKKa_hQVxdWPwwUCjC6hJ',
    instance='crn:v1:bluemix:public:quantum-computing:us-east:a/fc93289da39b4de6b7c94ee611ed4500:21d9bef2-1abe-4001-b94f-5a102e406235::' )
  backend = service.backend( 'ibm_kobe' )

  # circuit construct
  a = 7
  qubits = 8
  qc = shor_circuit( a, qubits )

  # transpile and optimize the circuit
  pm = generate_preset_pass_manager( backend=backend, optimization_level=1 )
  isa_qc = pm.run(qc)

  # set option
  options = {
    "default_shots": 10000,
  }
  sampler = SamplerV2( mode=backend, options=options )

  # run
  result = sampler.run([isa_qc]).result()

  return result

@task
def hpc_task_func( result, qubits ):
  counts = result[0].join_data().get_counts()

  rows = []
  for output in counts:
    decimal = int(output, 2)
    phase = decimal / (2**qubits)
    frac = Fraction(phase).limit_denominator(15)
    rows.append([
      f"{output}(bin) = {decimal}(dec)",
      f"{decimal}/{2**qubits} = {phase:.5f}",
      f"{frac.numerator}/{frac.denominator}",
      f"{frac.denominator}"
    ])
  headers = ["Register Output", "Phase", "Fraction", "Guess for r"]
  df = pd.DataFrame( rows, columns=headers )
  return df
  
  def c_amod15( a, power ):
  """Controlled multiplication by a mod 15"""
  if a not in [2,4,7,8,11,13]:
      raise ValueError("'a' must be 2,4,7,8,11 or 13")
  U = QuantumCircuit(4)
  for _iteration in range(power):
      if a in [2,13]:
          U.swap(2,3)
          U.swap(1,2)
          U.swap(0,1)
      if a in [7,8]:
          U.swap(0,1)
          U.swap(1,2)
          U.swap(2,3)
      if a in [4, 11]:
          U.swap(1,3)
          U.swap(0,2)
      if a in [7,11,13]:
          for q in range(4):
              U.x(q)
  U = U.to_gate()
  U.name = f"{a}^{power} mod 15"
  c_U = U.control()
  return c_U

def qft_dagger( n ):
  """n-qubit QFTdagger the first n qubits in circ"""
  qc = QuantumCircuit(n)
  # Don't forget the Swaps!
  for qubit in range(n//2):
      qc.swap(qubit, n-qubit-1)
  for j in range(n):
      for m in range(j):
          qc.cp(-np.pi/float(2**(j-m)), m, j)
      qc.h(j)
  qc.name = "QFT†"
  return qc

  def shor_circuit( a, qubits = 8 ):
  # Create QuantumCircuit with N_COUNT counting qubits
  # plus 4 qubits for U to act on
  qc = QuantumCircuit( qubits + 4, qubits )

  for i in range( qubits ):
    qc.h(i)

  # And auxiliary register in state |1>
  qc.x(qubits)

  # Do controlled-U operations
  for i in range( qubits ):
    qc.append( c_amod15(a, 2**i), [i] + [ k + qubits for k in range(4)] )

  # Do inverse-QFT
  qc.append( qft_dagger(qubits), range(qubits) )

  # Measure circuit
  qc.measure( range(qubits), range(qubits) )
  return qc

if __name__ == '__main__':
  df = shor_algorithm()
  print( df )
```

### Multilanguage Execution code

![#f03c15](https://placehold.co/15x15/f03c15/f03c15.png) In development and can be change in the near future. User can test it for now by following this example code.

In this example, the user need to compile MPI application before execute workflow/Python application and call the application using `executable` parameter. To pass and receive the parameters or results to and from MPI application, users should write a file to MPI to read manually and make the MPI application write the file and use another task to read the file back to the Python workflow. 
```python
from prefect import task, flow
from prefect_psij import PSIJTaskRunner
from datetime import timedelta
import os

mpi_spec = {
  'executable': 'mpirun',
  'arguments': ['-n', '4', './a.out'],
  'queue_name': 'small',
  'name': 'mpi_workflow_spec',
  'duration': timedelta( minutes = 4 ),
  'custom_attributes': {
    'group.a': '<group_name>',
    'pjsub_env.PJM_LLIO_GFSCACHE':'/vol0003:/vol0004:/vol0002:/vol0006',
    'node_shape.node': '4'
  }
}

py_spec = {
  'executable': '~/workflow_env/wf_compute/bin/python',
  'queue_name': 'small',
  'name': 'py_workflow_spec',
  'duration': timedelta( minutes = 4 ),
  'custom_attributes': {
    'group.a': '<group_name',
    'pjsub_env.PJM_LLIO_GFSCACHE':'/vol0003:/vol0004:/vol0002:/vol0006',
    'node_shape.node': '1'
  }
}

@task
def test_python( ):
    a = 1+1
    return a

@task
def call_mpi( ):
    pass

@flow
def mpi_test():
  cwd = os.getcwd()
  with PSIJTaskRunner( instance = 'pjsub', job_spec = mpi_spec, work_directory = cwd, keep_files = False ) as tr:
   job = tr.submit(
     task = call_mpi,
     parameters = None
   )
   job.wait()

  with PSIJTaskRunner( instance = 'pjsub', job_spec = py_spec, work_directory = cwd, keep_files = False ) as tr:
    job = tr.submit(
      task = test_python,
      parameters = None
    )
    a = job.result()
    print( a )

if __name__ == '__main__':
  mpi_test()
  print( "MPI Test Finish" )
```

#### MPI code used in the example
```c
#include <mpi.h>
#include <stdio.h>

int main(int argc, char** argv) {
    // Initialize the MPI environment
    MPI_Init(NULL, NULL);

    // Get the number of processes
    int world_size;
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);

    // Get the rank of the process
    int world_rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

    // Get the name of the processor
    char processor_name[MPI_MAX_PROCESSOR_NAME];
    int name_len;
    MPI_Get_processor_name(processor_name, &name_len);

    // Print off a hello world message
    printf("Hello world from processor %s, rank %d out of %d processors\n",
           processor_name, world_rank, world_size);

    // Finalize the MPI environment.
    MPI_Finalize();
}
```