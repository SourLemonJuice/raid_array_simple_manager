# raid_array_simple_manager

这是一个用`mdadm`来简单控制raid阵列的bash脚本\
这只是一些简单操作的合集，但这些操作在真正用的时候总是记不住所以拿来写一个脚本加强记忆和方便操作

> 数据无价，阵列再怎么校验也挡不住用户瞎搞

## 配置

在使用前需要配置一些信息

```shell
#!/bin/bash

# 配置
Raid_Name='/dev/md/test'
Raid_Devices=('/dev/sda' '/dev/sdb')
```

- `Raid_Name`: 阵列路径\
  可以填写阵列设备号(/dev/md0)，或者带阵列名的连接(/dev/md/test)
- `Raid_Devices`: 阵列所用的设备路径\
  需要设备路径用来在停止阵列时待机磁盘

## 使用

```shell
[lemon@linux ~]: ./main.sh help
help | info | status | mount | stop | check
```

### 1.info

打印配置的阵列详细信息

```shell
mdadm -D $Raid_Name
```

### 2.status

用来打印所有阵列设备的状态

```shell
cat /proc/mdstat
```

### 3.mount

组装和挂载阵列

```shell
mdadm --assemble $Raid_Name
mount $Raid_Name
```

### 4.stop

停止阵列，**并且使用`hdparm`待机硬盘**\
执行后会提示:

```shell
这项操作可能非常危险，要确定吗[y/n]
```

### 5.check

执行阵列检查，用来找出错误的块\
检查后坏块的数量: `/sys/blo.../md/mismatch_cnt`

[ArchWiki[en] RAID#Scrubbing](https://wiki.archlinux.org/title/RAID#Scrubbing)

```shell
Raid_BlockNum=$(basename $Raid_Name)
echo check >/sys/block/${Raid_BlockNum}/md/sync_action
```
