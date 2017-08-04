## Description

This script is a callback script that is triggered by the event softQuotaExceeded. It invokes a list policy to select files in the fileset that qualify for migration based on the quota limits and a migration policy that migrates the files identified by the list policy. Because the event softQuotaExceeded is triggered on the file system manager node it must be installed on all nodes with manager roles. If not all of these nodes are running the migration software (Spectrum Archive or TSM HSM) a node class can be created including all nodes running the migration software as. This node class can be defined in the script and it will select a node from this node class that is active and has the file system mounted. The local node is preferred when it is member of the node class. 


## Prerequisites

The script uses two policies that must be installed on all nodes running the migration software in the path specified by $workDir. If there is a subset of nodes that has the migration software installed then create a node class with these nodes as member and define the node class in the script ($nodeClass).

1. LIST policy:
Selects (lists) files if a fileset soft quota limit exceeds a certain threshold. The file list is stored in a output  file. In the example below it will essentially set fileset soft quota as a parameter to be checked against the threshold. If the high threshold (100% of soft quota limit) is met, then it selects files until the low limit (70% of the soft quota limit) is met.

       /* define macros */
       define(is_empty, (KB_ALLOCATED=0))
       define(access_age,(DAYS(CURRENT_TIMESTAMP) - DAYS(ACCESS_TIME)))
  
       /* check softquota against threshold and select files */
       RULE EXTERNAL LIST 'softquota' THRESHOLD 'FILESET_QUOTA_SOFT'
       RULE 'fsetquota' LIST 'softquota' THRESHOLD(100,70) WEIGHT(access_age) FOR FILESET ('FSETNAME') WHERE NOT (is_empty)

The result file is stored under the name $outfile.list.softquota. 

2. MIGRATE policy
Matches all files selected by the list policy against the migration rule and migrates the candidates. The migration policy should have the EXCLUDE rules and other than this just migrate everything which is NOT (is_empty). The example below migrates from system pool to TSM:

       /* define macros */
       define(is_empty,(KB_ALLOCATED=0))
       define(access_age,(DAYS(CURRENT_TIMESTAMP) - DAYS(ACCESS_TIME)))

       /* define exlude rule */
       RULE 'exclude' EXCLUDE WHERE ( PATH_NAME LIKE '%/.SpaceMan/%' OR PATH_NAME LIKE '%/.snapshots/%' OR NAME LIKE '%mmbackup%' OR NAME LIKE '%quota%' )

       /* define migration to HSM pool */
       RULE 'hsmexternalpool' EXTERNAL POOL 'hsm' EXEC '/var/mmfs/etc/mmpolicyExec-hsm' OPTS '-v'
       RULE 'quotaMig' MIGRATE FROM POOL 'system' WEIGHT(access_age) TO POOL 'hsm' FOR FILESET ('FSETNAME') WHERE NOT (is_empty)

This will migrate all or a subset of files of the input list file. 

## Invocation

This script is invoked by a callback, which is defined in the following way:

     # mmaddcallback SOFTQUOTA-MIGRATION --command $workDir/callback-quota.sh --event softQuotaExceeded --parms "%eventName %fsName %filesetName"

Syntax: callback-quota eventName fsName fsetName

- eventName 	should be the GPFS event softQuotaExceeded
- fsName 		file system name 
- fsetname 		fileset name

The callback script must be installed on all manager nodes in path $workDir. 


## Processing

- check if parameters are correct
- select the node to run the policy based on a node class defined in the script. If there is no node class defined it runs on the local node. If the local node is member of the node class it prefers the local node
- check if the node and file system state of the selected node is active, if not it checks another node from the node class
- run the list policy and create list of selected files based on quota consumption
- convert the resulting list file as input for the migration policy
- run the migrate policy using the file list


## Output

STDIN and STDERR are written to log file ($logF)

Return codes:

  0: Good
  
  1: Error


## Note:

- The callback is configured cluster wide for all nodes.
- The callback script must be installed on all manager nodes because the event is triggered on the file system manager only. 
- The policies must be installed on all nodes that can perform the migration under the path specified by $workDir
- The event "softQuotaExceeded" is only triggered once per fileset when the condition is met. It expects the space consumption to decrease under the quota limits. If this is the case and after a while the quota limit is reached again then this event is triggered again. Otherwise, if the space consumption does not decrease then the event might not be triggered again. Therefore it is important to make sure that the callback script works 100 % and that it alerts the admin if not. 
- In order to retrigger the event the softquota limits can be increased or files can be move out and back in again. Some delay between moving files out of the files and in should be planned (5 - 10 min).  
- Consider placing the temporary file generated by mmapplypolicy in a directory with sufficient space. Use the parameter -s with the mmapplypolicy command for this. 

