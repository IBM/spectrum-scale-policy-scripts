This project includes scripts for the Spectrum Scale Policy Engine:

Script Name: runpolicy.sh
Purpose: runpolicy is a wrapper for mmapplypolicy that runs a policy provided as 
input file for a file system or directory provided as input. It also passes 
arguments to the policy itself such as the FILESYSTEM and EEPOOL

Script Name: receiver.sh
Purpose: List policies can be used to list files based on rules and give the 
list of files to an external pool script. The external pool script can then
process the files according to the needs. This script is an external pool script
that receives the input from a list policy and prints all the file names in an 
output file. Of course you can add other operations.
