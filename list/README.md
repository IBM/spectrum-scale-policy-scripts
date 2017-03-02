# List policy script

## Description:
This script is a wrapper to run custom LIST policies. The list policy files are installed in the same path as the script `list.sh`. The list policy files have a specific naming convention with the "operation code" in the file name. The list policy script is invoked with the "operation code" that executes the underlying policy file and prints the selected files to STDOUT.

## Prerequisite:
1. Create a custom list policy where the EXTERNAL LIST RULE name is identical to a operation code. See examples below.
2. Store this list policy in a file with the operation code within the file name: `listpol_<op-code>.txt`
3. Store the file in the same directory as the script. Alternatively change the variable `$pfPrefix` in the script to reflect the correct path.

## Invocation:
```
list.sh <op-code> <fspath>
```

- *op-code* is the name of the policy to be executed according to the above naming conventions
- *fspath* is the file system or directory path subject for the list policy

## Processing:
The script checks if the list policy file exists, executes the LIST policy using `mmapplypolicy` and lists the files matching the rule. The output files are written to `/tmp/gpfs.list.<op-code>` and stored there until the next run.

Note that the directory of the output files can be changed in the script by the variable `$ofPrefix`.

## Output:
File identified by the policy engine are listed on STDOUT according to the policy engine format.
Output files including these files are stored in `/tmp/gpfs.list.<op-code>`

## Examples:

### LIST policy to identify all migrated files, copy and paste this to file listpol_mig.txt

```
/* Define exclude list to exclude SpaceMan and snapshots */
define( exclude_list,(PATH_NAME LIKE '%/.SpaceMan/%' OR PATH_NAME LIKE '%/.snapshots/%') )
/* Define is migrated */
define( is_migrated,(MISC_ATTRIBUTES LIKE '%V%') )
/* list rule to list all migrated files */
RULE EXTERNAL LIST 'mig' EXEC ''
RULE 'list_mig' LIST 'mig' WHERE ( is_migrated )  AND ( NOT (exclude_list) )
```

Execution: `list.sh mig /<fspath>`

Output file name: `/tmp/gpfs.list.mig`

### LIST policy to identify all premigrated files, copy and paste this to file listpol_pmig.txt

```
/* Define exclude list to exclude SpaceMan and snapshots */
define( exclude_list,(PATH_NAME LIKE '%/.SpaceMan/%' OR PATH_NAME LIKE '%/.snapshots/%') )
/* Define is premigrated */
define( is_premigrated,(MISC_ATTRIBUTES LIKE '%M%' AND MISC_ATTRIBUTES NOT LIKE '%V%') )
/* list rule to list all premigrated files */
RULE EXTERNAL LIST 'pmig' EXEC ''
RULE 'list_pmig' LIST 'pmig' WHERE ( is_premigrated )  AND ( NOT (exclude_list) )
```

Execution: `list.sh pmig /<fspath>`

Output file name: `/tmp/gpfs.list.pmig`

### LIST policy to identify all resident files, copy and paste this to file listpol_res.txt

```
/* Define exclude list to exclude SpaceMan and snapshots */
define( exclude_list,(PATH_NAME LIKE '%/.SpaceMan/%' OR PATH_NAME LIKE '%/.snapshots/%') )
/* Define is resident */
define( is_resident,(MISC_ATTRIBUTES NOT LIKE '%M%') )
/* list rule to list all resident files */
RULE EXTERNAL LIST 'res' EXEC ''
RULE 'list_res' LIST 'res' WHERE ( is_resident )  AND ( NOT (exclude_list) )
```

Execution: `list.sh res /<fspath>`

Output file name: `/tmp/gpfs.list.res`

### LIST policy to identify files in resident, migrated and premigrated state in a summary view, copy and paste this to file listpol_res.txt

```
/* Define exclude list to exclude SpaceMan and snapshots */
define( exclude_list,(PATH_NAME LIKE '%/.SpaceMan/%' OR PATH_NAME LIKE '%/.snapshots/%') )
/* Define is migrated */
define( is_migrated,(MISC_ATTRIBUTES LIKE '%V%') )
/* list rule to list all migrated files */
RULE EXTERNAL LIST 'mig' EXEC ''
RULE 'list_mig' LIST 'mig' WHERE ( is_migrated )  AND ( NOT (exclude_list) )
/* Define is premigrated */
define( is_premigrated,(MISC_ATTRIBUTES LIKE '%M%' AND MISC_ATTRIBUTES NOT LIKE '%V%') )
/* list rule to list all premigrated files */
RULE EXTERNAL LIST 'pmig' EXEC ''
RULE 'list_pmig' LIST 'pmig' WHERE ( is_premigrated )  AND ( NOT (exclude_list) )
/* Define is resident */
define( is_resident,(MISC_ATTRIBUTES NOT LIKE '%M%') )
/* list rule to list all resident files */
RULE EXTERNAL LIST 'res' EXEC ''
RULE 'list_res' LIST 'res' WHERE ( is_resident )  AND ( NOT (exclude_list) )
```

Execution: `list.sh all /<fspath>`

Output file names: `/tmp/gpfs.list.res`, `/tmp/gpfs.list.mig`, `/tmp/gpfs.list.pmig`
