## Introduction

The script `runpolicy.sh` is a wrapper for `mmapplypolicy`command that runs a policy for file system directory provided as input. When started with no additional arguments, `runpolicy.sh` will not execute the policy and run in test mode. This is usefull to check the policy syntax. With additional command line parameters you can run the policy and provide addition options to the `mmapplypolicy` command. 


## Preparation

Copy the program `runpolicy.sh` to a directory of a Spectrum Scale cluster node where you want to run the script.


Adjust the variables in the `runpolicy.sh` script:

| Parameter | Description |
| ----------|-------------|
| DEFAULT_OPTS | defines the default parameters for the policy engine. These are used if not other parameters are specified in the argument `opts` of the `runpolicy.sh` script |

Encoding default parameter in the script variable `DEFAULT_OPTS` is useful, when these parameters are static. Alternatively, parameters for the policy engine can be bassed with the `runpoliy.sh` commmand. 


Create and copy the file including the policy to a directory of the Spectrum Scale where you want to run the script. Find more guidance for the policies in section [Sample Policies](#Sample-policies)



## Running the script

The scipt can be invoked like this: 

	runpolicy.sh filesystem-directory policyfile [opts]
		filesystem: file system path and directory subject for the policy run (mandatory)
		policyfile: name of the file including the policy (mandatory)
        opts      : options for mmapplypolicy, such as -i <mode> -m <threads> -B <bucketsize> -n --single-instance -M param=value (optional)

**Notes:**
The sequence of parameters matters. The parameter `filesystem-path-directory` has to come first, followed by name of the `policyfile`. 

The default run mode is `test`. If you want to run the policy in a different mode specify `-I yes` for MIGRATE policies or `-I defer -f dirPrefix` for list policies in parameter `opts`. 

Parameter `opts` comes last and can include specific paramaters controlling `mmapplypolicy`. If parameter `opts` is not specified then the parameters encoded in the script variable `$DEFAULT_OPTS` are used. If parameter `opts` is specified the variable `$DEFAULT_OPTS` is ignored. 

Find some examples to run the script along with some sample policies below. 


### Sample policies

In folder [sample-policies](../sample-policies/) you can find some useful sample policies:

- Policy [migrate-all.txt](../sample-policies/migrate-all.txt) migrates all files that are not migrated, including pre-migrated files. To run the policy:


		runpolicy.sh path migrate-all.txt -M EEPOOL=pool1@lib1 [opts]

  
   The parameter `-M EEPOOL=pool1@lib1` denotes the destination pool for the migration and must be an existing pool in the Spectrum Archive EE system. Additional options for the policy engine should be configured. These options are passed to the `mmapplypolicy` command should include: `-B bucketsize -m threads -N nodenames --single-instance`. These options can either be encoded in the command line parameter `opts`, or these options can be encoded in the script variable `DEFAULT_OPTS`.


- Policy [migrate-fset.txt](../sample-policies/migrate-fset.txt) migrates all files for a particular fileset that are not migrated, including pre-migrated files. To run the policy:

	
		runpolicy.sh path migrate-fset.txt -M EEPOOL=pool1@lib1 -M FSET=filesetname [opts]

  
   The parameter `-M EEPOOL=pool1@lib1` denotes the destination pool for the migration and must be an existing pool in the Spectrum Archive EE system. The parameter `-M FSET=filesetname` denotes the fileset name subject for migration. Additional options for the policy engine should be configured. These options are passed to the `mmapplypolicy` command should include: `-B bucketsize -m threads -N nodenames --single-instance`. These options can either be encoded in the command line parameter `opts`, or these options can be encoded in the script variable `DEFAULT_OPTS`.

- Policy [premigrate-all.txt](../sample-policies/premigrate-all.txt) premigrates all resident files. To run the policy:


		runpolicy.sh path premigrate-all.txt -M EEPOOL=pool1@lib1 [opts]

  
   The parameter `-M EEPOOL=pool1@lib1` denotes the destination pool for the premigration and must be an existing pool in the Spectrum Archive EE system. Additional options for the policy engine should be configured. These options are passed to the `mmapplypolicy` command should include: `-B bucketsize -m threads -N nodenames --single-instance`. These options can either be encoded in the command line parameter `opts`, or these options can be encoded in the script variable `DEFAULT_OPTS`.


- Policy [premigrate-fset.txt](../sample-policies/premigrate-fset.txt) migrates all files for a particular fileset that are not migrated, including pre-migrated files. To run the policy:

	
		runpolicy.sh path premigrate-fset.txt -M EEPOOL=pool1@lib1 -M FSET=filesetname [opts]

  
   The parameter `-M EEPOOL=pool1@lib1` denotes the destination pool for the premigration and must be an existing pool in the Spectrum Archive EE system. The parameter `-M FSET=filesetname` denotes the fileset name subject for premigration. Additional options for the policy engine should be configured. These options are passed to the `mmapplypolicy` command should include: `-B bucketsize -m threads -N nodenames --single-instance`. These options can either be encoded in the command line parameter `opts`, or these options can be encoded in the script variable `DEFAULT_OPTS`.


- Policy [recall-all.txt](../sample-policies/recall-all.txt) recalls all files located in a specified directory (`RECAllDIR`). After recall files are in status `premigrated`. To run the policy:


		runpolicy.sh path recall-all.txt -M RECALLDIR=recallpath [opts]

  
   The parameter `-M RECALLDIR=recallpath` denotes the path in the Spectrum Scale file system subject for recall. All migrated files in this path are being recalled. Additional options for the policy engine should be configured. These options are passed to the `mmapplypolicy` command should include: `-B bucketsize -m threads -N nodenames --single-instance`. These options can either be encoded in the command line parameter `opts`, or these options can be encoded in the script variable `DEFAULT_OPTS`.

- Policy [list-byState.txt](../sample-policies/list-byState.txt) creates lists of all files in accordance to their migration state. For each migration state (resident, migrated, premigrated) a separate file list is created. To run the policy:


		runpolicy.sh path list-byState.txt -I defer -f dirPrefix

  
   The resulting file lists are stored in a directory denoted by parameter `-f dirPrefix`. File names of resident files are stored in file `dirPrefix.list.r`, file names of premigrated files are stored in file `dirPrefix.list.p` and file names of migrated files are stored in file `dirPrefix.list.m`. For example if the parameter `dirPrefix` is set to `/tmp/files`, then the file lists would be named: `/tmp/files.list.r`, `/tmp/files.list.p` and `/tmp/files.list.`. 
   Instead of specifying the parameter `-I defer -f dirPrefix` in the command line, these can also be encoded in the script variable `DEFAULT_OPTS`.

   
- Policy [list-byTapeID.txt](../sample-policies/list-byTapeID.txt) creates a list of all files that are located on a particular tape ID. The tape ID is specified in the command line. To run the policy:


		runpolicy.sh path list-byTapeID.txt -I defer -f dirPrefix -M TAPEID=volser

   The tape ID for which the files should be listed in provided with parameter `-M TAPEID=volser`.
   The resulting file list is stored in a directory denoted by parameter `-f dirPrefix` and named `dirPrefix.list.filesontape`.  For example if the parameter `dirPrefix` is set to `/tmp/files`, then the file list would be named: `/tmp/files.list.filesontape`. This file list includes all path and file names of files stored on the subject tape ID. This is includes files that have the primary or a secondary copy on the subject tape. 


- Policy [list-byStateWithTapeID.txt](../sample-policies/list-byStateWithTapeID.txt) creates a lists of all files that that are in premigrated and migrated state includin the tape ID where these files are (pre)migrated to. To run the policy:


		runpolicy.sh path list-byStateWithTapeID.txt -I defer -f dirPrefix 

   The resulting file lists are stored in a directory denoted by parameter `-f dirPrefix`. File names and tape ID of premigrated files are stored in file `dirPrefix.list.premigTapeID` and file names and tape ID of migrated files are stored in file `dirPrefix.list.migTapeID`. For example if the parameter `dirPrefix` is set to `/tmp/files`, then the file lists would be named: `/tmp/files.list.premigTapeID` and `/tmp/files.list.migTapeID`.
   Instead of specifying the parameter `-I defer -f dirPrefix` in the command line, these can also be encoded in the script variable `DEFAULT_OPTS`.


## Output

The `runpolicy.sh` script runs the `mmapplypolicy` command and logs all output to the console. The script output is marked with by token `RUNPOLICY`.
