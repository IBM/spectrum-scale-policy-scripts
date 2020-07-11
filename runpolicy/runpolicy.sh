#!/bin/bash
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
# Program name: runpolicy.sh
#
# Author: N. Haustein
# 
# Description: 
# Wrapper for mmapplypolicy 
#
# Prerequisite:
# policy file must exist and must be correct
# when required add optional parameters for mmapplypolicy
#
# Syntax:
# runpolicy mode filesystem policyfile [opts]
#   filesystem: GPFS file system and directory subject for the policy run
#   policyfile: name of the file including the policy 
#   opts      : options for mmapplypolicy, such as -I yes -m 3 -n 1 --single-instance -M param=value" (optional). Default options can be set with script parameter DEFAULT_OPTS
# Note, the sequence of the parameters matters. If not mmappylpolicy options are defined the policy is run in test mode. Specify other run mode explicitely with -I
#
# Output:
# writes STDOUT and STDERR to console
#
# Change history
#-----------------
# 07/06/20 streamlining, allow to specify mmapplypolicy parameters 
#

# adjustable parameters
# ---------------------
# default options for mmapplypolicy in case there are options specified with the runpolicy.sh command
DEFAULT_OPTS="-m 3 -n 1 --single-instance"


# Parameter assignment
# --------------------
#mode=$1
fs=$1
pol=$2
# we assign opts later
opts=""

hostname=$(hostname)
LOGLEVEL=1
MMAPPLYPOLICY_OPTS=""


syntax ()
{ 
   echo "SYNTAX: runpolicy filesystem-directory policyfile [opts]"
   echo "        filesystem: GPFS file system path and directory subject for the policy run (mandatory)"
   echo "        policyfile: name of the file including the policy (mandatory)"
   echo "        opts      : options for mmapplypolicy, such as II <mode> -m -n --single-instance -M param=value (optional)"
   echo ""
   echo "        Note: The sequence of parameters matters. File system path has to come first, followed by policyfile."
   echo "              The default run mode is test. If you want to run the policy specify -I yes for MIGRATE policies "
   echo "              or -I defer -f /tmp/prefix for list policies as parameter opts. "
   echo 
   exit 1
}

#**************  MAIN **************************
echo "====================================================="
echo "RUNPOLICY INFO: $(date +"%d/%m/%y %H:%M:%S") Starting policy on $hostname"

# check if file system was specified and check if path exists
if [[ -z "$fs" ]]; then
  echo "RUNPOLICY ERROR: filesystem not specified."
  syntax
elif [[ ! -d "$fs" ]]; then
  echo "RUNPOLICY ERROR: filesystem $fs does not exist."
  syntax
fi

# check if policyfile was specified and exists
if [[ -z "$pol" ]]; then
  echo "RUNPOLICY ERROR: policy file $pol not specified."
  syntax
elif [[ ! -f $pol ]]; then
  echo "RUNPOLICY ERROR: policy file $pol does not exist."
  syntax
fi

# we have file system name and policy file, now lets assign the rest of the options
# all the rest of the parameters are considered for mmapplypolicy (no parsing)
shift 2
opts="$*"

# assign mmapplypolicy options
if [[ ! -z "$opts" ]]; then
  MMAPPLYPOLICY_OPTS="$opts"
else
  if [[ ! -z "$DEFAULT_OPTS" ]]; then
    MMAPPLYPOLICY_OPTS="$DEFAULT_OPTS"
  else
    echo "RUNPOLICY INFO: not further mmapplypolicy options specified."
  fi
fi 
echo "RUNPOLICY DEBUG: MMAPPLYPOLICY_OPTS=$MMAPPLYPOLICY_OPTS"

# if -I is specified in the options with -I then use this, otherwise set -I test
if [[ -z $(echo $MMAPPLYPOLICY_OPTS | grep "\-I ") ]]; then
  echo "RUNPOLICY DEBUG: setting run mode to: test."
  MMAPPLYPOLICY_OPTS=" -I test "$MMAPPLYPOLICY_OPTS
else 
  echo "RUNPOLICY DEBUG: run mode was set as parameter ($MMAPPLYPOLICY_OPTS)."
fi

echo "RUNPOLICY INFO: running policy on file system $fs with policyfile $pol and options: $MMAPPLYPOLICY_OPTS."

#mmapplypolicy $fs -P $pol "$MMAPPLYPOLICY_OPTS"  -M "LASTRUNDATE=$LASTRUNDATE" -M "LASTRUNTIME=$LASTRUNTIME" -L $LOGLEVEL
# echo "RUNPOLICY DEBUG: mmapplypolicy $fs -P $pol "$MMAPPLYPOLICY_OPTS" "
mmapplypolicy $fs -P $pol $MMAPPLYPOLICY_OPTS 
rc=$?
if (( rc > 0 )); then
  echo "RUNPOLICY ERROR: mmapplypolicy returned an error (rc=$rc)"
else
  echo "RUNPOLICY INFO: mmapplypolicy succeeded (rc=$rc)"
fi

echo "RUNPOLICY INFO: $(date +"%d/%m/%y %H:%M:%S") Finishing policy on $hostname"
exit $rc
