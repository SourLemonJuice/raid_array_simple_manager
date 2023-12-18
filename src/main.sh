#!/bin/bash

# 配置
Raid_Name=('/dev/md/test')
Raid_Devices=('/dev/sda' '/dev/sdb')

# 加载依赖
source ./lib/errored_exit.sh || llib_errored_exit
source ./lib/prompts_need_perm.sh || llib_errored_exit

# 检查权限
llib_prompts_need_perm 1 0

# 主程序
case $1 in

    info)
        mdadm -D $Raid_Name
    ;;
    umount)
        # 为了不让 input 变量留到下面，所以在子shell里运行
        (
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
        )

        echo '即将卸载文件系统'
        umount $Raid_Name
        echo '即将关闭阵列'
        mdadm --stop $Raid_Name
        echo "即将 待机设备 ${Raid_Devices[@]}"
        hdparm -y
    ;;
    *)
        echo '非法参数'
        exit 1
    ;;

esac

exit 0
