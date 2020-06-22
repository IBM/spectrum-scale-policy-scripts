# Introduction: 

This script can be used in combination with the policy engine and a proper LIST policy to automatically set files to immutable with a defined retention period. The retention time for each files is set to current date and time plus retention period defined in the policy. It is an interface script for LIST policy invoked by mmapplypolicy. 


## Prerequisite:

The makeimmutable.sh script needs to be installed on one or more Spectrum Scale nodes in a the same directory. The directory where this program is installed is referenced in the EXTERNAL list rule. 

## Example Policy:

This example policy will identify all files ending with `.mp3` and `.pdf` in the immutable fileset `worm`that are not set to immutable and invoke the external script /root/silo/makeimmutable.sh. This external script sets the specified retention period to the selected files and make these files immutable. The external script is installed in directory: `root/silo/makeimmutable.sh` on all nodes that participate in this operation. 

The following rules show how to set all files ending with `.mp3` to 1 day retention (`OPTS '1'`):

	/* define exclude list */
	define(  exclude_list,
	  (PATH_NAME LIKE '%/.SpaceMan/%' OR
	   PATH_NAME LIKE '%/.ltfsee/%' OR
	   PATH_NAME LIKE '%/.mmSharedTmpDir/%' OR
	   PATH_NAME LIKE '%/.snapshots/%' OR
	   NAME LIKE '.mmbackupShadow%' OR
	   NAME LIKE 'mmbackup%')
	   
	/* define immutable attribute */
	define( immutable, MISC_ATTRIBUTES LIKE '%X%')

	/* define external list with makeimmutable.sh script to set mp3 files in fileset 'worm' to immutable with 1 day retention */
	RULE EXTERNAL LIST 'setmp3' EXEC '/root/silo/makeimmutable.sh' OPTS '1'
	RULE 'mp3' LIST 'setmp3' FOR FILESET ('worm') WHERE NOT (exclude_list) and NOT (immutable) and (NAME LIKE '%.mp3')


In the same policy there can be additional EXTERNAL LIST rules which set other types of files to immutable with different retention period. For example the rules below set 2 days retention times for files ending with `.pdf` (`OPTS '2'`). Add this set of rules to the policy above when needed: 

	/* define external list with makeimmutable.sh script to set pdf files in fileset 'worm' to immutable with 1 day retention */
	RULE EXTERNAL LIST 'setpdf' EXEC '/root/silo/makeimmutable.sh' OPTS '2'
	RULE 'pdf' LIST 'setpdf' FOR FILESET ('worm') WHERE NOT (exclude_list) and NOT (immutable) and (NAME LIKE '%.pdf')


An example of this policy can be found in [makeimmutablelistpolicy.txt](makeimmutablelistpolicy.txt). 


## Invokation:

To execute the policy use the mmapplypolicy command. This will invoke the external script with file lists including the filenames of the files that have been identied. Here is an example, some parameters have to be changed:

    mmapplypolicy fsname -P policyfile -N nodename -B 1000 -m 1 -s localworkdir -g globalworkdir --single-instance [-I test]


The parameters of the command are the following:

fsname is the name of the file system or a fully qualified path of a fileset or directory

-P policyfile is the file including the rules for this policy. An example can be found in [makeimmutablelistpolicy.txt](makeimmutablelistpolicy.txt)

-N specifies a one or more Spectrum Scale node name where the makeimmutable.sh script is installed.

-m specifies the number of concurrent external script instances to be launched per node. In the example above it is set to one which means that there is one instance running

-B specifies the number of file names in one file list. In this case it would be 1000 files per file list. 

-s specifies a local directory used to store temporary files created by the policy engine. There must be sufficient space in this directory. The default directory is /tmp.

-g specifies a directory that is accessible be all cluster nodes. It can be in the file system that is processed by the policy engine or it can be in a different file system. The default is specified by the Spectrum Scale configuration parameter `sharedTmpDir`. 

--single-instance specifies that only one instance of the policy engine can run. If another instance is already running then this command will abort

-I test means that the policy is tested for syntax. No -I means that the policy performs file selection and executes script. 



## Processing:

With the proper policy this script is invoked by mmapplypolicy with the following parameters:
  $1 operation (list, test)
  $2 file system name or name of filelist
  $3 optional parameter defined in LIST policy under OPTS, defines retention period in days relative to current date

The script implements the TEST and LIST operation. 
Upon TEST it tests if the file system name given with $2 exists and exits with 0.
Upon LIST it parses the filelist passed with the parameter $2, extracts the file names and sets the retention period to current-date plus retention-time. The retention-time is passed with the parameter $3 and encoded in the policy. 

## Output:

Sets files identified to immutable with retention period define in policy relative to current date and time (default is defined as $DEFRETTIME). 
Write runtime information and debugging messages to log file specified with the parameter `$LOGFILE` in the makeimmutable.sh script. 

## Supplemental List Policy

It may be worth to periodically check if all files have been set to immutable. The supplemental list policy [list-immutable.txt](list-immutable.txt) can be used for this.

To run this policy use the `mmapplypolicy` command:
	mmapplypolicy fsname -P policy -f ./my -I defer

The resulting file list is stored in file `my.list.immut`
