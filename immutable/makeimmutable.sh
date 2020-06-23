#! /bin/ksh
################################################################################
# The MIT License (MIT)                                                        #
#                                                                              #
# Copyright (c) 2020 Nils Haustein                             				   #
#                                                                              #
# Permission is hereby granted, free of charge, to any person obtaining a copy #
# of this software and associated documentation files (the "Software"), to deal#
# in the Software without restriction, including without limitation the rights #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell    #
# copies of the Software, and to permit persons to whom the Software is        #
# furnished to do so, subject to the following conditions:                     #
#                                                                              #
# The above copyright notice and this permission notice shall be included in   #
# all copies or substantial portions of the Software.                          #
#                                                                              #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER       #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,#
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE#
# SOFTWARE.                                                                    #
################################################################################

# Program: makeimmutable.sh
#
# Description: 
#-------------
# Interface script for LIST policy invoked by mmapplypolicy 
# Sets selected files to immutable with retention time given in policy.
#
# Prerequisite:
#-------------
# EXTERNAL list policy that identifies files that are not immutable.
#
# Input:
#-------
# invoked by mmapplypolicy with the following parameters:
# $1 operation (list, test)
# $2 file system name or name of filelist
# $3 optional parameter defined in LIST policy under OPTS, defines retention period in days relative to current date
#
# Output:
#--------
# Sets files identified to immutable with retention period define in policy (default is defined as $DEFRETTIME
# Write runtime information and debugging messages to log file $LOGFILE
#
# Example Policy:
#-----------------
#/* define exclude list */
#define(  exclude_list,
#  (PATH_NAME LIKE '%/.SpaceMan/%' OR
#   PATH_NAME LIKE '%/.ltfsee/%' OR
#   PATH_NAME LIKE '%/.mmSharedTmpDir/%' OR
#   PATH_NAME LIKE '%/.snapshots/%' OR
#   NAME LIKE '.mmbackupShadow%' OR
#   NAME LIKE 'mmbackup%')
#/* define immutable attribute */
#define( immutable, MISC_ATTRIBUTES LIKE '%X%')
#/* define external list with makeimmutable.sh script to set mp3 files in fileset 'worm' to immutable with 1 day retention */
#RULE EXTERNAL LIST 'setmp3' EXEC '/root/silo/makeimmutable.sh' OPTS '1'
#RULE 'mp3' LIST 'setmp3' FOR FILESET ('worm') WHERE NOT (exclude_list) and NOT (immutable) and (NAME LIKE '%.mp3')
#
# Invokation:
#-------------
# mmapplypolicy fsname -P policyfile [-N nodenames -m threads -B bucketsize]
#    Policy file must include a policy as shown above.
#
# Change History
#----------------
# 10/09/12 first implementation based on startbackup
# 12/20/15 implementation for immutability, some streamlining of existing code
# 06/22/20 minor adjustments

#----------------------------------
#These parameters can be adjusted
#-----------------------------------
# define the path for the log file
MYPATH="./makeimmutable/"
# logfile used for system_log function, logs are appended
LOGFILE=$MYPATH"makeimmutable.log"
# sets the log level for the system log, everything below that number is logged
LOGLEVEL=1
# default retention time
DEFRETTIME=0

#----------------------------------
# Constants
#----------------------------------
# GPFS path name to be used with all GPFS commands
gpfsPath="/usr/lpp/mmfs/bin"


## Append to the system log
## Usage: system_log <log_level> <log_message>
system_log () {
  SEV=$1

  case $SEV in
    [0-9]) ;;
    *)    SEV=1;;
  esac
    
  LINE=$2
  if [ $LOGLEVEL -ge $SEV ] ; then
    if [[ -z "$LINE" ]]; then
	  echo -e "INTERNAL WARNING: Improper value given to system_log function ($@)" >> $LOGFILE
	else
      echo -e "$LINE" >> $LOGFILE
	fi
  fi
}

## Print a message to the stdout
## Usage: user_log <log_message>
user_log () {
    echo -e "Makeimmutable $@"
}


## Get current date and time
## Usage: get_cur_date_time 
get_cur_date_time(){
  echo "$(date +"%Y-%b-%d %H:%M:%S")"
}

#++++++++++++++++++++++++++ MAIN ++++++++++++++++++++++++++++++++++++++
user_log "$(get_cur_date_time) makeimmutable invoked by policy engine"

# check the path for logging
if [[ ! -d $MYPATH ]] then
  mkdir -p $MYPATH
  rc=$?
  if (( rc > 0 )) then
    user_log "ERROR: failed to create directory $MYPATH, check permissions"
	exit 1
  fi
fi

system_log 1 "========================================================================="
system_log 1 "$(get_cur_date_time) makeimmutable invoked with arguments: $*"

## Parse Arguments & execute
#$1 is the policy operation (list, migrate, etc) 
op=$1
#$2 is the policy file name
polFile=$2
#$3 is the option given in the EXTERNAL LIST rule with OPTS '..' should be retention time here  
retTime=$3
    
## this is required, as the script may be called multiple times during
## the same backup (if there are too many files to process).

case $op in 
  TEST ) 
       user_log "INFO: TEST option received for directory $polFile."
	   system_log 1 "INFO: TEST option received for $polFile"
	   if [[ ! -z "$polFile" ]] then
	     if [[ -d "$polFile" ]] then
		   user_log "INFO: TEST directory $polFile exists."
		   system_log 1 "INFO: Directory $polFile exists."
		 else
		   user_log "WARNING: TEST directory $polFile does not exists."
		   system_log 1 "WARNING: Directory $polFile does not exist."
		 fi
	   fi
       ;;
  LIST )
       user_log "INFO: LIST option received, starting makeimmutable task"
	   system_log 1 "INFO: LIST option received with file name $polFile and options $retTime"
        
       #set retention time to default if not set
       if [[ -z $retTime ]] then 
	      retTime=$DEFRETTIME
	   fi
	   
	   itemNum=0
       
	   numEntries=$(wc -l $polFile | awk '{print $1}')
	   system_log 1 "INFO: setting retention time $retTime day(s) for $numEntries files"
	   #consider a function for this
       cat $polFile | while read line 
	   do
		 # use set to get file name, does tolerate blanks
		 set $line
		 shift 4
		 fName="$*"
		 
         rc=0  
		 # perhaps check if file exists
		 if [[ ! -a $fName ]] then
		   system_log 1 "WARNING: file $fName does not exist."
		   user_log "DEBUG: file $fName does not exist."
		 else 
           $gpfsPath/mmchattr -E $(date +%Y-%m-%d@%H:%M:%S -d "$DATE + $retTime day") "$fName"
           rc=$?
           if (( rc == 0 )) then
              $gpfsPath/mmchattr -i yes "$fName"
		     (( rc=rc+$? ))
           fi
		   if (( rc == 0 )) then
		     system_log 1 "INFO: Retention time $retTime for file $fName set successful."
			 user_log "INFO: Retention time $retTime for file $fName set successful."
		   else
		     system_log 1 "WARNING: Setting retention time $retTime for file $fName failed (rc=$rc)"
			 user_log "WARNING: Setting retention time $retTime for file $fName failed (rc=$rc)"
		   fi
		 fi
		 (( itemNum=itemNum+1 ))
       done
	   system_log 1 "INFO: retention time set for $itemNum out of $numEntries files"
	   user_log "INFO: retention time set for $itemNum out of $numEntries files"
       ;;
  REDO )
       user_log "INFO: REDO option received, doing nothing"
	   system_log 1 "INFO: REDO option received with file name $polFile and options $retTime"
       ;;
  * )
       user_log "WARNING: Unknown option $op received, doing nothing"
	   system_log 1 "WARNUNG: UNKNOWN option ($op) received with file name $polFile and options $retTime"
       ;;
esac

user_log "$(get_cur_date_time) makeimmutable ended"
system_log 1 "$(get_cur_date_time) makeimmutable ended"

exit 0