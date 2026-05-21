# IBM Storage Scale S3 Glacier tiering to tape using IBM Storage Archive

------------------------------------------

# Introduction

This project includes automation scripts and IBM Storage Scale policies to manage migration and restores of S3 GLACIER objects ingested through the Storage Scale S3 service in IBM Storage Scale file systems that is managed by IBM Storage Archive Enterprise Edition. 


**Note:** Storage Scale S3 service does not (yet) support S3 Glacier. As an alternative the open-source project [NooBaa](https://github.com/noobaa/noobaa-core/) can be used to provide the S3 service on top of an IBM Storage Scale file system. The scripts and policies in this project work with open-source Noobaa as well. 


Foundational information for managing migration and restores for S3 Glacier objects are provided in the [noobaaGlacier project](../noobaaGlacier). This project provides scripts and associated ILM policies that allow managing migration and restores out-of-the-box.

This project is released under [Apache License 2.0](../LICENSE)


## System environment

The scripts and policies of this project require a IBM Storage Scale cluster with S3 service enabled (CES S3) and IBM Storage Archive EE to manage the space in the file system. Objects and buckets created via the Storage Scale S3 service are stored as files and directories in the Storage Scale file system. 

The scripts and policies in this project allow migration and restores for S3 Glacier objects. S3 Glacier provides additional API functions on top of the S3 API. The S3 Glacier API facilitates retrieval or restoration of objects from high latency media like tapes. Object stored in a S3 Glacier storage class cannot be immediatelly retrieved using normal S3 GET requests. Instead, the S3 user must first issue the `restore-rbject` request provided by the S3 Glacier API to request the recall from tape. After the object was recalled from tape, the user can use the normal S3 GET request to retrieve the object. 


# Installation

The following files are included in this projects:

| File name | Description |
|-----------|-------------|
| Readme.md | This readme file with comprehensive instructions for installation, configuration and usage |
| mig-glacier.sh  | Script to migrate S3 glacier objects |
| migrate.pol  | Migrate policy executed by `mig-glacier.sh` |
| rest-glacier.sh | Script to restore S3 Glacier objects | 
| recall.pol | External List policy executed by `rest-glacier.sh` that recalls objects using the interface script `recall.sh`. |
| recall.sh | Interface script invoked by the recall policy `recall.pol` in `rest-glacier.sh` |
| setattr.pol | External List policy executed by `rest-glacier.sh`  that sets attributes for recalled objects using the interface script `setattr.sh` |
| setattr.sh | Interface script invoked by the set attribute policy `setattr.pol` in `rest-glacier.sh`  |
| funcs-glacier.sh | Script defining global parameters and functions for the scripts `mig-glacier.sh` and `rest-glacier.sh` |


The scripts and policies included in this project must be installed on at least one Storage Archive nodes. If there is more than one Storage Archive nodes in the cluster, then all Storage Archive could be used to execute the policies. In this case install the scripts and policies on all Storage Archive nodes in the same path (e.g., `/usr/local/bin`)

Clone the repository:

```
# cd /tmp
# git clone git@github.com:IBM/spectrum-scale-policy-scripts
```

Change to this project's directory:

```
# cd spectrum-scale-policy-scripts/s3-glacier-automation
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


## Enable S3 Glacier

To enable S3 Glacier in Storage Scale S3 server perform the following command as adminstrative user. This command will restart the S3 service:

```
# mms3 config change NSFS_GLACIER_ENABLED=true
```

**Note:** The S3 Glacier function is not officially supported. Refer to this IDEA for more information [Allow S3 Glacier in Storage Scale](https://ideas.ibm.com/ideas/SPA-I-38/)



## Adjust configuration parameters

Configuration parameters used by the `mig-glacier.sh` and `rest-glacier.sh` are globally defined in file `funcs-glacier.sh`. Some configuration parameters must be adjusted, especially those that define the scope for S3 Glacier migration and restore (e.g., file system, fileset or bucket), the node names for executing the policies and the tape pools used. Find below a description of the configuration parameters subject for adjustments:


| Parameter | Description | Required | Example |
|-----------|-------------|----------|---------|
| s3Path | Defines the base path where the buckets are located. | Yes | /ibm/archfs/buckets |
| fSet | Defines the name of the fileset. This parameter is only required, if `s3Path` is the path of a fileset. In this case this parameter must be set to the fileset name. | Only if `s3Path` is a fileset path | buckets | 
| bucket | Defines the name of the bucket. This parameter is only required if objects from a specific bucket must be processed. If multiple buckets under `s3Path` must be processed, then this parameter can be blank. | Only if a specific bucket must be processed | glacier | 
| tapePool | Defines the name of the Storage Archive EE tape pool used as target for migration. The syntax is `pool@library`. If two copies must be created, then two pools can be specified here (for example: `pool1@lib1 pool2@lib2`) | yes | pool1@lib1 |
| nodes | Defines the node names that execute migration and restore. These nodes must be Storage Archive EE nodes. When this parameter is left blank, then the local node where the scripts are executed is used. This parameter can specify multiple node names separated with comma and no blank (e.g., `node1,node2`). This parameter can also specify a node class (e.g., `all`). | Yes | node1 |
| tFlag | Defines the action the policy engine performs on files. When set to blank, then identified files are processed (migrated, recalled or attributes set). When set to `-I test`, then files are identified and no action is performed on files. | Only when identified files must not be processed  | `-I test` (test mode) |


To adjust configuration parameters open the file `funcs-glacier.sh`.

Here is an example whereby the base path for S3 Glacier objects is `/ibm/archfs/buckets` the fileset name for this path is `buckets`. Underneath the path `/ibm/archfs/buckets` there are multiple buckets that must be processed. The tape pool is `pool1@lib1` and the nodes are `eenode1` and `eenode2`. The configuration parameters for this example are shown below:


| Parameter | Value |
|-----------|-------|
| s3Path | /ibm/archfs/buckets |
| fSet | buckets |
| bucket| "" |
| tapePool | pool1@lib1 |
| nodes | eenode1,eenode2 |
|tFlag | "" |

The parameter bucket is left blank because there are multiple buckets under `s3Path` that must be processed. 


Note, there are further configuration parameters defined in the script `funcs-glacier.sh` that are used for internal program controls. For Storage Scale policy engine experts, the parameter `migPolOpts`, `recPolOpts` and `setAttrPolOpts` provide additional parameter when executing the policy engine for the purposes of migration, recall and set-attributes. 



# Workflows

The typical workflow for Glacier objects is the following

1. The S3 user issues a PUT request for an object with storage-class set to GLACIER into a bucket. Example with the AWS CLI:

   ```
   # aws s3api put-object --bucket glacier --body coldfile0 --key coldfile0 --storage-class GLACIER
   ```


2. New S3 Glacier objects are migrated to tape by the [Migration](#Migration) process.  The migration script `mig-glacier.sh` is started by a scheduler and executes a migration policy. The command to start migration manually is:

   ```
   # mig-glacier.sh
   ``` 


3. The S3 user issues a `Restore-Object` request for an object. Example with the AWS CLI:

   ```
   # aws s3api restore-object --bucket glacier --key coldfile0 --restore-request '{"Days": 1}'
   ```
   
4. Objects requested for restore are restored by the [Restore](#Restore) process. The restore script `rest-glacier.sh` is started by a scheduler. It runs in two phases: (1) objects requested for restore are recalled from tape by leveraging a ILM policy. (2) recalled objects are marked for access by setting file attributes. The command to start restore manually is:

   ```
   # rest-glacier.sh
   ``` 


5. The S3 user can now retrieve the object using a normal GET request

   ```
   # aws s3api get-object --bucket glacier --key coldfile0 coldfile0
   ```


The migration and recall processes are implemented in scripts and policies and are further explained below. 


## Migration

After object are created for storage class GLACIER in the buckets, the [migration script](mig-glacier.sh) can be executed. Usually the migration script is executed by a scheduler.

The configuration parameters used by the script are defined in script `funcs-glacier.sh` (see section [Adjust configuration parameters](#Adjust-configuration-parameters))

The migration script can be executed like this:

```
# mig-glacier.sh
```


The migration script essentially executes the [migration policy](migrate.pol) provided with this project. Some of the parameters defined in the migration script are directly passed to the migration policy. 


To automate migration of S3 Glacier objects to tape, the `mig-glacier.sh` script can be scheduled. Here is an example for scheduling migration using`cron` 4 times a day. The output of the script is logged in `/var/log/mig-glacier.log`:

```
0  0,6,12,18  *  *  * /usr/local/bin/mig-glacier.sh >> /var/log/mig-glacier.log 2>&1
```


If there are multiple buckets with S3 Glacier objects to be migrated, then consider to place all buckets in the same base path and set the base path parameter `s3Path` in the `funcs-glacier.sh` script to this path. At the same time set the parameter `bucket=""`. 
If the buckets are not in the same base path, then create multiple copies of this script in different paths, adjust it to the required paths and bucket names and run it sequentially. 


The migration of Glacier objects that were identified by the migration policy is executed by all Storage Archive nodes. If there are multiple Storage Archive nodes that should execute the migration policy, then install the scripts and policies on all Storage Archive nodes in the same path and set the parameter `nodes` in the `funcs-glacier.sh` script accordingly. Running the policy on multiple nodes may speed up the policy scan and file processing.



## Recall

After the S3 user issued `restore-object` requests to objects, these objects can be recalled using the [restore script](rest-glacier.sh). Usually the restore script is executed by a scheduler.

The restore script runs in two phases:

1. Objects requested for restore that are migrated are recalled from tape by leveraging the tape optimized recall function.
2. Objects that were recalled are marked for access by setting file attributes. 


The configuration parameters used by the script are defined in script `funcs-glacier.sh` (see section [Adjust configuration parameters](#Adjust-configuration-parameters))

The restore script can be executed like this:

```
# rest-glacier.sh
```

The restore script executes the [recall policy](recall.pol) that recalls objects requested for restore. The recall policy identifies objects to be recalled and invokes the [recall script](recall.sh) to recall the objects in a tape optimized manner. 

Subsequently, the restore script executes the [set attributes policy](setattr.pol) that sets file attributes for recalled objects using the [set attributes script](setattr.sh). Some of the parameters defined in the restore script are directly passed to the recall and set attribute policies. 


To automate restore of S3 Glacier objects requested for restore, the `rest-glacier.sh` script can be scheduled. Here is an example for scheduling restore using`cron` 4 times a day. The output of the script is logged in `/var/log/rest-glacier.log`:

```
0  3,9,15,21  *  *  * /usr/local/bin/rest-glacier.sh >> /var/log/rest-glacier.log 2>&1
```


If there are multiple buckets with S3 Glacier objects to be restored, then consider to place all buckets in the same base path and set the base path parameter `s3Path` in the `funcs-glacier.sh` script to this path. At the same time set the parameter `bucket=""`.
 
If the buckets are not in the same base path, then create multiple copies of this script, adjust it to the required paths and bucket names and run it sequentially. 


The recall of Glacier objects that were identified by the recall policy is executed by all Storage Archive nodes. If there are multiple Storage Archive nodes that should execute the recall policy, then install the scripts and policies on all Storage Archive nodes in the same path and set the parameter `nodes` in the `funcs-glacier.sh` script accordingly. Running the policy on multiple nodes may speed up the policy scan and file processing.


-------------------
END OF DOCUMENT
-------------------
