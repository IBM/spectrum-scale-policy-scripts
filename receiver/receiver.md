
## Introduction

List policies can be used to list files based on rules and give the list of files to an external pool script. The external pool script can then process the files according to the needs.

I have create a script which receives the input from a list policy and prints all the file names in an output file.

## Instructions

1. copy the program to a directory of a node on your GPFS cluster and make it executable.

2. create a list policy file as file such as the following which identifies migrated files.
            /* list all files that are migrated*/
            define(  exclude_list, (PATH_NAME LIKE '%/.SpaceMan/%' OR PATH_NAME LIKE '%/.ctdb/%' OR NAME LIKE 'user.quota%' OR NAME LIKE 'fileset.quota%' OR NAME LIKE group.quota%') )
            RULE EXTERNAL LIST 'mig-list' EXEC './receiver.sh' 
            RULE 'list_mig' LIST 'mig-list' WHERE (MISC_ATTRIBUTES LIKE '%M%' AND KB_ALLOCATED == 0)

3. Run mmapplypolicy from the directory where the program is located.
            mmapplypolicy <gpfs-filesystem-dir> -m 1 -N <nodename> -n1 --single-instance -P <policy-file>

### Notes:
-m 1: only one thread
-N <nodename>: specifies the nodename where the program is installed
-P <policy-file>: specifies the policy file including a policy like above


### Output:
The program creates a subdirectory in the current directory called reciever and place a receiver.out file there, which includes all files identified. It also places a receiver.log file with some logging information

### Combination with runpolicy.sh
You can also combine this with the runpolicy script. Then you do not have to run the long mmapplypolicy command:

                  ./runpolicy run /mnt/userfs policy_mig_list
