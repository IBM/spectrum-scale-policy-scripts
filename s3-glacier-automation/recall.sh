#! /bin/ksh
################################################################################
# IBM Storage Scale
#
# (C) Copyright International Business Machines Corp. 2026
#
################################################################################
#
# Program: recall.sh
#
# Description: 
# Interface script for LIST policy invoked by mmapplypolicy 
# Performs recall of files provided in filelist 
#
# Prerequisite:
# EXTERNAL list policy that identifies files that must be processed
#
# Input:
# invoked by mmapplypolicy with the following parameters:
# $1 operation (list, test)
# $2 file system name or name of filelist
# $3 optional parameter defined in LIST policy under OPTS
#
# Processing:
# recalls files in file list
#
# Output:
# written to standard out
#
# Change History
# 7.5.2024 first implementation based on receiver script
# 05/19/26 remove logging into log files - output written to STDOUT


#Program specific global vars:
#------------------------------
# global vars
gpfsPath="/usr/lpp/mmfs/bin"
eePath="/opt/ibm/ltfsee/bin"


#===================================================================================
# Main
#===================================================================================
echo -e "\n========================================================================="
echo "$(date) $0 invoked with parameters $*"

## Parse Arguments & execute
#$1 is the policy operation (list, migrate, etc) 
op=$1
#$2 is the policy file name
polFile=$2
#$3 is the option given in the EXTERNAL LIST rule with OPTS '..' should be retention time here  
option=$3
    
### Respond to the operation invoked by the policy engine
# this is required, as the script may be called multiple times during
rc=0
case $op in 
  TEST ) 
     echo "INFO: TEST option received for directory $polFile."
	   if [[ ! -z "$polFile" ]] then
	     if [[ -d "$polFile" ]] then
		     echo "  INFO: TEST directory $polFile exists."
       else
		     echo "  WARNING: TEST directory $polFile does not exists."
         rc=1
		   fi
     else
       echo "  WARNING: TEST directory parameter is empty."
       rc=1
	   fi;;

  LIST )
     echo "INFO: LIST option received, starting recall task"
	   
	   # process the files
	   recallRc=0
     numEntries=$(wc -l $polFile | awk '{print $1}')
	   echo "  INFO: Recalling $numEntries files"
     $eePath/eeadm recall $polFile
	   rc=$?
	   
	   # evaluate return code and log message
	   if (( rc > 0 )); then
	     echo "   WARNING: Recall ended with return code $rc"
	   fi;;

  REDO )
     echo "INFO: REDO option received, doing nothing";;

  * )
     echo "WARNING: Unknown option $op received, doing nothing";;
esac

echo "$(date) $0 finished (rc=$rc)"
echo -e "=========================================================================\n"
exit $rc