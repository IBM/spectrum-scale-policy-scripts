This project includes scripts for the Spectrum Scale Policy Engine:

Script Name: runpolicy.sh

Purpose: runpolicy is a wrapper for mmapplypolicy that runs a policy provided as
input file for a file system or directory provided as input. It also passes
arguments to the policy itself such as the FILESYSTEM and EEPOOL. For more details
about its usage see runpolicy.readme. 

------------------------

Script Name: receiver.sh

Purpose: List policies can be used to list files based on rules and give the
list of files to an external pool script. The external pool script can then
process the files according to the needs. This script is an external pool script
that receives the input from a list policy and prints all the file names in an
output file. Of course you can add other operations.

------------------------

Folder [immutable](immutable/) - Set files to immutable

Purpose: This script is an external pool script that receives the input from a
list policy and sets all files identified by the LIST policy to immutable using
the mmchattr command. The retention period is defined in the policy itself and
is applied to each file by setting the retention time to current date and time
plus retention period

------------------------

Folder [list](list/) - List policy script

Purpose: This script is a wrapper to run custom LIST policies. The list
policy files are installed in the same path as the script list.sh. The list
policy files have a specific naming convention with the "operation code"
in the file name. The script list.sh is invoked with the "operation code"
that executes the underlying policy file and prints the selected files to
STDOUT.

------------------------

Folder [Recall](recall/)

Purpose: This folder contains script and policies to drive tape optimized recalls
with TSM HSM or Spectrum Archive (LTFS EE). The scripts are customized interface 
scripts that perform recall instead of migration. 

------------------------

Folder [quota-migration](/quota-migration) - Automated migration based on Quota 

Purpose: This folder contains a callback script and policies facilitating migration of a fileset to be triggered when the quota consumption reaches a certain threshold. The callback script (callback-quota.sh) is invoked when the GPFS event softQuotaExceeded is triggered. This script invokes a list policy to list files in the fileset that qualify for migration based on the quota limits and a migration policy that migrates the files identified by the list policy. 

------------------------

Folder [premigrate](/premigrate) - Premigrate policies and scripts

Purpose: This folder contains script and policies to perform premigrates using migrate 
policies. It provides an interface script that wraps perform pre-migration instead of 
migration. It contains an interface script for Spectrum Archive (LTFS EE). TSM HSM will be 
added later. 

