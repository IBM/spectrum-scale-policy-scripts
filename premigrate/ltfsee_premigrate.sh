#! /bin/ksh
#
# Copy Right IBM Corporation 2017
#
# Program: ltfsee_premigrate
#
# Description: 
# Interface script for MIGRATE policy invoked by mmapplypolicy 
# Invokes ltfsee premigrate -s filelist -p pool@library
#
# Prerequisite:
# EXTERNAL pool policy that identifies files to be premigrated.
#
# Input:
# invoked by mmapplypolicy with the following parameters:
#   $1 operation (list, test)
#   $2 file system name or name of filelist
#   $3 optional parameter defined in LIST policy under OPTS
#
# Output:
# Writes runtime information to STDOUT - ends up in mmapplypolicy output
#
# Example Policy:
# /* define macros */
# define(is_empty, (KB_ALLOCATED=0))
# define( is_premigrated,(MISC_ATTRIBUTES LIKE '%M%' AND MISC_ATTRIBUTES NOT LIKE '%V%') )
# /* define exclude rule */
# RULE 'exclude' EXCLUDE WHERE (PATH_NAME LIKE '%/.SpaceMan/%' OR PATH_NAME LIKE '%/.snapshots/%')
# /* define external pool */
# RULE 'extpool' EXTERNAL POOL 'ltfs' EXEC 'ltfsee_premig.sh' OPTS '-p test@eelib1'
# /* define migration rule */
# RULE 'premigall' MIGRATE FROM POOL 'system' TO POOL 'ltfs' WHERE NOT (is_empty) AND NOT (is_premigrated)
#
# Invokation:
# mmapplypolicy fsname -P policyfile
#
# Change History
# 10/09/12 first implementation based GAD startbackup
# 12/20/15 implementation for immutability, some streamlining of existing code
# 12/21/15 create the general receiver
# 08/23/17 ltfsee premigrate
# 08/31/17 streamline

#global variables for this script
# set the default option in case $3 is not give, allows to specify the pool in the syntax "-p pool@lib", just in case the pool is not set in the external pool definition of the migrate policy
DEFOPTS=""
# define ltfsee directory
LTFSEEDIR=/opt/ibm/ltfsee/bin

#++++++++++++++++++++++++++ MAIN ++++++++++++++++++++++++++++++++++++++
echo "================================================================================================"
echo "$(date +"%Y-%b-%d %H:%M:%S") ltfsee_premig.sh invoked with arguments: $*"

## Parse Arguments & execute
#$1 is the policy operation (list, migrate, etc) 
op=$1
#$2 is the policy file name
polFile=$2
#$3 is the option given in the EXTERNAL LIST rule with OPTS '..' should be the pool 
shift 2
option=$*
    
## evaluate the operation passed by mmapplypolicy and act upon it
case $op in 
  # there will always be a TEST call with $2 being the file system path
  TEST ) 
       echo "INFO: TEST option received for $polFile"
	   if [[ ! -z "$polFile" ]] then
	     if [[ ! -d "$polFile" ]] then
		   echo "WARNING: TEST directory $polFile does not exists."
		 fi
	   fi
	   ;;
  MIGRATE )
  # this is the actual migrate call where we call ltfsee premigrate
       echo "INFO: MIGRATE option received with file name $polFile and options $option"
       #set option to default if not set
       if [[ -z $option ]] then 
	     if [[ -z $DEFOPTS ]] then
		   echo "ERROR: Pool name not specified in the external pool rule."
		   exit 1
		 else
	      option=$DEFOPTS
		 fi
	   fi
	   
	   echo "INFO: Start processing files $polFile with ltfsee premigrate to pool $option"
	   $LTFSEEDIR/ltfsee premigrate -s $polFile $option 
	   rc=$?
       if (( rc != 0 )) then
         echo "WARNING: ltfsee premigrated ended with return code $rc"	
       fi		 
       ;;
  REDO )
	   echo "INFO: REDO option received with file name $polFile and options $option"
       ;;
  * )
	   echo "WARNING: UNKNOWN operation ($op) received with file name $polFile and options $option"
       ;;
esac

echo "$(date +"%Y-%b-%d %H:%M:%S") ltfsee_premig ended"
echo 
exit 0
