#!/bin/bash
# 
#  Program name: runpolicy
# Description: run a policy to a given file system with a given policy file
# Author: N. Haustein
#

LOGLEVEL=1
MMAPPLYPOLICY_OPTS="-m 3 -N all -n 1 --single-instance"
DEFAULT_FSDIR="/mnt/userfs/"
DEFAULT_PFILE="./policyfile"
DEFAULT_EEPOOL="mpool"
mode=$1
fs=$2
pol=$3
pool=$4
hostname=$(hostname)

syntax ()
{ 
   echo "SYNTAX: runpolicy mode [filesystem] [policyfile] [pool]"
   echo "        mode      : test|run, mandatory parameter"
   echo "        filesystem: GPFS file system and directory subject for the policy run"
   echo "                    (default: $DEFAULT_FSDIR)"
   echo "        policyfile: name of the file including the policy"
   echo "                    (default: $DEFAULT_PFILE"
   echo "        pool:       name of the tape storage pool(s), multiple enclosed in quotes"
   echo "                    (default: $DEFAULT_EEPOOL)"
   echo 
   exit 1
}

#**************  MAIN **************************
echo "====================================================="
echo "INFO: $(date +"%d/%m/%y %H:%M:%S") Starting policy on $hostname"

if [[ "$mode" = "test" || "$mode" = "run" ]]; then
   if [ "$mode" = "run" ]; then
     mode=yes
   fi
   MMAPPLYPOLICY_OPTS="-I $mode "$MMAPPLYPOLICY_OPTS
else
  echo "ERROR: policy run mode not or wrong specified ($mode)"
  syntax
fi
if [ -z "$fs" ]; then
  fs=$DEFAULT_FSDIR
fi
if [ ! -d "$fs" ]; then
  echo "ERROR: filesystem $fs does not exist"
  syntax
fi

if [ -z "$pol" ]; then
  pol=$DEFAULT_PFILE
fi
if [ ! -f $pol ]; then
  echo "ERROR: policy file $pol does not exist."
  syntax
fi
if [ -z "$pool" ]; then
   pool="$DEFAULT_EEPOOL"
fi

echo "INFO: running policy on file system $fs with policyfile $pol to pool $pool."

#mmapplypolicy $fs -P $pol "$MMAPPLYPOLICY_OPTS"  -M "LASTRUNDATE=$LASTRUNDATE" -M "LASTRUNTIME=$LASTRUNTIME" -L $LOGLEVEL
echo "DEBUG: mmapplypolicy $fs -P $pol "$MMAPPLYPOLICY_OPTS" -M "FILESYSTEM=$fs"%"" -M "EEPOOL=$pool" -L $LOGLEVEL"
mmapplypolicy $fs -P $pol $MMAPPLYPOLICY_OPTS -M "FILESYSTEM=$fs%" -M "EEPOOL=$pool" -L $LOGLEVEL
rc=$?
if (( rc > 0 )); then
  echo "ERROR: mmapplypolicy returned an error (rc=$rc)"
fi

echo "INFO: $(date +"%d/%m/%y %H:%M:%S") Finishing policy on $hostname"
exit $rc

