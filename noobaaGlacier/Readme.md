# Introduction

This project includes policies and scripts allowing to automatically manage migration and recalls of S3 GLACIER objects ingested through NooBaa endpoints in IBM Storage Scale file systems. 


## System environment

The systems applicable for the policies and scripts includes an IBM Storage Scale file system that is space managed by IBM Storage Archive Enterprise Edition. The open-source software NooBaa is installed on one or more IBM Storage Scale cluster nodes and provides the S3 object storage endpoints to the S3 users and applications. Objects and buckets ingested via the NooBaa S3 endpoints are stored as files and directories in the Storage Scale file system. 

NooBaa supports the AWS S3 and the AWS S3 Glacier API. 


## AWS S3 Glacier

AWS S3 Glacier provides additional API functions on top of the S3 API. The S3 Glacier API facilitates retrieval or restoration of objects from high latency media like tapes. Object stored in a Glacier storage class cannot be retrieved using normal S3 GET requests. Instead, the S3 user must first issue the Restore-Object request provided by the S3 Glacier API to request the recall from tape. After the object was recalled from tape, the user can use the normal S3 GET operations to retrieve the object. 

With the Restore-Object request, the S3 user can signal the retrieval of the object. The Restore-Object request allows to specify an expiration time period in days. After the recall, the object shall be retained on disk for the specified expiration time period. 

This means, a S3 Glacier object is not immediatelly accessible. Instead the user issues a Restore-Object request and waits for an agree time period. During this time period more Restore-Object requests can be accumulated and objects can be recalled from tape in an optimized manner. The time period the user must wait before he can access the object is defined as service level agreement (SLA). 

Here is an example of the Restore-Object command using the AWS CLI where a expiration time of 1 days is specified:

```
# aws s3api restore-object --bucket glacier1 --key coldile0 --restore-request '{"Days": 1}'
```


After issuing the Restore-Object command, the user can check if the object is available for access by using the Head-Object command. 

```
# aws s3api head-object --bucket glacier1 --key coldfile0
{
    "AcceptRanges": "bytes",
    "Restore": "ongoing-request=\"true\"",
    "LastModified": "Mon, 11 Mar 2024 14:30:28 GMT",
    "ContentLength": 6449152,
    "ETag": "\"mtime-czqzravhx5a8-ino-mxj\"",
    "ContentType": "application/octet-stream",
    "Metadata": {
        "storage_class": "GLACIER"
    },
    "StorageClass": "GLACIER"
}

```

The `Restore` parameter is set to `ongoing-request=true`, which means that the object is being retrieved from the high latency media. The object can still not be retrieved using the normal GET object request. Some magic needs to happen in the system, that is described in the next section.



## NooBaa and S3 Glacier

NooBaa leverages extended attributes of the files in the Storage Scale file system. When the S3 user stores an object in storage class GLACIER, then NooBaa sets an attribute `user.storage_class=GLACIER`. With this attribute an object is marked as Glacier object. 

When the user issues an Restore-Object request for an object, then NooBaa sets an attribute `user.noobaa.restore.request="1"` The value of `1` denotes the expiration time period of 1 day. This means after the recall the object is kept on disk for 1 day. The expireation time period can be any integer value. 

To make the object available for retrieval using a normal GET request, the attribute `user.noobaa.restore.expiry` must be set to a valid time stamp in the future and the attribute `user.noobaa.restore.request` must be deleted (or set to `false`). The time stamp encoded in attribute `user.noobaa.restore.expiry` represents the expiration date. If the expiration date has expired, then the object is no longer retrievable. The time stamp in attribute `user.noobaa.restore.expiry` is set in ISO format: `yyyy-mm-ddTHH:MM:SSZ`. Setting and deleting these attribute is not automated in NooBaa and must be triggered within the system. In this project we provide a policy along with an external script to accomplish this. 

For example, when the attribute `user.noobaa.restore.expiry` is set to a future date and the attribute `user.noobaa.restore.request` is deleted, then the user can GET the object. The Head-Object request shows that there is no ongoing restore-request and that the restore can be performed until the expiry date (parameter `Restore` is set to `ongoing-request=false, expiry-date=some-date-in-the future`

```
# s3u1api head-object --bucket glacier1 --key coldfile0
{
    "AcceptRanges": "bytes",
    "Restore": "ongoing-request=\"false\", expiry-date=\"Wed, 13 Mar 2024 00:00:00 GMT\"",
    "LastModified": "Mon, 11 Mar 2024 14:30:28 GMT",
    "ContentLength": 6449152,
    "ETag": "\"mtime-czqzravhx5a8-ino-mxj\"",
    "ContentType": "application/octet-stream",
    "Metadata": {
        "storage_class": "GLACIER"
    },
    "StorageClass": "GLACIER"
}

```

NooBaa represents the storage class and restore-request in extended attributes of the files associated with S3 Glacier objects. This enables automation of migration and recalls and facilitates tape optimized operations because multiple requests for recalls can be accumulated and executed as tape optimized recalls. 

The policies and script included in this project take care for migration, recalls and setting the NooBaa specific extended attributes. These policies and scripts can be simply automated and execute the S3 Glacier workflows unattended. 



# Policies and scripts

In this section the policies and scripts are explained that facilitate migration, recalls and attribute setting for Glacier objects.


## Workflow

The typical workflow for Glacier objects is the following

1. The S3 user issues a PUT request for an object with storage-class set to GLACIER into a bucket 
2. An automated process migrates objects with storage-class set to GLACIER to tape. This is the [Migration](#Migration) process.
3. The S3 user issues a Restore-Object request for an object. 
4. An automated process recalls objects that have a restore-request from tape. This is the [Recall](#Recall) process.
5. An automated process sets the attributes of objects that were recalled. This is the [Set attributes](#Set-attributes) process. 



## Migration

The migration of objects from the Storage Scale file system to tape is accommodated by the [migration policy](migrate.pol). This policy uses Storage Archive EE to perform the migration to tape. 

This migration policy migrates files matching the following conditions:
	storage_class attribute set to GLACIER AND 
	NOT migrated AND 
	( ( user.noobaa.restore.request is set AND user.noobaa.restore.expiry is NOT set) OR user.noobaa.restore.expiry is expired )

This policy migrates all files that were newly ingested with storage-class set to Glacier and also files where the date and time encoded in attribute `user.noobaa.restore.expiry` is expired. 


### Adjusting the migration policy

The [migration policy](migrate.pol) must be adjusted. The EXTERNAL POOL rule must reflect the tape pool(s) used as destination for the migration. Adjust the parameter `-p poolname` whereby `poolname` is the name of the tape pools. If Storage Archive is configured with multiple libraries, then the pool name must also include the library name (e.g., `-p poolname@libname`). When multiple copies must be created on different tape pools, then this parameter must include all pool names (e.g., `-p poolname1@libname1 poolname2@libname2`)

```
RULE 'extPool' EXTERNAL POOL 'ltfs' EXEC '/opt/ibm/ltfsee/bin/eeadm' OPTS '-p poolname'
```


The second adjustment must be done in the MIGRATE rule. If objects must be migrated from specific filesets, then these fileset name must be added to the FOR FILESET() clause. In the example below, the migration scope is limited to `fileset1`and `fileset2`. If the scope not limited to filesets and applies to the entire file system, then the FOR FILESET() clause can be removed. 

```
RULE 'migGlacier' MIGRATE FROM POOL 'system' TO POOL 'ltfs' FOR FILESET('fileset1' 'fileset1') WHERE
```


### Executing the migration policy

Once the migration policy was adjusted, it can be executed by the policy engine using the following command:

```
# mmapplypolicy [path-or-device] -P migrate.pol -m [threads] -N [archiveNodes] -B [bucket-size]--single-instance
```

The following parameters for the `mmapplypolicy` command must be considered:

- `path-or-device`	Path name of file system name. For example: `/ibm/fs1`
- `-m threads`		Number of parallel threads per node. This should be equivalent to the number of drives per node minus 1. 
- `-N nodes`			Names of the Storage Archive nodes. 
- `-B bucket-size`	Number of files to be migrated by one migrate operation. Depends on file size. A good value may be between 1000 and 20000.
- `--single-instance` Ensures that not more than one instance of this policy is executed at a time.  


The execution of the migration policy may be scheduled to run 1 - 2 times a day, depending on the requirements. 


## Recall

The recall of objects from tape is accommodated by the [recall policy](recall.pol) which is executed by the Storage Scale policy engine. The recall policy is an EXTERNAL LIST policy that invokes the external script [recallGlacier.sh](recallGlacier.sh) to accommodate the recall of the selected files. 

The [recall policy](recall.pol) selects all files matching the following conditions:
	storage_class attribute set to GLACIER AND 
	migrated AND 
	user.noobaa.restore.request is set

File names that are selected by the recall policy are packed in file list and passed on to the [recall script](recallGlacier.sh). This script performs the tape optimized recall of all files in the list by executing the Storage Archive `eeadm recall filelist` command. 


### Adjusting the recall policy and script

The [recall policy](recall.pol) must be adjusted. The EXTERNAL LIST rule must point to the exact path and file name where the [recall script](recallGlacier.sh) is located. In the example below the external script path and name is `/usr/local/bin/recallGlacier.sh`. 

```
RULE 'extlist' EXTERNAL LIST 'recall' EXEC '/usr/local/bin/recallGlacier.sh'
```

The second adjustment must be done in the LIST rule. If objects must be recalled from specific filesets, then these fileset name must be added to the FOR FILESET() clause. In the example below, the recall scope is limited to `fileset1`and `fileset2`. If the scope is not limited to  filesets and applies to the entire file system, then the FOR FILESET() clause can be removed. 

```
RULE 'listRec' LIST 'recall' FOR FILESET('fileset1' 'fileset1') WHERE
```


In the [recall script](recallGlacier.sh), the variable `MYPATH` must be set to a valid path. The script will write the log file into this path. The path must be valid for each Storage Archive node. In the following example the log file path is set to `/var/log/glacier/recall`:

```
# define paths for log files and output files
MYPATH="/var/log/glacier/recall"
```


### Executing the recall policy and script

Once the recall policy and script was adjusted, it can be executed by the policy engine using the following command:

```
# mmapplypolicy [path-or-device] -P recall.pol -m [threads] -N [archiveNodes] -B [bucket-size] --single-instance
```

The following parameters for the `mmapplypolicy` command must be considered:

- `path-or-device`	Path name of file system name. For example: `/ibm/fs1`
- `-m threads`		Number of parallel threads per node. This should be equivalent to the number of drives per node minus 1. 
- `-N nodes`			Names of the Storage Archive nodes. 
- `-B bucket-size`	Number of files to be migrated by one migrate operation. Depends on file size. A good value may be between 1000 and 20000. 
- `--single-instance` Ensures that not more than one instance of this policy is executed at a time.  


The schedule for the execution of the recall policy depends on the service level specifying the time period a S3 user must wait for the object to be retrievable after the user issued the Restore-Object request. Depending of the number of files in the file system and filesets, realistic time periods for retrieval may be 4 - 8 hours. If the time period for the retrieval is 4 hours, than the recall policy should be executed every 3 hours to give it some lead time for recalls. 


Note, that the [recall script](recallGlacier.sh) appends the output into a log file (recall.log) that is stored in path specified by `MYPATH`. Consider implementing log rotation to prevent the file system to be filled up. 



## Set Attributes

Setting the user.noobaa attributes is accommodated by the [set-attributes policy](setexpire.pol) that is executed by the Storage Scale policy engine. The set-attribute policy is an EXTERNAL LIST policy that invokes the external script [setExpire.sh](setExpire.sh) to accommodate setting the attributes of the selected files. 

The [set-attributes policy](setExpire.pol) selects all files matching the following conditions:
	storage_class attribute set to GLACIER AND 
	NOT migrated AND 
	user.noobaa.restore.request is set

File names that are selected by the set-attributes policy are packed in file list and passed on to the [set-attributes script](setExpire.sh). For each file in the file list, the set-attributes script performs the following steps:
- Calculates expiry-date based on current time plus the time period in days encoded in the attribute user.noobaa.restore.request
- Set the attribute user.noobaa.restore.expiry to the value of the calculated expiry-date
- Remove the attribute user.noobaa.restore.request


To assure that recalled files (objects) are retrievable by the S3 user, **the set-attributes policy must be executed right after the recall**. This is because the recall is initiated for files that are migrated and have the attribute user.noobaa.restore.request set. After the recall, the files become retrievable as object via the S3 API when the attribute user.noobaa.restore.request is not present (or set to `false`) and then the date and time stamp encoded in attribute user.noobaa.restore.expire is in the future. This is taken care by the set-attributes policy and the set-attributes script. 


### Adjusting the set-attribute policy and script

The [set-attribute policy](recall.pol) must be adjusted. The EXTERNAL LIST rule must point to the exact path and file name of the[set-attributes script](setExpire.sh). In the example below the external script path and name is `/usr/local/bin/setExpire.sh`. 

```
RULE 'extlist' EXTERNAL LIST 'setExpiry' EXEC '/usr/local/bin/setExpire.sh'
```

The second adjustment must be done in the LIST rule. If objects must be processed from specific filesets, then these fileset names must be added to the FOR FILESET() clause. In the example below the processing scope is limited to `fileset1`and `fileset2`. If the processing scope is not limited to fileset and applies to the entire file system, then the FOR FILESET() clause can be removed. 

```
RULE 'listFiles' LIST 'setExpiry' FOR FILESET('fileset1' 'fileset1') WHERE
```


In the [set-attributes script](setExpire.sh), the variable `MYPATH` must be set to a valid path. The script will write the log file into this path. The path must be valid for each Storage Archive node. In the following example the log file path is set to `/var/log/glacier/setexpire`:

```
# define paths for log files and output files
MYPATH="/var/log/glacier/setexpire"
```


### Executing the set-attribute policy and script

Once the set-attributes policy and script was adjusted, it can be executed by the policy engine using the following command:

```
# mmapplypolicy [path-or-device] -P setexpire.pol -m [threads] -N [Nodes] -B [bucket-size] --single-instance
```

The following parameters for the `mmapplypolicy` command must be considered:

- `path-or-device`	Path name of file system name. For example: `/ibm/fs1`
- `-m threads`		Number of parallel threads per node. This should be equivalent to the number of drives per node minus 1. 
- `-N nodes`			Names of nodes that execute the policy and the script. This is **not** limited the Storage Archive nodes. 
- `-B bucket-size`	Number of files to be migrated by one migrate operation. Depends on file size. A good value may be between 1000 and 20000. 
- `--single-instance` Ensures that not more than one instance of this policy is executed at a time.  


The schedule for the execution of the set-attribute policy depends on the schedule of the recall policy. The set-attribute policy must be executed right after the recall to assure that files get the right attributes set and can be retrieved by the S3 user. 

Note, that the [set-attribute script](setExpire.sh) appends the output into a log file (setexpire.log) that is stored in path specified by `MYPATH`. Consider implementing log rotation to prevent the file system to be filled up. 

