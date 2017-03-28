#! /bin/bash

#
# flexible framework to run list policies
# - create a list policy where the external rule name is identical to the op-code given to this program
# - the op-code given to this program is the first argument
# - the policy file must include the op-code in the filename: listpol_<op-code>.txt
# - this policy file is stored in the path configurable below ($pfPrefix)
# - run the program with the state: list.sh <state> <fspath>
# - optional argument -v allows to show verbose output (file names)
# - optional argument -s <workDir> allows to set the working directory for the policy engine output files
#

# ADJUST define pathname and prefix for policy files
# policy file must be named: $pfPrefix_$op.txt
pfPrefix="./listpol"

# define local work directory for mmapplypolicy and output files, default is /tmp
workDir="/tmp"

# ADJUST define file system name
fsName=""

# define output format: 0 - number of files only; 1 - filenames
numbersOnly=1


#function syntax
function syntax
{
  echo
  echo "Syntax: list state filesystem [-v -s workDir]"
  echo "This program lists the files according to the HSM state, Valid states are:"
  echo "  mig:        list all migrated files"
  echo "  pmig:       list all premigrated files"
  echo "  res:        list all resident files"
  echo "  all:        provides statistic about all states"
  echo
  echo "  Filesystem: is the name of the file system or directory"
  echo "  -v:         shows the file names selected by the policy (default is number of files)"
  echo "  -s workDir: specify the working directory for the policy engine output files (default is $workDir)"
  echo
}

#set number format
export LC_NUMERIC="en_US.UTF-8"

#check first argument to be state
if [[ -z "$1" ]];
then
  echo "Error: state not specified."
  syntax
  exit 1
else
  op=$1
fi

# second argument must be file system path
if [[ -z "$2" ]];
then
  echo "Error: file system not specified"
  syntax
  exit 1
else
  fsName=$2
  if [[ ! -d $fsName ]];
  then
    echo "Error: file system $fsName does not exist."
	syntax
	exit 1
  fi
fi

# now parse the rest of the arguments
shift 2
# echo "DEBUG: args=$*"

while [[ ! -z "$1" ]];
do
  case "$1" in
  "-v") numbersOnly=0;;
  "-s") shift 1
        workDir=$1
		if [[ ! -d "$workDir" ]];
		then
		   echo "Error: working directory specified by -s $workDir does not exist."
		   syntax
		   exit 1
		fi ;;
  *)    echo "Error: Unknown Argument received ($1). "
        syntax
		exit 1;;
  esac
  shift 1
done

#define prefix for policy output file
#policy output file is named: $ofPrefix.list.$op
ofPrefix="$workDir""/gpfs"

#define logfile name
logfile="$workDir""/gpfslist_mmapply.log"


#check if policy file exists
polfile="$pfPrefix""_""$op"".txt"
# echo "DEBUG: policy file name is: $polfile"
if [[ ! -a $polfile ]];
then
  echo "ERROR: Policyfile $polfile does not exist in $pfPrefix. Provide the file or use correct state."
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
mmapplypolicy $fsName -P $polfile -s $workDir -f $ofPrefix -I defer > $logfile
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
		  size=0
		else
		  num=$(wc -l $outfile | awk '{print $1}')
		  size=$(awk '{sum += $4/(1024^3)} END {print sum}' $outfile)
		fi
		printf "  Number of files with state $s:  %7s  %.2f GB  (filename: $outfile)\n" $num $size
	 done
  else
    #create name of policy output file
    outfile="$ofPrefix"".""list"".""$op"
    # echo "DEBUG: out file name is: $outfile"
	if (( numbersOnly ));
	then
	  num=$(wc -l $outfile | awk '{print $1}')
	  size=$(awk '{sum += $4/(1024^3)} END {print sum}' $outfile)
	  printf "  Number of files with state $op:  %7s  %.2f GB  (filename: $outfile)\n" $num $size
	else
      cat $outfile
	  echo "---------------------------------------------------------------------------"
	  echo "INFO: See file $outfile"
	  echo "---------------------------------------------------------------------------"
	fi
  fi
else
  echo "ERROR: mmapplypolicy returned error (rc=$rc), check log ($logfile)"
fi

exit 0
