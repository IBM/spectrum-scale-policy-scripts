# List policy script

## Description:

This is a wrapper script to run predefined and custom LIST policies. LIST policies can be used to find files matching certain criteria, such as file that are migrated or files that are premigrated. There are some predefined LIST policies included (see section [Running predefined LIST policies](#Running-predefined-LIST-policies)). Further custom LIST policies can be created and run by this wrapper script (see section [Running custom LIST policies](#Running-custom-LIST-policies)).


## Running predefined LIST policies

The wrapper script `list.sh` lists the number of files according to the state given as command line parameter. Optionally the file names can be listed (option `-v`)

For installation, copy the wrapper script `list.sh` along with the predefined policy file examples named `listpol_*.txt` to the same directory. 

The syntax is:

	list.sh state fspath [-v -s]
	
	Options:
	state		is the name of the policy to be executed according to the above naming conventions
    fspath		is the file system or directory path subject for the list policy
	-v			list the file names instead of the number of files
	-s 			specify the local work directory for the policy engine (default is /tmp)
	
	Predefined states are:
	mig		list all migrated files
	pmig		list all premigrated files
	res		list all resident files 
	all		list all premigrated 
	
The script checks if the list policy file exists, executes the approporate LIST policy using `mmapplypolicy` and prints the number of files matching the state. The actual path and file names matching the LIST rule are written to `/tmp/gpfs.list.<state>`. The directory of the output files can be changed in the script by the parameter `$ofPrefix`.

The output of the policy run is written to STDOUT.

For example, to list the number of in file system /gpfs/archive that are migrated use the following command:

	list.sh mig /gpfs/archive
	
	[I] 2020-06-23@16:55:05.206 Directory entries scanned: 838.
	[I] 2020-06-23@16:55:06.106 Parallel-piped sort and policy evaluation. 838 files scanned.
	[I] 2020-06-23@16:55:06.399 Piped sorting and candidate file choosing. 141 records scanned.
	[I] 2020-06-23@16:55:06.437 Policy execution. 0 files dispatched.
	==============================================================================
	Files that are in state mig:
	Number of files with state mig:  141  (filename: /tmp/gpfs.list.mig)


The file list with the file names is stored in `/tmp/gpfs.list.mig` (until the program is executed again with the same state operation).

You can also create your own list policies and run it by the wrapper script `list.sh`. 


## Running custom LIST policies

The wrapper script `list.sh` can also be used to run your own custom policies. To create a custom policy two things must be considered:

1. Create a custom list policy where the EXTERNAL LIST name defines the state of the files to be listed. For example, the following EXTERNAL LIST name is `immut`. The associated LIST rules lists immutable files:

		/* Define exclude list to exclude SpaceMan and snapshots */
		define(  exclude_list,
		  (PATH_NAME LIKE '%/.SpaceMan/%' OR 		
		   PATH_NAME LIKE '%/.ltfsee/%' OR 			
		   PATH_NAME LIKE '%/.mmSharedTmpDir/%' OR	
		   PATH_NAME LIKE '%/.snapshots/%' OR 		
		   NAME LIKE '.mmbackupShadow%' OR 			
		   NAME LIKE 'mmbackup%')					
		) 

		/* find immutable files */
		define(is_immutable,(MISC_ATTRIBUTES LIKE '%X%'))

		RULE EXTERNAL LIST 'immut' EXEC ''
		RULE 'immutable_files' LIST 'immut' WHERE (is_immutable) AND ( NOT (exclude_list) )


2. Store this policy in a file named: `listpol_immut.txt`. Thus, the name of the EXTERNAL LIST must match the file name pattern of the policy file. 


To run this policy with the `list.sh` script, copy the policy file to the directory where `list.sh` is located or alternatively to the location specified by parameter `$pfPrefix` within the `list.sh`script. Now run the script:

	list.sh immut /gpfs/archive


This display list the number of immutable files in the file system `gpfs/archive`. The file list with the file names is stored in `/tmp/gpfs.list.immut` (until the program is executed again with the same state operation).
