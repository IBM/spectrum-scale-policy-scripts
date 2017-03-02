# Recall policy

## Description
The policy engine can be used to recall large numbers of files from an external pool, e.g. from tape. The policy file provided with this project can act as a template for performing such bulk recalls.

## Usage

1. Modify the sample policy `recpol.txt` to select the files you intend to recall. Line 14 in that policy contains the selection criteria:

   ```
   define(recall_dir, (PATH_NAME LIKE '/sample_fs/sample_dir/%'))
   ```

   Adjust the path as required.

2. Run the policy to recall the actual data:

   ```
   # mmapplypolicy <fsname> -P recpol.txt -N node1,node2 -m 4 –B 1000 -s <local-work-dir> [-I test]
   ```

   - `-N node1,node2`

     Specifies the HSM nodes or nodeclass to perform the policy scan, as well as the subsequent recall operation.

   - `-m 4 (ThreadLevel)`

     With two HSM nodes recalling the actual data, this will result in ~8 tape mounts on the TSM server. However, this number is not guaranteed... So you will need to monitor TSM server activity and potentially adjust this setting as required.

   - `‐B 1000 (MaxFiles)`

     A batch size of 1000-2000 files is probably the minimum, and will only make sense for fewer large files. In directories with many small files it is suggested to raise this parameter.

   - `-s <local-work-dir>`

     Provide a directory with sufficient capacity as scratch space for temporary data (e.g. file lists) used during the policy scan and recall operation.

   - `-I test`

     Optionally performs a dry-run (test) of the recall operation. This will evaluate the policy with the given path definition, and report on the amount of data which would be transferred. Remove this argument to perform the actual data recall.

3. It is recommended to create multiple copies of the `recpol.txt` file in order to recall independent batches of files as required.

## Further optimization

The HSM recall script which is shipped with (certain versions of) Spectrum Scale does not facilitate a Spectrum Protect tape-optimized recall by default. However, the script can be modified in order to optimize performance during bulk recalls using the policy engine.

Furthermore, bulk-recalls are most frequently used to ultimately recall data from external pools prior to a system migration, or in preparation of disabling HSM altogether. Performance can be improved in both such scenarios by recalling files into resident state. By default, files would be recalled into premigrated state - but the HSM recall script can be modified to recall data into resident state right away.

Both these modifications can be realized by applying the patch which is shipped with this project on all HSM nodes:

```
patch -b /usr/lpp/mmfs/samples/ilm/mmpolicyExec-hsm.sample mmpolicyExec-hsm.sample.patch
```

Subsequently, the name of the filesystem needs to be adapted in fore mentioned script. Simply search for `sample_fs` in a line starting with `$RecallFormat`. Replace `/sample_fs` with the actual mountpoint of the filesystem.

Note that this modification needs to be performed on each HSM node in order to enable Spectrum Protect tape-optimized recall operation.
