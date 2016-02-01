Description: 
This script can be used in combination with the policy engine and a proper LIST policy to automatically set files to immutable with a defined retention period. The retention time for each files is set to current date and time plus retention period defined in the policy. It is an interface script for LIST policy invoked by mmapplypolicy. 

Prerequisite:
EXTERNAL list policy that identifies files that are not immutable.

Example Policy:
/* define macros */
define( exclude_list, (PATH_NAME LIKE '%/.SpaceMan/%' OR PATH_NAME LIKE '%/.snapshots/%' OR NAME LIKE '%mmbackup%' ))
define( immutable, MISC_ATTRIBUTES LIKE '%X%')
/* define external script and 1 day retention for all files */
RULE EXTERNAL LIST 'setmp3' EXEC '/root/silo/makeimmutable.sh' OPTS '1'
/* define LITS rule to select files to be processed */
RULE 'mp3' LIST 'setmp3' FOR FILESET ('native') WHERE NOT (exclude_list) and NOT (immutable) and (NAME LIKE '%.mp3')

Note, mupliple EXTERNAL LIST and LIST rules can be specified in one policy with different retention periods. For example the rules below set 2 days retention times for files ending with *.pdf files. 
/* define external script and 1 day retention for all files */
RULE EXTERNAL LIST 'setpdf' EXEC '/root/silo/makeimmutable.sh' OPTS '2'
/* define LITS rule to select files to be processed */
RULE 'pdf' LIST 'setpdf' FOR FILESET ('native') WHERE NOT (exclude_list) and NOT (immutable) and (NAME LIKE '%.pdf')


Invokation:
mmapplypolicy fsname -P policyfile

Processing:
With the proper policy this script is invoked by mmapplypolicy with the following parameters:
  $1 operation (list, test)
  $2 file system name or name of filelist
  $3 optional parameter defined in LIST policy under OPTS, defines retention period in days relative to current date
The script implements the TEST and LIST operation. 
Upon TEST it tests if the file system name given with $2 exists and exits with 0.
Upon LIST it parses the filelist passed with the parameter $2, extracts the file names and sets the retention period to current-date plus retention-time. The retention-time is passed with the parameter $3 and encoded in the policy. 

Output:
Sets files identified to immutable with retention period define in policy relative to current date and time (default is defined as $DEFRETTIME). 
Write runtime information and debugging messages to log file $LOGFILE
