#!/bin/bash
################################################################################
# IBM Storage Scale
#
# (C) Copyright International Business Machines Corp. 2026
#
################################################################################
#
# Program: migrate-normal.sh
#
# Description: 
# Executes migration policy migrate.pol
#
# Input:
# Parameters at the beginning of this scripts must be adjusted.
#
# Processing:
# Executes the policy engine with policy file migrate.pol
#
# Output:
# Runtime information are written to standard out. 
#
#------------------------------------------------------------------------
# Change History
# 10/30/2026 first implementation 


#======================================================================
#
# Adjust the following parameters
#
#----------------------------------------------------------------------
# base path where buckets and objects are stored (required)
# this can either be the file system path or a fileset path
s3Path="/ibm/archfs/buckets"

# fileset name (optional) 
# if $s3Path is a fileset path, then enter the fileset name here., Otherwise, leave this blank
fSet="buckets"

# bucket name (optional)
# when specified, the scope for file processing is limited to $s3Path/$bucket. The $bucket parameter must be a subdirectory underneath $s3Path
bucket="test"

# tape pool name
tapePool="pool1@lib1"

# defines node names that can execute the policy, these nodes must have the scripts installed
#   when "" then the local node is used
#   multiple nodes are separated with comma and no blanks, e.g., node1,node2
#   all refers to all nodes
nodes=""

# specify the -I flag for the policy engine (mmapplypolicy) 
# if tFlag="", then the policy is executed. If tFlag="-I test" then the policy is tested, migration and recalls are not executed
tFlag=""


#----------------------------------------------------------------------
# Global parameter - may not have to be changed
#----------------------------------------------------------------------
polFile="./migrate.pol"
gpfsPath="/usr/lpp/mmfs/bin"


#======================================================================
# Main
#----------------------------------------------------------------------

echo "$(date) Invoking migration policy for fileset $fSet and bucket $bucket to tapepool $tape Pool on nodes $nodes"


if [[ ! -a $polFile ]]; then
  echo "ERROR: Policy file $polFile does not exist."
  exit 1
fi

if [[ -z $bucket ]]; then
  bucketPath=$s3Path
else
  bucketPath=$s3Path/$bucket
fi

if [[ -z $nodes ]]; then
  nodes=$($gpfsPath/mmlsnode -N localhost | awk '{print $1}' )
fi

$gpfsPath/mmapplypolicy $s3Path -P $polFile --single-instance -N $nodes -M TAPEPOOL=$tapePool -M FSET=$fSet -M BUCKET=$bucketPath $tFlag 
rc=$?

echo -e "\n\n$(date) migration finished rc=$rc"

exit $rc