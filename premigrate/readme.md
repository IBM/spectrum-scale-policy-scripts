
# Script: ltfsee_premig.sh

## Description

This script can be used as an interface script in combination with a migration policy to pre-migrate files from IBM Spectrum Scale to IBM Spectrum Archive EE. This script receives the file list from the policy engine according to the MIGRATE rule and feeds this into the `ltfsee_premig.sh` script. 


## Prerequisite

Copy the `ltfsee_premig.sh` script to a directory of the executing EE node. To run the policy on multiple EE nodes the script must be placed in the same directory on each node. Consider placing it in a shared file system. 

Adjust the premigration policy according to your needs and store it in the same directory as the `ltfsee_premig.sh` script. The file [premig_fset_all.txt](premig_fset_all.txt) is an example for a premigration policy. 

Note, the directory where the `ltfsee_premig.sh` script is stored must be entered into to the EXEC clause of the EXTERNAL POOL rule
 

## Invokation

The premigration script `ltfsee_premig.sh` is invoked with the policy engine:


	# mmapplypolicy fsname -P policyfile -N nodenames --single-instance
	
	Options:
		fsname			is the file system name, file system path or the file system path with a subdirectory. 
		-P policyfile		is the policy file including the EXTERNAL POOL rule specifying the `ltfsee_premig.sh` interface script and the MIGRATE rule. 
		-N nodenames		node name or node class name that executes this policy. Must be Spectrum Archive EE nodes
		--single-instance	run only one instance of this policy. 


An example for the `policyfile` in file [premig_fset_all.txt](premig_fset_all.txt). Further options can be specified with the `mmapplypolicy` command. 	


## Processing 

The policy engine (`mmapplypolicy`) identifies files according to the migrate rule and passes these files to the interface script `ltfsee_premig.sh`. The interface script `ltfsee_premig.sh` premigrates the selected files using the command: `eeadm premigrate filelist -p pool@library`. 


## Output

Output of the script is logged to STDOUT and ends up within the output of the mmapplypolicy command


