# Recall policy

## Description
TBD

## Recommended usage

```
# mmapplypolicy <fsname> -P recpol.txt -N node1,node2 -m 4 –B 1000 -s <local-work-dir> [-I test]
```

`-m 4 (ThreadLevel)`
If you have two HSM nodes recalling the actual data, this will result in ~8 tape mounts on the TSM server. However, this number is not guaranteed... So we will need to monitor TSM server activity and potentially adjust this setting.

`‐B 1000 (MaxFiles)`
A batch size of 1000-2000 files is probably the minimum, and will only make sense for fewer large files. In directories with many small files I'd suggest to raise this parameter.
