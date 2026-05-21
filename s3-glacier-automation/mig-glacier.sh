#!/bin/bash
################################################################################
# IBM Storage Scale
#
# (C) Copyright International Business Machines Corp. 2026
#
################################################################################
#
# Program: mig-glacier.sh
#
# Description: 
# Script to migrate S3 Glacier objects from a given directory or bucket.
#
# Input:
# Parameters at the beginning of this scripts must be adjusted.
#
# Processing:
# Executes the migrate.pol that identifies and migrates all Glacier objects in the given scope 
#
# Output:
# Runtime information are written to standard out. 
#
#------------------------------------------------------------------------
# Change History
# 23.7.25 first implementation 
# 05/19/26 moved global paramters to funcs-glacier.sh


funcFile="funcs-glacier.sh"

#---------------------------------------
# Main
#---------------------------------------

### determine directory where the script is started from
basePath=$(dirname $0)
if [[ $basePath = "." ]]; then
  basePath=$PWD
fi
# echo "DEBUG: base path for $0: $basePath"

### source common functions
if [[ -a $basePath/$funcFile ]]; then
  . $basePath/$funcFile
else
  echo "  ERROR: common functions in file $funcFile not found in $basePath."
  exit 1 
fi

### check parameters 
echo "INFO: Checking configuration parameters."
if ! check_config; then
  exit 2
fi

### further checks on migration specific parameters
# check if $tapePool is set
if [[ -z $tapePool ]]; then
  echo "  ERROR: tape pool parameter not set in $funcFile."
  rc=1
fi
# check if migPol parameter and file exist
if [[ ! -z $migPol ]]; then
  if [[ ! -a $migPol ]]; then
    echo "  ERROR: Migration policy file $migPol does not exist."
    exit 2
  fi
else
  echo "  EEROR: parameter migPol is not defined in $funcFile."
  exit 2
fi


### adjust the policy: if not fileset is given, then remove the FOR FILESET clause
if [[ $fSet == "root" ]]; then
  fsetClause=""
else
  fsetClause="FOR FILESET('$fSet')"
fi

# print banner
echo "$(date) Invoking Glacier migration policy on nodes $nodes for fileset $fSet and bucket $bucket to tapepool $tapePool"

# run the policy
$gpfsPath/mmapplypolicy $s3Path -P $migPol $migPolOpts -M TAPEPOOL="$tapePool" -M FILESETCLAUSE="$fsetClause" -M BUCKET="$bucketPath" $tFlag -N "$nodes"
rc=$?

echo -e "\n\n$(date) Glacier migration finished (rc=$rc)"

exit $rc


