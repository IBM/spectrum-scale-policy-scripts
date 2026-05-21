#!/bin/bash
################################################################################
# IBM Storage Scale
#
# (C) Copyright International Business Machines Corp. 2026
#
################################################################################
#
# Program: rest-glacier.sh
#
# Description: 
# Script to restore S3 Glacier objects that have a restore request. Runs in two phases
# 1. Identify all Glacier objects that have a restore request and recall those 
#    using an EXTERNAL LIST policy recall.pol that invokes the external script recall.sh
# 2. Identify all Glacier objects that have a restore request and were recalled 
#    and set the file attributes using an EXTERNAL LIST policy setattr.pol that invokes the external script setattr.sh
# 
# Input:
# Sourced from funcs-glacier.sh
#
# Processing:
# Executes the recall.pol policy and subsequently executes the setattr.pol policy
#
# Output:
# Runtime information are written to standard out. 
#
#------------------------------------------------------------------------
# Change History
# 23.7.25 first implementation 
# 05/19/26 moved global paramters to funcs-glacier.sh


funcFile="funcs-glacier.sh"

#----------------------------------
# Main
#---------------------------------

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

### further checks on restore specific parameters
# check that recall and setAttr policy and programs exist in $basePath
for f in $recPol $recallProg $setAttrPol $setAttrProg; do
  if [[ ! -z $f ]]; then
    if [[ ! -a $f ]]; then
    echo "  ERROR: File $f does not exist."
    exit 2
  fi
  else
    echo "  ERROR: parameter $f is not defined in $funcFile."
    exit 2
  fi
done

### adjust the policy: if not fileset is given, then remove the FOR FILESET clause
if [[ $fSet == "root" ]]; then
  fsetClause=""
else
  fsetClause="FOR FILESET('$fSet')"
fi

### start the recall
echo "$(date) Invoking Glacier restore on nodes $nodes for fileset $fSet and bucket $bucket"

# if there is no fileset, then use root as fileset name
if [[ -z $fSet ]]; then
  fSet="root"
fi

echo "INFO: Starting recall for $s3Path"
$gpfsPath/mmapplypolicy $s3Path -P $recPol $recPolOpts -M FILESETCLAUSE="$fsetClause" -M BUCKET="$bucketPath" -M PROG="$recallProg" -N "$nodes" $tFlag
rc=$?

echo -e "\n\nINFO: recall finished (rc=$rc)"
echo -e "======================================================================================\n"

sleep 5


### start setAttr
echo "INFO: Starting setting object restore attribute on nodes $nodes for fileset $fSet "
$gpfsPath/mmapplypolicy $s3Path -P $setAttrPol $setAttrPolOpts -M FILESETCLAUSE="$fsetClause" -M BUCKET="$bucketPath" -M PROG="$setAttrProg" -N "$nodes" $tFlag
(( rc=rc+$? ))


echo -e "\n\n$(date) Glacier restore finished rc=$rc"

exit $rc


