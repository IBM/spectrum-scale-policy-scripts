#! /bin/ksh
################################################################################
# The MIT License (MIT)                                                        #
#                                                                              #
# Copyright (c) 2019 Nils Haustein                             				   #
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
# Program: ltfsee_recall
#
# Description: 
# Interface script for MIGRATE policy invoked by mmapplypolicy 
# Invokes ltfsee recall -l libname filelist
#
# Prerequisite:
# EXTERNAL pool policy that identifies files to be recalled.
#
# Input:
# invoked by mmapplypolicy with the following parameters:
#   $1 operation (migrate, test)
#   $2 file system name or name of filelist
#   $3 library name
#
# Output:
# Writes runtime information to STDOUT - ends up in mmapplypolicy output
#
# Example Policy:
# /* define path name pattern for the file to be recalled */
# define(recall_dir, (PATH_NAME LIKE '%'))
# /* define external pool with customized interface script and target library for recall*/
# RULE 'extpool' EXTERNAL POOL 'ltfs' EXEC '/path/ltfsee_recall.sh' OPTS 'eelib1'
# /* define migration rule to recall all migrated files matching the path pattern*/
# RULE 'recall' MIGRATE FROM POOL 'ltfs' TO POOL 'system' FOR FILESET ('swr') WHERE 
#(XATTR('dmapi.IBMPMig') IS NULL) AND NOT (XATTR('dmapi.IBMTPS') IS NULL) and (recall_dir)
#
# Invokation:
# mmapplypolicy fsname -P policyfile
#
# Change History
# 10/09/12 first implementation based GAD startbackup
# 12/20/15 implementation for immutability, some streamlining of existing code
# 12/21/15 create the general receiver
# 09/01/17 ltfsee recall

#global variables for this script
# set the default option in case $3 is not give, allows to specify the library name
DEFOPTS=""
# define ltfsee directory
LTFSEEDIR=/opt/ibm/ltfsee/bin

#++++++++++++++++++++++++++ MAIN ++++++++++++++++++++++++++++++++++++++
echo "================================================================================================"
echo "$(date +"%Y-%b-%d %H:%M:%S") ltfsee_recall.sh invoked with arguments: $*"

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
  RECALL | MIGRATE | LIST )
  # this is the actual migrate call where we call ltfsee premigrate
       echo "INFO: $op option received with file name $polFile and options $option"
       #set option to default if not set
       if [[ -z $option ]] then 
	     if [[ -z $DEFOPTS ]] then
		   echo "ERROR: Library name not specified in the external pool rule."
		   exit 1
		 else
	      option=$DEFOPTS
		 fi
	   fi
	   
	   echo "INFO: Start processing files $polFile with ltfsee recall from library $option"
	   $LTFSEEDIR/ltfsee recall -l $option $polFile  
	   rc=$?
       if (( rc != 0 )) then
         echo "WARNING: ltfsee recall ended with return code $rc"	
       fi		 
       ;;
  REDO )
	   echo "INFO: REDO option received with file name $polFile and options $option"
       ;;
  * )
	   echo "WARNING: UNKNOWN operation ($op) received with file name $polFile and options $option"
       ;;
esac

echo "$(date +"%Y-%b-%d %H:%M:%S") ltfsee_recall ended"
echo 
exit 0
