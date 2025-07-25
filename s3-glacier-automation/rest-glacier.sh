#!/bin/bash
################################################################################
# The MIT License (MIT)                                                        #
#                                                                              #
# Copyright (c) 2025 Nils Haustein                             				   #
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
# Parameters at the beginning of this scripts must be adjusted.
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


#------------------------------------------
# static parameters - do not change
#------------------------------------------
# GPFS bin path
gpfsPath="/usr/lpp/mmfs/bin"

#------------------------------------------
# The following parameters must be adjusted
#-----------------------------------------
# base path where buckets and objects are stored
s3Path="/ibm/fs1/demo"

# fileset name when available, fileset path should correspond to s3Path. Leave blank if there is no fileset.
fSet="demo"

# bucket name
# when bucket is specified, then we scan the bucket only otherwise we scan the entire base object path ($s3Path)
bucket="glacier"

# path where the scripts and policies are located:
scriptPath="/usr/local/bin"

# recall policy file name
recPol="$scriptPath/recall.pol"

# set attribute policy file name
attrPol="$scriptPath/setattr.pol"

# path and file name for the recall script
recallProg="$scriptPath/recall.sh"

# path and file name for the set attribute script
setAttrProg="$scriptPath/setattr.sh"

# node names that can execute the policy, these nodes must have the scripts installed
#   when "" then the local node is used
#   multiple nodes are separated with comma and no blanks, e.g., node1,node2
#   all refers to all nodes
nodes=""


#----------------------------------
# Main
#---------------------------------

# Set optional parameters
# if there is no fileset, then use root as fileset name
if [[ -z $fSet ]]; then
  fSet="root"
fi

# if there is no node name, then set it to the local node
if [[ -z $nodes ]]; then
  nodes=$($gpfsPath/mmlsnode -N localhost | awk '{print $1}' )
fi

# if a bucket is specified, then add the bucket name to the base object path
if [[ -z $bucket ]]; then
  bucketPath=$s3Path
else
  bucketPath=$s3Path/$bucket
fi


echo "$(date) Invoking Glacier restore on nodes $nodes for fileset $fSet"


# if there is no fileset, then use root as fileset name
if [[ -z $fSet ]]; then
  fSet="root"
fi

echo "INFO: Starting recall for $s3Path"
$gpfsPath/mmapplypolicy $s3Path -P $recPol --single-instance -M FSET=$fSet -M BUCKET=$bucketPath -M PROG=$recallProg -N $nodes
rc=$?

echo -e "\n\nINFO: recall finished"
echo -e "======================================================================================\n"

sleep 5

echo "INFO: Starting setting object restore attribute on nodes $nodes for fileset $fSet "
$gpfsPath/mmapplypolicy $s3Path -P $attrPol --single-instance -M FSET=$fSet -M BUCKET=$bucketPath -M PROG=$setAttrProg -N $nodes
(( rc=rc+$? ))


echo -e "\n\n$(date) Glacier restore finished rc=$rc"


