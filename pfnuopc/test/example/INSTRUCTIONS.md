# LND-ParFlow NUOPC Test Application Instructions

## Configuration
1. edit nuopc_test.cfg
| pfAttribute        | Description                           |
| ------------------ | ------------------------------------- |
| Verbosity          | integer interpreted as a bit field    |
| Diagnostic         | integer interpreted as a bit field    |
| realize_all_import | true, false                           |
| realize_all_export | true, false                           |
| filename           | ParFlow configuration file            |
| initialize_import  | true, false                           |
| initialize_export  | true, false                           |
| check_import       | check import time stamp               |
| geom               | field geometric object                |
| share_field_mem    | import and export fields share memory |
| output_directory   | ParFlow cap output directory          |

## Execution
```
mpirun -np 1 ./parflow-nuopc-test
```

## Slurm Workload Manager
1. edit slurm_template.sh
    - partition=<partition_names>
    - account=<account>
    - constraint=<list>
    - qos=<qos>
    - setup environment as needed
```
sbatch slurm_template.sh
```

## Validation
Successful execution produces evaptrans, press, and satur files through 00003.

[Slurm Documentation](https://slurm.schedmd.com/documentation.html)
