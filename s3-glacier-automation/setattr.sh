#! /bin/ksh
################################################################################
# IBM Storage Scale
#
# (C) Copyright International Business Machines Corp. 2026
#
################################################################################
#
# Program: setAttr.sh
#
# Description: 
# Interface script for LIST policy invoked by mmapplypolicy 
# Sets the user.noobaa.restore.expiry attribute and removes the user.noobaa.restore.request atttibute
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
# calculate the expiration time based on user.noobaa.restore.request attribute
# sets the expiration time in user.noobaa.restore.expiry attribute
# deletes user.noobaa.restore.request attribute
#
# Output:
# written to standard out
#
# Change History
# 6.5.2024 first implementation based on receiver script
# 05/19/26 remove logging into log files - output written to STDOUT
# 09/10/26 tolerate multiple blanks when processing filenames


#Program specific global vars:
#------------------------------
# global vars
restoreAttrName="user.noobaa.restore.request"
expireAttrName="user.noobaa.restore.expiry"
gpfsPath="/usr/lpp/mmfs/bin"

# default value of restore.requet days
reqDaysDefault=1

#===================================================================================
# Main
#===================================================================================
echo -e "\n========================================================================="
echo "$(date) $0 invoked with parameters: $*"

## Parse Arguments & execute
#$1 is the policy operation (list, migrate, etc) 
op=$1
#$2 is the policy file name
polFile=$2
#$3 is the option given in the EXTERNAL LIST rule with OPTS '..' should be retention time here  
option=$3

### Respond to the operation invoked by the policy engine
#this is required, as the script may be called multiple times during
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
       echo "INFO: LIST option received, starting setExpire task"
	   
	   # process the files
	   itemNum=0
       numEntries=$(wc -l $polFile | awk '{print $1}')
	   echo "INFO: Start processing $numEntries files"
	   cat $polFile | while IFS= read -r line; 
	   do
		# tolerate file names with multiple blanks
         fName="${line#*-- }"

		 # get restore.request days
		 reqDays=$($gpfsPath/mmlsattr -n $restoreAttrName "$fName" | grep "$restoreAttrName" | cut -d'"' -f 2)
		 if [[ -z $reqDays ]]; then
		   echo "  DEBUG: value for attribute $restoreAttrName of filename $fName is emtpy. Setting default $reqDaysDefault days"
		   reqDays=$reqDaysDefault
		 fi 
		 
		 # calculate expiration time
		 expDate=$(date +"%Y-%m-%dT%H:%M:%S.000Z" -d "$DATE + $reqDays day")
		 
		 # set expiration time
		 if ! $gpfsPath/mmchattr --set-attr $expireAttrName="$expDate" "$fName" 2>&1; then
		   echo "  ERROR: setting attribute $expireAttrName=$expDate for $fName"
		   (( rc += 1 ))
         fi

		 # remove restore attr
		 if ! $gpfsPath/mmchattr --delete-attr $restoreAttrName "$fName" 2>&1; then 
		   echo "  ERROR: deleting attribute $restoreAttrName for $fName"
		   (( rc += 1 ))
         fi
		 
		 ((itemNum=itemNum+1))
	   done

	   echo "INFO: Processed $itemNum out of $numEntries files (rc=$rc)";;

  REDO )
       echo "INFO: REDO option received, doing nothing";;

  * )
       echo "WARNING: Unknown option $op received, doing nothing";;
esac

echo "$(date) $0 finished (rc=$rc)"
echo -e "=========================================================================\n"
exit $rc