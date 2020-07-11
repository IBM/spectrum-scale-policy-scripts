## Introduction

The script `runpolicy.sh` is a wrapper for `mmapplypolicy`command that runs a policy for file system directory provided as input. When started with no additional arguments, `runpolicy.sh` will not execute the policy, but test it. With additional arguments you can run the policy and provide addition parameter to the `mmapplypolicy` command. 


## Preparation

Copy the program `runpolicy.sh` to a directory of a Spectrum Scale cluster node where you want to run the script.


Adjust the variables in the `runpolicy.sh` script:

| Parameter | Description |
| ----------|-------------|
| DEFAULT_OPTS | defines the default parameters for the policy engine. These are used if not other parameters are specified in the argument `opts` of the `runpolicy.sh` script |

Encoding default parameter in the script variable `DEFAULT_OPTS` is usefull, when these parameters are static. Alternatively, parameters for the policy engine can be bassed with the `runpoliy.sh` commmand. 


Create and copy the file including the policy to a directory of the Spectrum Scale where you want to run the script. Find more guidance for the policies in section [Sample Policies](#Sample-policies)

Run the script. 


## Running the script

The scipt can be invoked like this: 

	runpolicy.sh filesystem-directory policyfile [opts]
		filesystem: file system path and directory subject for the policy run (mandatory)
		policyfile: name of the file including the policy (mandatory)
        opts      : options for mmapplypolicy, such as -i <mode> -m <threads> -B <bucketsize> -n --single-instance -M param=value (optional)

**Notes:**
The sequence of parameters matters. The parameter `filesystem-path-directory` has to come first, followed by name of the `policyfile`. 

The default run mode is `test`. If you want to run the policy in a different mode specify -I yes for MIGRATE policies or -I defer -f /tmp/prefix for list policies in parameter `opts`. 

Parameter `opts` comes last and can include specific paramaters controlling `mmapplypolicy`. If parameter `opts` is not specified then the parameters encoded in the script variable `$DEFAULT_OPTS` are used. 

Find some examples to run the script along with some sample policies below. 


### Sample policies

In folder [sample-policies](../sample-policies/) you can find some useful sample policies:

- Policy [migrate-all.txt](../sample-policies/migrate-all.txt) migrates all files that are not migrated, including pre-migrated files. To run the policy:
	
	runpolicy.sh path migrate-all.txt -M EEPOOL=pool1@lib1 [opts]
  
   The parameter `-M EEPOOL=pool1@lib1` denotes the destination pool for the migration and must be an existing pool in the Spectrum Archive EE system. Additional options for the policy engine should be configured. These options are passed to the `mmapplypolicy` command should include: `-B bucketsize -m threads -N nodenames --single-instance`. These options can either be encoded in the command line parameter `opts`, or these options can be encoded in the script variable `DEFAULT_OPTS`.


- Policy [migrate-fset.txt](../sample-policies/migrate-fset.txt) migrates all files for a particular fileset that are not migrated, including pre-migrated files. To run the policy:
	
	runpolicy.sh path migrate-fset.txt -M EEPOOL=pool1@lib1 -M FSET=filesetname [opts]
  
   The parameter `-M EEPOOL=pool1@lib1` denotes the destination pool for the migration and must be an existing pool in the Spectrum Archive EE system. The parameter `-M FSET=filesetname` denotes the fileset name subject for migration. Additional options for the policy engine should be configured. These options are passed to the `mmapplypolicy` command should include: `-B bucketsize -m threads -N nodenames --single-instance`. These options can either be encoded in the command line parameter `opts`, or these options can be encoded in the script variable `DEFAULT_OPTS`.
   
   
premigrate-all.txt
premigrate-fset.txt
recall-all.txt
list-byState.txt
list-byTapeID.txt
list-byStateWithTapeID.txt


## Output

The `runpolicy.sh` script runs the `mmapplypolicy` command and logs all output to the console. 
