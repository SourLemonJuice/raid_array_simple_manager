#!/bin/bash

# 配置
Raid_Name='/dev/md/test'
Raid_Devices=('/dev/sda' '/dev/sdb')

# 加载依赖
source ./lib/errored_exit.sh || exit 1
source ./lib/prompts_need_perm.sh || exit 1

# 检查权限
llib_prompts_need_perm 1 0

# 主程序
case $1 in

    info)
        mdadm -D $Raid_Name
    ;;
    status)
        cat /proc/mdstat
    ;;
    stop)
        read -t 5 -p '这项操作可能非常危险，要确定吗[y/n]' input
        llib_errored_exit
        case $input in
            y | Y)
                :
            ;;
            *)
                echo '操作取消'
                exit
            ;;
        esac

        # 卸载文件系统
        echo '即将卸载文件系统'
        umount $Raid_Name
        llib_errored_exit

        # 关闭阵列
        echo '即将关闭阵列'
        mdadm --stop $Raid_Name
        llib_errored_exit
        echo '关闭命令执行结束'

        # 待机设备
        echo "即将 待机设备 ${Raid_Devices[@]}"
        hdparm -y ${Raid_Devices[@]}
        llib_errored_exit
    ;;
    mount)
        mdadm --assemble $Raid_Name
        mount $Raid_Name
    ;;
    check)
        echo idle > /sys/block/md0/md/sync_action
    ;;
    help)
        echo "help | info | status | mount | stop | check"
    ;;
    *)
        echo '非法参数'
        exit 1
    ;;

esac

exit 0
