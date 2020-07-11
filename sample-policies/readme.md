## Introduction

This folder contains some sample policy files. This readme briefly describes the policies contained in the policy files and how to invoke it using the IBM Spectrum Scale policy engine. 

These examples have been tested in a test environment. There is no guarantee that these policies work in any environment. Furthermore it requires knowledge about the policy rule language and policy engine parameters. Refer to the [IBM Spectrum Scale ILM policy whitepaper](https://www-03.ibm.com/support/techdocs/atsmastr.nsf/WebIndex/WP102642) for more information about the RULES and policy engine parameters. 


## Policy file examples 

In this section the sample policy files located in this folder are explained, along with the command to run the policy engine using these policy files. The description below contains some basic parameters for the `mmapplypolicy` command, further parameters may be required. 

- Policy [migrate-all.txt](../sample-policies/migrate-all.txt) migrates all files that are not migrated, including pre-migrated files. The following command can be used to run this policy:


		mmapplypolicy path -P migrate-all.txt -M EEPOOL=pool@lib -N <eenodes> -m <threads> -B <bucketsite> --single-instance 

  
   The parameter `-M EEPOOL=pool@lib` denotes the destination pool for the migration and `pool@lib` must specify an existing pool in the Spectrum Archive EE system. It substitutes the variable `EEPOOL` within the policy. Additional parameters `-N <eenodes> -m <threads> -B <bucketsite> --single-instance` specify the Spectrum Archive EE node names (`-N`), the number of `eeadm migrate` threads per node (`-m`), the number of files per file list (`-B`) and to run as single instance (`--single-instance`). Futher parameters may be required. 


- Policy [migrate-fset.txt](../sample-policies/migrate-fset.txt) migrates all files for a particular fileset that are not migrated, including pre-migrated files. To run the policy:

	
		mmapplypolicy path -P migrate-fset.txt -M EEPOOL=pool@lib -M FSET=filesetname -N <eenodes> -m <threads> -B <bucketsite> --single-instance 


   The parameter `-M EEPOOL=pool@lib` denotes the destination pool for the migration and `pool@lib` must specify an existing pool in the Spectrum Archive EE system. The parameter `-M FSET=filesetname` denotes the fileset name subject for migration and the file set named `filesetname` must exist within the specified `path`.   
   Additional parameters `-N <eenodes> -m <threads> -B <bucketsite> --single-instance` specify the Spectrum Archive EE node names (`-N`), the number of `eeadm migrate` threads per node (`-m`), the number of files per file list (`-B`) and to run as single instance (`--single-instance`). Futher parameters may be required. 
   
   
- Policy [premigrate-all.txt](../sample-policies/premigrate-all.txt) premigrates all resident files. To run the policy:


		mmapplypolicy path -P premigrate-all.txt -M EEPOOL=pool@lib -N <eenodes> -m <threads> -B <bucketsite> --single-instance 

  
   The parameter `-M EEPOOL=pool@lib` denotes the destination pool for the premigration and `pool@lib` must specify an existing pool in the Spectrum Archive EE system. It substitutes the variable `EEPOOL` within the policy. Additional parameters `-N <eenodes> -m <threads> -B <bucketsite> --single-instance` specify the Spectrum Archive EE node names (`-N`), the number of `eeadm migrate` threads per node (`-m`), the number of files per file list (`-B`) and to run as single instance (`--single-instance`). Futher parameters may be required. 
      

- Policy [premigrate-fset.txt](../sample-policies/premigrate-fset.txt) migrates all files for a particular fileset that are not migrated, including pre-migrated files. To run the policy:


		mmapplypolicy path -P premigrate-fset.txt -M EEPOOL=pool@lib -M FSET=filesetname -N <eenodes> -m <threads> -B <bucketsite> --single-instance 


   The parameter `-M EEPOOL=pool@lib` denotes the destination pool for the premigration and `pool@lib` must specify an existing pool in the Spectrum Archive EE system. The parameter `-M FSET=filesetname` denotes the fileset name subject for premigration and the file set named `filesetname` must exist within the specified `path`.   
   Additional parameters `-N <eenodes> -m <threads> -B <bucketsite> --single-instance` specify the Spectrum Archive EE node names (`-N`), the number of `eeadm migrate` threads per node (`-m`), the number of files per file list (`-B`) and to run as single instance (`--single-instance`). Futher parameters may be required. 
	

- Policy [recall-all.txt](../sample-policies/recall-all.txt) recalls all files located in a specified directory (`RECAllDIR`). After recall files are in status `premigrated`. To run the policy:


		mmapplypolicy path -P recall-all.txt -M RECALLDIR=recallpath -N <eenodes> -m <threads> -B <bucketsite> --single-instance 

  
   The parameter `-M RECALLDIR=recallpath` denotes the path in the Spectrum Scale file system subject for recall. All migrated files in this path are being recalled. Additional parameters `-N <eenodes> -m <threads> -B <bucketsite> --single-instance` specify the Spectrum Archive EE node names (`-N`), the number of `eeadm recall` threads per node (`-m`), the number of files per file list (`-B`) and to run as single instance (`--single-instance`). Futher parameters may be required. 
   
   
- Policy [list-byState.txt](../sample-policies/list-byState.txt) creates lists of all files in accordance to their migration state. For each migration state (resident, migrated, premigrated) a separate file list is created. To run the policy:


		mmapplypolicy path -P list-byState.txt -I defer -f dirPrefix

  
   The resulting file lists are stored in a directory denoted by parameter `-f dirPrefix`. File names of resident files are stored in file `dirPrefix.list.r`, file names of premigrated files are stored in file `dirPrefix.list.p` and file names of migrated files are stored in file `dirPrefix.list.m`. For example if the parameter `dirPrefix` is set to `/tmp/files`, then the file lists would be named: `/tmp/files.list.r`, `/tmp/files.list.p` and `/tmp/files.list.m`. 
   
   
- Policy [list-byTapeID.txt](../sample-policies/list-byTapeID.txt) creates a list of all files that are located on a particular tape ID. The tape ID is specified in the command line. To run the policy:


		mmapplypolicy path -P list-byTapeID.txt -I defer -f dirPrefix -M TAPEID=volser

   The tape ID for which the files should be listed in provided with parameter `-M TAPEID=volser`.
   The resulting file list is stored in a directory denoted by parameter `-f dirPrefix` and named `dirPrefix.list.fileontape`. For example if the parameter `dirPrefix` is set to `/tmp/files`, then the file list would be named: `/tmp/files.list.filesontape`. This file list includes all path and file names of files stored on the subject tape ID. This is includes files that have the primary or a secondary copy on the subject tape. 


- Policy [list-byStateWithTapeID.txt](../sample-policies/list-byStateWithTapeID.txt) creates a lists of all files that that are in premigrated and migrated state including the tape ID where these files are (pre)migrated to. To run the policy:


		mmapplypolicy path -P list-byStateWithTapeID.txt -I defer -f dirPrefix 

   The resulting file lists are stored in a directory denoted by parameter `-f dirPrefix`. File names and tape ID of premigrated files are stored in file `dirPrefix.list.premigTapeID` and file names and tape ID of migrated files are stored in file `dirPrefix.list.migTapeID`. For example if the parameter `dirPrefix` is set to `/tmp/files`, then the file lists would be named: `/tmp/files.list.premigTapeID` and `/tmp/files.list.migTapeID`.
   
