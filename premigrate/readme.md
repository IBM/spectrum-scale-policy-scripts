
# Script: ltfsee_premigrate.sh

## Description: 
This script can be used as an interface script in combination with a migration policy to pre-migrate files from Spectrum Scale to Spectrum Archive EE. This script receives the file list from the policy engine according to the MIGRATE rule and feeds this into the ltfsee premigrate command. 

## Prerequisite: 
The interface customized interface script (ltfsee_premig.sh) must be installed on all nodes that are enabled to perform the migration. 

An external pool rule that invokes this script in combination with a MIGRATE rule is required. Find an example below:

    /* define macros */
    define( is_premigrated,(MISC_ATTRIBUTES LIKE '%M%' AND MISC_ATTRIBUTES NOT LIKE '%V%') )
    define( is_empty,(KB_ALLOCATED=0) )
    
    /* Define exclude list to exclude SpaceMan and snapshots */
    RULE 'exclude' EXCLUDE WHERE (PATH_NAME LIKE '%/.SpaceMan/%' OR PATH_NAME LIKE '%/.snapshots/%' )
    
    /* Define LTFS as external pool with customized interface script */
    RULE EXTERNAL POOL 'ltfsPremig'
    EXEC '/path/ltfsee_premig.sh' 
    OPTS '-p test@eelib1' 
    
    /* select files that are not pre-migrated and not empty for (pre) migration*/
    RULE 'MigToExt' MIGRATE FROM POOL 'system' TO POOL 'ltfsPremig' 
    WHERE ( NOT (is_empty) AND NOT (is_premigrated) )


Note: 
The example above shows the policy that pre-migrates all files that are not pre-migrated and are larger than zero bytes. The external pool rule executes the customized interface script (/path/ltfsee_premig.sh). The MIGRATE rule selects all files that are not yet pre-migrated and not empty.

## Invokation: 
mmapplypolicy fsname -P policyfile -N ltfseenodes --single-instance

## Processing: 
The policy engine applies the EXCLUDE and MIGRATE rules and selects files according to the criteria. It passes these files to the interface script (ltfsee_premigrate.sh). The interface script invokes ltfsee premigrate with the list of files and the target pool. 

## Output: 
Output of the script is logged to STDOUT and ends up within the output of the mmapplypolicy command


