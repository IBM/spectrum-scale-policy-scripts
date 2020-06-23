
# Script: ltfsee_recall.sh


## Description

This script can be used as an interface script in combination with a migration policy to recall files from Spectrum Archive EE to Spectrum Scale. This script receives the file list from the policy engine according to the MIGRATE rule and feeds this into the ltfsee recall command. 

Please notice that IBM Spectrum Archive Enterprise Edition version 1.3.0.7 and above has built in capabilities to recall files from LTFS Tape to IBM Spectrum Scale disk. For more details see the IBM Spectrum Archive EE Knowledge Center - section [Manual-recall-with-the mmapplypolicy-command](https://www.ibm.com/support/knowledgecenter/en/ST9MBR_1.3.0/ltfs_ee_recall_mmapplypolicy.html). If you are using this version of IBM Spectrum Archive EE it is recommended to use the built in approach.

The script `ltfsee_recall.sh` along with the policies has been last tested with IBM Spectrum Archive EE version 1.3.0.7.

## Prerequisite

Copy the `ltfsee_recall.sh` script to a directory of the executing EE node. To run the policy on multiple EE nodes the script must be placed in the same directory on each node. Consider placing it in a shared file system. 

Adjust the recall policy according to your needs and store it in the same directory as the `ltfsee_recall.sh` script. The directory name where the `ltfsee_recall.sh` script is stored on all executing nodes must be updated in the EXTERNAL POOL rule. 

There are two policies provided:

[recall_migOnly_policy.txt](recall_migOnly_policy.txt):
This policy recalls all migrated files that match clause in the macro `recall_dir`. Only migrated files are recalled. To recall migrated files directly to resident state the option `--resident` has to be added to the EXTERNAL POOL rule in the clause: `OPTS '--resident'`. Note, you cannot recall pre-migrated files, unless you recall to resident state. 

[recall_migPmig_policy.txt](recall_migPmig_policy.txt):
This policy recalls all pre-migrated and migrated files to resident state that match clause in the macro `recall_dir`. 
 
If the `ltfsee_recall.sh` script and the policies are stored in directory `/usr/local/bin` then the EXTERNAL POOL rule EXEC clause must be adjusted to:

	RULE 'extpool' EXTERNAL POOL 'ltfs' EXEC '/usr/local/bin/ltfsee_recall.sh' 


## Invokation

The recall script `ltfsee_recall.sh` is invoked with the policy engine:


	# mmapplypolicy fsname -P policyfile -N nodenames --single-instance
	
	Options:
		fsname			is the file system name, file system path or the file system path with a subdirectory. 
		-P policyfile		is the policy file including the EXTERNAL POOL rule specifying the `ltfsee_premig.sh` interface script and the MIGRATE rule. 
		-N nodenames		node name or node class name that executes this policy. Must be Spectrum Archive EE nodes
		--single-instance	run only one instance of this policy. 


Two example for the `policyfile` are provided in [recall_migOnly_policy.txt](recall_migOnly_policy.txt) and [recall_migPmig_policy.txt](recall_migPmig_policy.txt). Further options can be specified with the `mmapplypolicy` command. 	


## Processing 

The policy engine (`mmapplypolicy`) identifies files according to the migrate rule and passes these files to the interface script `ltfsee_recall.sh`. The interface script `ltfsee_recall.sh` recalls the selected files using the command: `eeadm recall filelist [--resident]`. The option `--resident` can be specified via the OPTS clause in the EXTERNAL POOL definition of the policies. 


## Output

Output of the script is logged to STDOUT and ends up within the output of the mmapplypolicy command

