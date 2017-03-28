This project includes scripts for the Spectrum Scale Policy Engine:

Script Name: runpolicy.sh

Purpose: runpolicy is a wrapper for mmapplypolicy that runs a policy provided as
input file for a file system or directory provided as input. It also passes
arguments to the policy itself such as the FILESYSTEM and EEPOOL

------------------------

Script Name: receiver.sh

Purpose: List policies can be used to list files based on rules and give the
list of files to an external pool script. The external pool script can then
process the files according to the needs. This script is an external pool script
that receives the input from a list policy and prints all the file names in an
output file. Of course you can add other operations.

------------------------

Script Name: [makeimmutable.sh](immutable/) - Set files to immutable

Purpose: This script is an external pool script that receives the input from a
list policy and sets all files identified by the LIST policy to immutable using
the mmchattr command. The retention period is defined in the policy itself and
is applied to each file by setting the retention time to current date and time
plus retention period

------------------------

Script Name: [list.sh](list/) - List policy script

Purpose: This script is a wrapper to run custom LIST policies. The list
policy files are installed in the same path as the script list.sh. The list
policy files have a specific naming convention with the "operation code"
in the file name. The script list.sh is invoked with the "operation code"
that executes the underlying policy file and prints the selected files to
STDOUT.

------------------------

[Recall policy](recall/)

The policy engine can be used to recall large numbers of files from an external pool, e.g. from tape. The policy file provided with this project can act as a template for performing such bulk recalls.
