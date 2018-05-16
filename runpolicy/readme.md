## Purpose:
runpolicy is a wrapper for mmapplypolicy that runs a policy provided as input file for a file system and directory provided as input. It also passes arguments to the policy itself such as the FILESYSTEM and EEPOOL

## Syntax:

        runpolicy mode [filesystem] [policyfile] [pool]
                mode      : test|run, mandatory parameter
                filesystem: GPFS file system and directory subject for the policy run
                policyfile: name of the file including the policy
                pool:       name of the tape storage pool(s), multiple enclosed in quotes


### Arguments passed to policy engine:
The parameters filesystem (given as input) and pools (given as input) are passed to the policy as parameters:
FILESYSTEM and EEPOOL. 

For example - Migration policy based on size

With the command: 

        runpolicy run /ibm/gpfs policyfile.txt "mypool@lib0"

The parameter FILESYSTEM is set to /ibm/gpfs and the parameter EEPOOL to mypool@lib0 when the policyfile.txt is executed

        RULE EXTERNAL POOL 'ltfs2'
        EXEC '/opt/ibm/ltfsee/bin/ltfsee' /* full path to ltfsee command must be specified */  
        OPTS 'EEPOOL' /* this is our pool in LTFS EE which is given by the runpolicy script*/

        /* here comes the migration rule whereby the FILESYSTEM is given by the runpolicy script*/
        RULE 'ee-sizemig' MIGRATE FROM POOL 'system' TO POOL 'ltfs2' WHERE
        (
          (
          PATH_NAME LIKE 'FILESYSTEM'
          AND (KB_ALLOCATED > 1024 )
          AND NOT (exclude_list)
          )
        )

This policy will migrate files from the system pool of file system /ibm/gpfs to the mypool@lib0 which is larger than 1 MiB. 


### Defaults
Defaults are defined in the runpolicy.sh file on top:

        DEFAULT_FSDIR="/mnt/userfs/" : default GPFS file system for the policy, can be overwritten by the filesystem parameter
        DEFAULT_PFILE="./policyfile" : default policy file can be overwritten by the policyfile parameter
        DEFAULT_EEPOOL="mzpool"      : LTFS EE pool, can also be two or three pools (mzpool1 mzpool2)


### Notes:
In the policy you may have to adjust the GPFS file system pool in the FROM POOL statement, currently set to system.

## Example Premigration policy:

Uses the THRESHOLD token with %high,%low,%premig whereby:

HighPercentage: Indicates that the rule is to be applied only if the occupancy percentage of the current pool of the file is greater than or equal to the HighPercentage value. Specify a nonnegative integer in the range 0 to 100.

LowPercentage: Indicates that MIGRATE rules are to be applied until the occupancy percentage of the current pool of the file is reduced to less than or equal to the LowPercentage value. Specify a nonnegative integer in the range 0 to 100. The default is 0%.

PremigratePercentage: Defines an occupancy percentage of a storage pool that is below the lower limit. Files that lie between the lower limit LowPercentage and the pre-migrate limit PremigratePercentage will be copied and become dual-resident in both the internal GPFS storage pool and the designated external storage pool. This option allows the system to free up space quickly by simply deleting pre-migrated files if the pool becomes full. Specify a nonnegative integer in the range 0 to LowPercentage. The default is the same value as LowPercentage.

Here is an example of a premigration policy based that premigrates everything and migrates if the occupancy of the sysem pool is larger than 30 %: 

        /* premigrate all files from the given file sytem and directory */
        /* Define exclude list to exclude SpaceMan and snapshots */
        define(  exclude_list, (PATH_NAME LIKE '%/.SpaceMan/%' OR PATH_NAME LIKE '%/.snapshots/%') )
        
        /* Define LTFS as external pool */
        RULE EXTERNAL POOL 'ltfs1'
        EXEC '/opt/ibm/ltfsee/bin/ltfsee' /* full path to ltfsee command must be specified */
        OPTS 'EEPOOL' /* this is our pool in LTFS EE which is given by the runpolicy script*/
        
        /* here comes the premigration rule whereby the FILESYSTEM is given by the runpolicy script*/
        /* see the THRESHOLD(high%, low%, premig%), kicks in at high% and premig% */
        RULE 'ee-all-premig' MIGRATE FROM POOL 'system' THRESHOLD (0,30,0) TO POOL 'ltfs1' WHERE
        (
          (
          PATH_NAME LIKE 'FILESYSTEM'
          AND (KB_ALLOCATED > 0)
          AND NOT (exclude_list)
          )
        )

Save this policy in a policy-file and run the policy for your file system (e.g. /ibm/gpfs) to migrate to pool mypool@lib0:

        runpolicy run /ibm/gpfs policy-file "mypool@lib0"
