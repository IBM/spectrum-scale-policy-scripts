# Introduction

This project includes scripts and ILM policies to manage migration and restores of S3 GLACIER objects ingested through the Storage Scale S3 service in IBM Storage Scale file systems. 


**Note:** Storage Scale S3 service does not (yet) support S3 Glacier. As an alternative the open-source project [NooBaa](https://github.com/noobaa/noobaa-core/) can be used to provide the S3 service. The scripts and policies in this project work with open-source Noobaa as well. 


Foundational information for managing migration and restores for S3 Glacier objects are provided in the [noobaaGlacier project](../noobaaGlacier). This project provides scripts and associated policies that allow managing migration and restores out-of-the-box.


## System environment

The scripts and policies of this project require a IBM Storage Scale cluster with S3 service enabled (CES S3) and IBM Storage Archive to manage the space in the file system. Objects and buckets created via the Storage Scale S3 service are stored as files and directories in the Storage Scale file system. 

The scripts and policies in this project allow migration and restores for S3 Glacier objects. AWS S3 Glacier provides additional API functions on top of the S3 API. The S3 Glacier API facilitates retrieval or restoration of objects from high latency media like tapes. Object stored in a S3 Glacier storage class cannot be retrieved using normal S3 GET requests. Instead, the S3 user must first issue the `Restore-Object` request provided by the S3 Glacier API to request the recall from tape. After the object was recalled from tape, the user can use the normal S3 GET request to retrieve the object. 


# Installation

The following files are included in this projects:

| File name | Description |
|-----------|-------------|
| Readme.md | This readme file with comprehensive instructions for installation, configuration and usage |
| mig-glacier.sh  | Script to migrate S3 glacier objects |
| migrate.pol  | Migrate policy executed by `mig-glacier.sh` |
| rest-glacier.sh | Script to restore S3 Glacier objects | 
| recall.pol | External List policy that recalls objects using the interface script `recall.sh` |
| recall.sh | Interface script invoked by the recall policy `recall.pol` |
| setattr.pol | External List policy that sets attributes for recalled objects using the interface script `setattr.sh` |
| setattr.sh | Interface script invoked by the set attribute policy `setattr.pol` |


The scripts and policies included in this project must be installed on at least one Storage Archive nodes. If there is more than one Storage Archive nodes in the cluster, then all Storage Archive could be used to execute the policies. In this case install the scripts and policies on all Storage Archive nodes in the same path (e.g., `/usr/local/bin`)

Clone the repository:

```
# cd /tmp
# git clone git@github.com:IBM/spectrum-scale-policy-scripts
```

Change to this project's directory:

```
# cd spectrum-scale-policy-scripts/s3glacier
```

Copy the file to a common directory such as `/usr/local/bin`

```
# cp * /usr/local/bin
```

Make the scripts executable

```
cd /usr/local/bin
# chmod +x mig-glacier.sh
# chmod +x rest-glacier.sh*
# chmod +x recall.sh
# chmod +x setattr.sh
```

Configure and test the scripts using instructions in section [Workflows](#Workflows)



# Workflows

The typical workflow for Glacier objects is the following

1. The S3 user issues a PUT request for an object with storage-class set to GLACIER into a bucket. Example with the AWS CLI:

   ```
   # aws s3api put-object --bucket glacier --body coldfile0 --key coldfile0 --storage-class GLACIER
   ```

2. New S3 Glacier objects are migrated to tape by the [Migration](#Migration) process.  The migration process is started by a scheduler and executes a migration policy. 

3. The S3 user issues a `Restore-Object` request for an object. Example with the AWS CLI:

   ```
   # aws s3api restore-object --bucket glacier --key coldfile0 --restore-request '{"Days": 1}'
   ```
   
4. Objects requested for restore are restored by the [Restore](#Restore) process. The restore process is started by a scheduler. It runs in two phases: (1) objects requested for restore are recalled from tape by leveraging a ILM policy. (2) recalled objects are marked for access by setting file attributes. 

5. The S3 user can now retrieve the object using a normal GET request

   ```
   # aws s3api get-object --bucket glacier --key coldfile0 coldfile0
   ```

The migration and recall processes are implemented in scripts and policies and are further explained below. 


## Migration

After object are created for storage class GLACIER in the bucket, the [migration script](mig-glacier.sh) can be executed. Usually the migration script is executed by a scheduler.

The [migration script](mig-glacier.sh) has a section at the beginning where different parameters are defined. Here is an overview of the parameters that must be defined:

| Parameter | Description | Requires | Example |
|-----------|-------------|----------|---------|
| s3Path | Base path where buckets are stored. This is usually the `new-bucket-path` for S3 accounts. If there are multiple buckets, then consider to place all or a subset of buckets in the same base path (e.g., fileset).  | yes | /ibm/archfs/demo |
| fSet | Fileset name of the base path, if the base path is a fileset. If not leave this blank (""). | yes | demo |
| bucket | Name of the bucket to be migrated. If the name is blank `("")` then all objects stored in base path `s3Path` are migrated. This is appropriate if there there multiple buckets in the base path | yes  | glacier |
| scriptPath | Path where the script and policies of this project are stored | yes | /usr/local/bin |
| polFile | Path and filename of the migrate policy `migrate.pol` | yes | migrate.pol |
| tapePool | Name of the Storage Archive tape pool | yes | pool1@lib1 |
| nodes | Node names that execute the policy. When set to `""`, then it defaults to the local nodes. Multiple nodes are provide as `node1,node2`. When multiple nodes are specified, then the policies and scripts must be installed on all nodes in the same directory | no | node1 |
| tFlag | Optional flag for the policy engine. Default is that the policy is executed. If `tFlag="-I test"` then the migrate policy is not executed but tested. Useful for debugging. Default is `-I yes` | no | -I test |


After the parameters are defined, the migration script can be executed like this:

```
# mig-glacier.sh
```

The migration script essentially executes the [migration policy](migrate.pol) provided with this project. Some of the parameters defined in the migration script are directly passed to the migration policy. 

To automate migration of S3 Glacier objects to tape, the `mig-glacier.sh` script can be scheduled. Here is an example for scheduling migration using`cron` 4 times a day. The output of the script is logged in `/var/log/mig-glacier.log`:

```
0  0,6,12,18  *  *  * /usr/local/bin/mig-glacier.sh >> /var/log/mig-glacier.log 2>&1
```

If there are multiple buckets with S3 Glacier objects to be migrated, then consider to place all buckets in the same base path and set the base path parameter `s3Path` in the `mig-glacier.sh` script to this path. At the same time set the parameter `bucket=""`. 
If the buckets are not in the same base path, then create multiple versions of this script, adjust it to the required paths and bucket names and run it sequentially. 


The migration of Glacier objects that were identified by the migration policy is executed by all Storage Archive nodes, depending on the amount and size of objects to be migrated. If there are multiple Storage Archive nodes that should execute the migration policy, then install the scripts and policies on all Storage Archive nodes in the same path and set the parameter `nodes` in the `mig-glacier.sh` script accordingly. Running the policy distributed on multiple nodes may speed up the policy scan.



## Recall

After the S3 user issued `Restore-Object` requests to objects, these objects can be recalled using the [restore script](rest-glacier.sh). Usually the restore script is executed by a scheduler.

The restore script runs in two phases:

1. Objects requested for restore that are migrated are recalled from tape by leveraging the tape optimized recall function.
2. Objects that were recalled are marked for access by setting file attributes. 


The [restore script](rest-glacier.sh) has a section at the beginning where different parameters are defined. Here is an overview of the parameters that must be defined:

| Parameter | Description | Requires | Example |
|-----------|-------------|----------|---------|
| s3Path | Base path where buckets are stored. This is usually the `new-bucket-path` for S3 accounts. If there are multiple buckets, then consider to place all or a subset of buckets in the same base path (e.g., fileset).  | yes | /ibm/archfs/demo |
| fSet | Fileset name of the base path, if the base path is a fileset. If not leave this blank (""). | yes | demo |
| bucket | Name of the bucket to be process for recalls. If the name is blank `("")` then all objects stored in base path `s3Path` are considered for recall. This is appropriate if there there multiple buckets in the base path | yes  | glacier |
| scriptPath | Path where the script and policies of this project are stored | yes | /usr/local/bin |
| recallProc | Path and filename of the recall script `recall.sh` | yes | recall.sh |
| recPol | Path and filename of the recall policy file `recall.pol` | yes | recall.pol |
| setAttrProc | Path and filename of the set attribute script `setattr.sh` | yes | setattr.sh |
| setAttrPol | Path and filename of the set attribute policy file `setattr.pol` | yes | setattr.pol |
| nodes | Node names that execute the policy. When set to `""`, then it defaults to the local nodes. Multiple nodes are provide as `node1,node2`. When multiple nodes are specified, then the policies and scripts must be installed on all nodes in the same directory | no | node1 |

After the parameters are defined, the restore script can be executed like this:

```
# rest-glacier.sh
```

The restore script essentially executes the [recall policy](recall.pol) that recalls objects requested for restore. The recall policy identifies objects to be recalled and invokes the [recall script](recall.sh) to recall the objects in a tape optimized manner. Subsequently, the restore script executes the [set attributes policy](setattr.pol) that sets file attributes for recalled objects using the [set attributes script](setattr.sh). Some of the parameters defined in the restore script are directly passed to the recall and set attribute policies. 

To automate restore of S3 Glacier objects requested for restore, the `rest-glacier.sh` script can be scheduled. Here is an example for scheduling restore using`cron` 4 times a day. The output of the script is logged in `/var/log/rest-glacier.log`:

```
0  3,9,15,21  *  *  * /usr/local/bin/rest-glacier.sh >> /var/log/rest-glacier.log 2>&1
```

If there are multiple buckets with S3 Glacier objects to be restored, then consider to place all buckets in the same base path and set the base path parameter `s3Path` in the `rest-glacier.sh` script to this path. At the same time set the parameter `bucket=""`. 
If the buckets are not in the same base path, then create multiple versions of this script, adjust it to the required paths and bucket names and run it sequentially. 


The recall of Glacier objects that were identified by the recall policy is executed by all Storage Archive nodes, depending on the amount and size of objects to be recalled. If there are multiple Storage Archive nodes that should execute the recall policy, then install the scripts and policies on all Storage Archive nodes in the same path and set the parameter `nodes` in the `mig-glacier.sh` script accordingly. Running the policy distributed on multiple nodes may speed up the policy scan.


-------------------
END OF DOCUMENT
-------------------
