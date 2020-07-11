
Copyright 2019 Nils Haustein, released under the [MIT license](LICENSE)

This project includes scripts and policies for the Spectrum ILM:

## Folder [immutable](immutable/) - Script to set files to immutable

This folder contains a script and policies to identify files that are not immutable in an immutable fileset and sets these identified files to immutable. The `makeimmutable.sh` script is an external pool script that receives the input from an EXTERNAL LIST policy and sets all files identified by the LIST policy to immutable using the `mmchattr -i yes` command. The retention period is defined in the policy itself and is applied to each file by setting the retention time to current date and time plus retention period

------------------------

## Folder [list](list/) - List policy script

This folder contains a wrapper script for LIST policies. The main purpose is to list the numbers and optionally the file names of file in accordance to their migration state. This wrapper script can be dynamically extended to use other list policies. 

------------------------

## Folder [premigrate](/premigrate) - Premigrate policies and scripts

This folder contains script and policies to perform premigrates using migrate policies. It provides an interface script that wraps perform pre-migration instead of migration. It contains an interface script for Spectrum Archive.  

------------------------

## Folder [quota-migration](/quota-migration) - Automated migration based on Quota 

This folder contains a callback script and policies facilitating migration of a fileset to be triggered when the quota consumption reaches a certain threshold. The callback script (`callback-quota.sh`) is invoked when the event `softQuotaExceeded` is triggered. This script invokes an EXTERNAL LIST policy to list files in the fileset that qualify for migration based on the quota limits and a migration policy that migrates the files identified by the list policy. 

------------------------

## Folder [Recall](recall/)

This folder contains script and policies for tape optimized recalls with Spectrum Protect for Space Management and Spectrum Archive Enterprise Edition . The scripts are customized interface scripts that perform recall instead of migration. 

------------------------

## Folder [receiver](receiver/) - external script invoked by EXTERNAL LIST policy

This folder includes an interface script that receives file lists from an EXTERNAL LIST policies and processes the files contained in the file list. The processing in this script extracts the file names contained in the file list and writes these file names to an extra file. Of course you can add other operations for the files. 

------------------------

## Folder [runpolicy](runpolicy/) - wrapper for mmapplypolicy

This folder contains a wrapper script for the `mmapplypolicy` command. It is invoked in a simplified way and allows either pass further options for the `mmapplypolicy` commmand or encode these options in an internal variable. 

------------------------

## Folder [sample-policies](sample-policies/) - sample ILM policies

This folder includes sample policies for migration, recall and list. 


