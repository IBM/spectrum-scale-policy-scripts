#!/bin/bash
################################################################################
# IBM Storage Scale
#
# (C) Copyright International Business Machines Corp. 2026
#
################################################################################
#
# Program: funcs-glacier.sh
#
# Description: 
# Script includes common functions and parameters and is sourced by other scripts
#
# Input:
# Parameters at the beginning of this scripts must be adjusted.
#
# Processing:
# sourced by other scripts 
#
# Output:
# Runtime information are written to standard out. 
#
#------------------------------------------------------------------------
# Change History
# 05/19/2026 first implementation 

#------------------------------------------
# The following parameters must be adjusted
#-----------------------------------------
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


#------------------------------------------
# The following parameters must not be changed
# - these parameters provide internal program controls
#-----------------------------------------
# migrate policy options
migPolOpts="-m 2 -B 1000 --single-instance"

# recall policy options
recPolOpts="-m 2 -B 1000 --single-instance"

# recall policy options
setAttrPolOpts="-m 2 -B 1000 --single-instance"

# migrate policy file name
migPol="$basePath/migrate.pol"

# recall policy file name
recPol="$basePath/recall.pol"

# recall program file name
recallProg="$basePath/recall.sh"

# setattr policy file name
setAttrPol="$basePath/setattr.pol"

# path and file name for the set attribute script
setAttrProg="$basePath/setattr.sh"

# name of restore request attribute
restoreAttrName="user.noobaa.restore.request"

# name of restore expiry date attribute
expireAttrName="user.noobaa.restore.expiry"

# GPFS bin path
gpfsPath="/usr/lpp/mmfs/bin"


#-------------------------------------------------
# function: check_config
#
# Checks common configuration parameters and assigns defaults when required
# 
# Return code:
# 0: check successful
# 1: checks failed
#
#-------------------------------------------------

function check_config()
{
    frc=0

    # check if s3Path is defined and exists
    if [[ ! -z $s3Path ]]; then
    if [[ ! -d $s3Path ]]; then
        echo "  ERROR: path $s3Path does not exist or file system is not mounted."
        frc=1
    fi
    else
      echo "  ERROR: parameter sPath is not set in $funcFile."
      frc=1
    fi

    # Set optional parameters
    # if fileset is not specified, then set fileset name to root for display purposes
    if [[ -z $fSet ]]; then
      fSet="root"
    fi

    # if a bucket is specified, then add the bucket name to the base object path
    if [[ -z $bucket ]]; then
      bucketPath=$s3Path
    else
      bucketPath=$s3Path/$bucket
    fi

    # if there is no node name, then set it to the local node
    if [[ -z $nodes ]]; then
      nodes=$($gpfsPath/mmlsnode -N localhost | awk '{print $1}' )
    fi

    return $frc
}