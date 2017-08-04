#!/bin/bash


# callback script for softQuotaExceeded event
# catches the event, creates a list of files for the subject fileset according to thresholds and migrates this list of files
# this event is triggered on the file system manager, so the script must run on a file system manager
# if file system managers cannot do the migration then use a node class ($nodeClass) to propagate this to another set of nodes
#
# To setup the callback:
# mmaddcallback SOFTQUOTA-MIGRATION --command /path/callback-quota.sh --event softQuotaExceeded --parms "%eventName %fsName %filesetName"
#
# This script must be installed on all manager nodes that can become file system manager in the path given in the callback (--command)
# The policies referenced ($listpol, $migpol) must be installed in the path referenced by $workDir on all nodes who can perform the migration
#
# !!!! Use on your own risk, no guarantee and no liability !!!
#

# static variables, adjust these when required
# the workdir must exist on all manager nodes who can become file system manager
workDir=/root/silo
outfile=$workDir"/qFiles"
# the policy files must be accessible on all nodes
listpol=$workDir"/list.pol"
migpol=$workDir"/mig.pol"
# the log directory must exist
logDir="/var/log/callback"
# The log file is appended to, you have to take care of logfile rotation
logF=$logDir"/quota-callback.log" # note you have to take care of logfile rotation

# set the node class, if the migration needs to run on a special set of node
nodeClass="all"

# assign parameters given to the script 
evName=$1
fsName=$2
fsetName=$3

# check if logDir exists
if [[ ! -d "$logDir" ]];
then
  echo "ERROR: logging directory $logDir does not exist. exiting." 
  exit 1
fi
if [[ ! -d "$workDir" ]];
then
  echo "ERROR: working directory $workDir does not exist. exiting." 
  exit 1
fi

# present a banner
echo "==============================================================================" >>  $logF
echo "$(date) Program $0 started on $(hostname)" | tee -a  $logF
echo "------------------------------------------------------------------------------"  >> $logF

#check parameters given to the script
if [[ -z $evName ]];
then
  echo "ERROR: event name not specified."  | tee -a $logF
  echo "Syntax: $0 event-name filesystem-name fileset-name" >> $logF
  exit 1
fi
if [[ -z $fsName ]];
then
  echo "ERROR: filesystem name not specified."  | tee -a $logF
  echo "Syntax: $0 event-name filesystem-name fileset-name" >> $logF
  exit 1
fi
if [[ -z $fsetName ]];
then
  echo "ERROR: fileset name not specified."  | tee -a $logF
  echo "Syntax: $0 event-name filesystem-name fileset-name"  >> $logF
  exit 1
fi

echo "INFO: received event $evName for file system $fsName and fileset $fsetName"  | tee -a $logF

# determine the node to run this command based on node class and node and file system state
localNode=$(mmlsnode -N localhost | cut -d'.' -f1)
echo "INFO: local node is: $localNode" >> $logF
allNodes=""
sortNodes=""
# if node class is set up determine node names in node class
if [[ ! -z $nodeClass ]];
then
   echo "INFO: node class to select the node from is: $nodeClass" >> $logF
   allNodes=$(mmlsnodeclass $nodeClass -Y | grep -v HEADER | cut -d':' -f 10 | sed 's|,| |g')
   if [[ -z $allNodes ]]
   then
     echo "WARNING: node class $nodeClass is empty, using local node" >> $logF
     sortNodes=$localNode
   else
     # reorder allNodes to have localNode first, if it exists
     for n in $allNodes;
     do
       if [[ "$n" == "$localNode" ]];
       then
         sortNodes=$localNode" "$sortNodes
       else
         sortNodes=$sortNodes" "$n
       fi
     done
   fi
else
   # if no node class is defined set the local node 
   sortNodes=$localNode
fi

# select the node to execute the command based on state 
echo "INFO: The following nodes are checked to run the operation: $sortNodes" >> $logF
execNode=""
for n in $sortNodes;
do
  # determine node state
  state=$(mmgetstate -N $n -Y | grep -v ":HEADER:" | cut -d':' -f 9)
  if [[ "$state" != "active" ]];
  then
	continue
  else 
	# determine file system state on node
	mNodes=$(mmlsmount $fsName -Y | grep -v HEADER | grep -E ":RW:" | cut -d':' -f 12)
	for m in $mNodes;
	do
	  if [[ "$m" == "$n" ]];
	  then
		execNode=$m
      fi		
	done
	if [[ ! -z "$execNode" ]];
	then
	  break
	fi
  fi
done

if [[ -z "$execNode" ]];
then
  echo "ERROR: no node is in appropriate state to run the job, exiting." | tee -a $logF
  exit 1
else
  echo "INFO: Selected node for execution is: $execNode" | tee -a $logF
fi


# set the name of the output file to qfiles-fsname-fsetname
outfile=$outfile"-"$fsName"-"$fsetName


# delete last output file and invoke list policy
echo "INFO: running list policy for filesystem $fsName and file set $fsetName on node $execNode" >> $logF
ssh $execNode "rm -f $outfile.list.softquota" >> $logF 2>&1
ssh $execNode "rm -f $outfile.list" >> $logF 2>&1
ssh $execNode "mmapplypolicy $fsName -P $listpol -f $outfile -M FSETNAME=$fsetName --single-instance -I defer"  >> $logF 2>&1  

#check if the outfile exists and run the MIGRATE policy on $execNode
ssh $execNode "ls $outfile.list.softquota" >> $logF 2>&1 
rc=$?
if (( rc != 0 ));
then 
  echo >> $logF
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >> $logF
  echo "WARNING: no outputfile ($outfile) has been created, skipping migration." | tee -a $logF
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" >> $logF
else
  # adjusting the output file by extracting the path and filenames
  ssh $execNode "cut -d' ' -f7-20 $outfile.list.softquota > $outfile.list" >> $logF 2>&1
  echo >> $logF
  echo "INFO: running migration from list file on node $execNode." >> $logF
  ssh $execNode "mmapplypolicy $fsName -P $migpol --single-instance -M FSETNAME=$fsetName -i $outfile.list" >> $logF 2>&1
fi

echo >> $logF
echo "INFO: $(date) Program finished on node $localNode executing on node $execNode" | tee -a $logF
echo >> $logF

exit 0

