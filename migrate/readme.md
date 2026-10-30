
# Script: migrate-normal.sh

## Description

The script [migrate-normal.sh](migrate-normal.sh) can be used to migrate files from a file system or fileset. It uses a customizable ILM policy [migrate.pol](migrate.pol). 


## Installation and configuration

Copy the script `migrate-normal.sh` and the policy `migrate.pol` to a directory of in a Storage Archive node. Make the script `migrate-normal.sh` executable. 

Adjust the parameters on top of the `migrate-normal.sh` script:

| Parameter | Description | Required | Example |
|-----------|-------------|----------|---------|
| s3Path | Defines the base path where the files and directories are located. | Yes | /ibm/archfs/buckets |
| fSet | Defines the name of the fileset. This parameter is only required, if `s3Path` is the path of a fileset. In this case this parameter must be set to the fileset name. | Only if `s3Path` is a fileset path | buckets | 
| bucket | Defines the name of the bucket. This parameter is only required if objects from a specific bucket must be processed. If multiple buckets under `s3Path` must be processed, then this parameter can be blank. | Only if a specific bucket must be processed | glacier | 
| tapePool | Defines the name of the Storage Archive EE tape pool used as target for migration. The syntax is `pool@library`. If two copies must be created, then two pools can be specified here (for example: `pool1@lib1 pool2@lib2`) | yes | pool1@lib1 |
| nodes | Defines the node names that execute migration. These nodes must be Storage Archive EE nodes. When this parameter is left blank, then the local node where the scripts are executed is used. This parameter can specify multiple node names separated with comma and no blank (e.g., `node1,node2`). This parameter can also specify a node class (e.g., `all`). | Yes | node1 |
| tFlag | Defines the action the policy engine performs on files. When set to blank, then identified files are processed (migrated, recalled or attributes set). When set to `-I test`, then files are identified and no action is performed on files. | Only when identified files must not be processed  | `-I test` (test mode) |


## Execution

The script `migrate-normal.sh` must be executed as `root` user. To execute the script:

```
# migrate-normal.sh
```


## Processing 

The script executes the policy engine (`mmapplypolicy`) with the policy file `migrate.pol`. 


## Output

Output of the script is logged to STDOUT and ends up within the output of the mmapplypolicy command


