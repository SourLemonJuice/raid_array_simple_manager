#!/bin/bash

# 配置
Raid_Name='/dev/md/test'
Raid_Devices=('/dev/sda' '/dev/sdb')

# 获取脚本所在的真实路径 (函数)
llib_script_realpath(){
    # 用dirname截取脚本所在路径的纯路径，而非带有文件名的位置信息
    # 不然就退出
    cd $(dirname $0) || exit 1
    # 然后输出出去
    pwd
}

# 主程序 (函数)
main(){
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
            # 获取设备编号
            Raid_BlockNum=$(basename $Raid_Name)
            # 以防万一检测一遍在执行
            [[ -f /sys/block/${Raid_BlockNum}/md/sync_action ]] || llib_errored_exit
            # 提示信息
            echo "检查会耗时很久的哦，没事不要乱用"
            echo "8秒后向 /sys/block/${Raid_BlockNum}/md/sync_action 写入 check"
            sleep 8
            # 执行
            echo check > /sys/block/${Raid_BlockNum}/md/sync_action
            # 向这个文件输入 idel 可以安全的暂停检查，重启也同样会安全暂停并在开机时继续
        ;;
        help)
            echo "help | info | status | mount | stop | check"
        ;;
        *)
            echo '非法参数'
            exit 1
        ;;

    esac
}

# 加载依赖
script_realpath=$(llib_script_realpath)
source $script_realpath/lib/errored_exit.sh || exit 1
source $script_realpath/lib/prompts_need_perm.sh || exit 1

# 这些操作很危险，永远不要相信用户的输入，数据无价。

# 将阵列名转换为设备编号而非有名称的链接，并检查他们是否存在
# 使用 (realpath -e) 是因为这样只解析存在的路径或文件，否则会报错
Raid_Name=$(realpath -e $Raid_Name)
llib_errored_exit

# 检查 Raid_Devices 是否存在且为块设备
for i in ${Raid_Devices[@]}; do
    [[ -b $i ]] || llib_errored_exit
done
# 删除临时变量
unset -v "i"

# 检查权限
llib_prompts_need_perm 1 0
# 主函数
main $@
# 无事发生就以0退出
exit 0
