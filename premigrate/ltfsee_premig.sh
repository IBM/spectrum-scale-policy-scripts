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
#   $3 target for migration as pool@library name 
#
# Output:
# Writes runtime information to STDOUT - ends up in mmapplypolicy output
#
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
# 06/23/20 adopt to eeadm command, improve messaging

#global variables for this script
# set the default option in case $3 is not give, allows to specify the pool in the syntax "-p pool@lib", just in case the pool is not set in the external pool definition of the migrate policy
DEFOPTS=""
# define ltfsee directory
LTFSEEDIR=/opt/ibm/ltfsee/bin

#++++++++++++++++++++++++++ MAIN ++++++++++++++++++++++++++++++++++++++
echo "================================================================================================"
echo "$(date +"%Y-%b-%d %H:%M:%S") LTFSEE_PREMIG invoked with arguments: $*"

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
       echo "LTFSEE_PREMIG INFO: TEST option received for $polFile"
	   if [[ ! -z "$polFile" ]] then
	     if [[ ! -d "$polFile" ]] then
		   echo "LTFSEE_PREMIG WARNING: TEST directory $polFile does not exists."
		 fi
	   fi
	   ;;
  MIGRATE )
  # this is the actual migrate call where we call ltfsee premigrate
       echo "LTFSEE_PREMIG INFO: MIGRATE option received with file name $polFile and options $option"
       #set option to default if not set
       if [[ -z $option ]] then 
	     if [[ -z $DEFOPTS ]] then
		   echo "LTFSEE_PREMIG ERROR: Pool name not specified in the external pool rule."
		   exit 1
		 else
	      option=$DEFOPTS
		 fi
	   fi
	   
	   echo "LTFSEE_PREMIG INFO: Start processing files $polFile with ltfsee premigrate to pool $option"
	   $LTFSEEDIR/eeadm premigrate $polFile $option 
	   rc=$?
       if (( rc != 0 )) then
         echo "LTFSEE_PREMIG WARNING: ltfsee premigrated ended with return code $rc"	
       fi		 
       ;;
  REDO )
	   echo "LTFSEE_PREMIG INFO: REDO option received with file name $polFile and options $option"
       ;;
  * )
	   echo "LTFSEE_PREMIG WARNING: UNKNOWN operation ($op) received with file name $polFile and options $option"
       ;;
esac

echo "$(date +"%Y-%b-%d %H:%M:%S") LTFSEE_PREMIG ended"
echo 
exit 0
