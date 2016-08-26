#! /bin/bash
#
# flexible framework to run list policies
# - create a list policy where the external rule name is identical to the op-code given to this program
# - the op-code given to this program is the first argument
# - the policy file must include the op-code in the filename: listpol_<op-code>.txt
# - this policy file is stored in the path configurable below ($pfPrefix)
# - run the program with the state: list.sh <state> <fspath>
#

# ADJUST define pathname and prefix for policy files
# policy file must be named: $pfPrefix_$op.txt
pfPrefix="./listpol"

# ADJUST define file system name
fsName="/ibm/hsmdiv"

#define prefix for policy output file
#policy output file is named: $ofPrefix.list.$op
ofPrefix="/tmp/gpfs"

#define logfile name
logfile="/tmp/gpfs_mmapply.log"


#function syntax
function syntax 
{
  echo 
  echo "Syntax: list state filesystem"
  echo "This program lists the files according to the HSM state, Valid states are:"
  echo "  mig:    list all migrated files"
  echo "  pmig:   list all premigrated files"
  echo "  res:    list all resident files"
  echo "  all:    provides statistic about all states"
  echo 
  exit 1
}

#check arguments
if [[ -z "$1" ]]; 
then
  syntax
  exit 1
else
  op=$1
fi

if [[ -z "$2" ]]; 
then
  echo "Setting file system to default name: $fsName"
else
  fsName=$2
fi


#check if policy file exists
polfile="$pfPrefix""_""$op"".txt"
# echo "DEBUG: policy file name is: $polfile"
if [[ ! -a $polfile ]];
then
  echo "ERROR: Policyfile $polfile does not exist in $pfPrefix. Provide the file or use correct status."
  syntax
  exit 1
fi

#delete previous files to not get confused
for s in mig pmig res;
do
   outfile="$ofPrefix"".""list"".""$s"
   rm -f $outfile 2>&1
done

# if state=all then run run mmapplypolicy and subsequently determine the number of respective files

# run mmapplypolicy
mmapplypolicy $fsName -P $polfile -f $ofPrefix -I defer > $logfile
rc=$?
echo "=============================================================================="
if (( rc == 0 )); 
then
  echo "Files that are in state $op:"
  if [[ "$op" = "all" ]];
  then
     for s in mig pmig res;
	 do
	    outfile="$ofPrefix"".""list"".""$s"
		if [[ ! -a "$outfile" ]]; 
		then
		  num=0
		else
		   num=$(wc -l $outfile | awk '{print $1}')
		fi
		echo "  Number of files with state $s:  $num"
	 done
  else
    #create name of policy output file
    outfile="$ofPrefix"".""list"".""$op"
    # echo "DEBUG: out file name is: $outfile"
    cat $outfile;
  fi
else
  echo "ERROR: mmapplypolicy returned error (rc=$rc), check log ($logfile)"
fi

exit 0 
