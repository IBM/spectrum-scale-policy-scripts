
Copyright 2026 Nils Haustein, released under [Apache License 2.0](LICENSE)

This repository includes scripts and policies for IBM Storage Scale ILM in combination with IBM Storage Archive Enterprise Edition and IBM Storage Protect for Space Management. For more inforemation refer to the [IBM Storage Scale ILM policy Redbook](https://www.redbooks.ibm.com/abstracts/redp5739.html). 

-----------------------

## Folder [immutable](immutable/) - Script to set files to immutable

This folder contains a script and policies to identify files that are not immutable in an immutable fileset and sets these identified files to immutable. The `makeimmutable.sh` script is an external pool script that receives the input from an EXTERNAL LIST policy and sets all files identified by the LIST policy to immutable using the `mmchattr -i yes` command. The retention period is defined in the policy itself and is applied to each file by setting the retention time to current date and time plus retention period

------------------------

## Folder [list](list/) - List policy script

This folder contains a wrapper script for LIST policies. The main purpose is to list the numbers and optionally the file names of file in accordance to their migration state. This wrapper script can be dynamically extended to use other list policies. 

------------------------

## Folder [noobaaGlacier](noobaaGlacier/) - policies and scripts for NooBaa Glacier

This folder contains policies and scripts allowing to automatically manage migration and recalls of S3 GLACIER objects ingested through NooBaa endpoints in IBM Storage Scale file systems. 

The policies and scripts in this folder are associated with the series of blog article [Noobaa on Scale](https://community.ibm.com/community/user/storage/blogs/nils-haustein1/2024/02/21/s3-tiering-to-tape-with-noobaa-part-1-introduction)

For policies and scripts managing S3 GLACIER with Storage Scale S3 service refer to folder [Storage Scale S3 Glacier automation](s3-glacier-automation/).

------------------------

## Folder [premigrate](/premigrate) - Premigrate policies and scripts

This folder contains script and policies to perform premigrates using migrate policies. It provides an interface script that wraps perform pre-migration instead of migration. It contains an interface script for Storage Archive.  

------------------------

## Folder [quota-migration](/quota-migration) - migration when quota limits have reached 

This folder contains a callback script and policies facilitating migration of files for filesets where the soft quota limit has been reached. The callback script (`callback-quota.sh`) is invoked when the event `softQuotaExceeded` is triggered for a fileset. This script invokes an EXTERNAL LIST policy to identify files in the fileset that qualify for migration based on the quota limits and a migration policy that migrates the files identified by the list policy to IBM Storage Archive EE. 

------------------------

## Folder [Recall](recall/) - wrapper script for tape optimized recalls

This folder contains script and policies for tape optimized recalls with Storage Protect for Space Management and Storage Archive Enterprise Edition . The scripts are customized interface scripts that perform recall instead of migration. 

------------------------

## Folder [receiver](receiver/) - external script invoked by EXTERNAL LIST policy

This folder includes an interface script that receives file lists from an EXTERNAL LIST policies and processes the files contained in the file list. The processing in this script extracts the file names contained in the file list and writes these file names to an extra file. Of course you can add other operations for the files. 

------------------------

## Folder [runpolicy](runpolicy/) - wrapper for mmapplypolicy

This folder contains a wrapper script for the `mmapplypolicy` command. It is invoked in a simplified way and allows either pass further options for the `mmapplypolicy` commmand or encode these options in an internal variable. 

------------------------

## Folder [s3-glacier-automation](s3-glacier-automation/) - S3 Glacier migration and restore 

This folder includes scripts and associated policy files for managing migration and restore of S3 Glacier objects in IBM Storage Scale S3 service. 

------------------------

## Folder [sample-policies](sample-policies/) - sample ILM policies

This folder includes sample policies for migration, recall and list. 


----------------------
END OF DOCUMENT
----------------------

