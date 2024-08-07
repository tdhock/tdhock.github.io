---
layout: post
title: How reproducible are benchmarks?
description: Comparing atime results on different computers
---

[data.table](https://github.com/rdatatable/data.table) is an R package
for efficient data manipulation.  I have an NSF POSE grant about
expanding the open-source ecosystem of users and contributors around
`data.table`.  Part of that project is benchmarking time and memory
usage, and comparing with similar packages. This post is based on [a
previous post](https://tdhock.github.io/blog/2024/collapse-reshape/),
and the goal is to see how reproducible those results are, between
different computers.

## Background about atime

TODO

## CPUs to compare

On my old MacBook (~2008) running Ubuntu Jammy, `cat /proc/cpuinfo` says: "Intel(R)
Core(TM)2 Duo CPU P7350 @ 2.00GHz."

TODO windows.

## wide compare

![plot of chunk atime-wide-win-new](/assets/img/2024-08-06-atime-different-cpu/atime-wide-win-new.png)

![plot of chunk atime-wide-linux-old](/assets/img/2024-08-06-atime-different-cpu/atime-wide-linux-old.png)

TODO

## agg compare

![plot of chunk atime-agg-win-new](/assets/img/2024-08-06-atime-different-cpu/atime-agg-win-new.png)

![plot of chunk atime-agg-linux-old](/assets/img/2024-08-06-atime-different-cpu/atime-agg-linux-old.png)

TODO

## cpu details

```
$ cat /proc/cpuinfo
processor	: 0
vendor_id	: GenuineIntel
cpu family	: 6
model		: 23
model name	: Intel(R) Core(TM)2 Duo CPU     P7350  @ 2.00GHz
stepping	: 6
microcode	: 0x60c
cpu MHz		: 1591.913
cache size	: 3072 KB
physical id	: 0
siblings	: 2
core id		: 0
cpu cores	: 2
apicid		: 0
initial apicid	: 0
fpu		: yes
fpu_exception	: yes
cpuid level	: 10
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ht tm pbe syscall nx lm constant_tsc arch_perfmon pebs bts rep_good nopl cpuid aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm sse4_1 lahf_lm pti tpr_shadow vnmi flexpriority vpid dtherm
vmx flags	: vnmi flexpriority tsc_offset vtpr vapic
bugs		: cpu_meltdown spectre_v1 spectre_v2 spec_store_bypass l1tf mds swapgs itlb_multihit mmio_unknown
bogomips	: 3979.77
clflush size	: 64
cache_alignment	: 64
address sizes	: 36 bits physical, 48 bits virtual
power management:
```
