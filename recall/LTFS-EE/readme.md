

# Script: ltfsee_recall.sh

## Description: 
This script can be used as an interface script in combination with a migration policy to recall files from Spectrum Archive EE to Spectrum Scale. This script receives the file list from the policy engine according to the MIGRATE rule and feeds this into the ltfsee recall command. 

## Prerequisite: 
The interface customized interface script (ltfsee_recall.sh) must be installed on all nodes that are enabled to perform the migration. 

An external pool rule that invokes this script in combination with a MIGRATE rule is required. Find an example below:

	/* define macros */
	define(recall_dir, (PATH_NAME LIKE '%'))
	
	/* define external pool */
	RULE 'extpool' EXTERNAL POOL 'ltfs' EXEC '/root/silo/recall/ltfsee_recall.sh' OPTS 'eelib1'
	
	/* define migration rule */
	RULE 'recall' MIGRATE FROM POOL 'ltfs' TO POOL 'system' FOR FILESET ('swr') WHERE 
	(XATTR('dmapi.IBMPMig') IS NULL) AND NOT (XATTR('dmapi.IBMTPS') IS NULL) and (recall_dir)

### Note: 
The example above shows the policy that pre-migrates all files that are not pre-migrated and are larger than zero bytes. The external pool rule executes the customized interface script (/path/ltfsee_premig.sh). The MIGRATE rule selects all files that are not yet pre-migrated and not empty.


## Invokation: 
  mmapplypolicy fsname -P policyfile -N ltfseenodes --single-instance [-B -m]

## Processing: 
The policy engine applies the MIGRATE rules and selects files according to the criteria. It passes these files to the interface script (ltfsee_recall.sh). The interface script invokes ltfsee recall command with the list of files and the target pool. 

## Output: 
Output of the script is logged to STDOUT and ends up within the output of the mmapplypolicy command



