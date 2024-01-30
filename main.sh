#!/bin/bash

# 配置
Raid_Name='/dev/md/test'
Raid_Devices=('/dev/sda' '/dev/sdb')

# errored_exit v2
# 如果上一个命令执行错误则以同样的报错码退出
llib_errored_exit() {
    _error_code=$?
    if [ ! $_error_code == 0 ]; then
        echo "此前执行的命令执行错误 错误码:$_error_code"
        exit $_error_code
    fi
}

# prompts_need_perm v2
# 检测并提示提示用户需要别的权限
# 依赖: errored_exit
# (应用/用户)权限 == Permissions == perm
# 参数:
# $1 == Switch( * || 1 )(default on == 1)
# $2 == User( username || 1000 )(default root == 0 )
llib_prompts_need_perm() {
    _Switch=1
    [[ ! -z $1 ]] && _Switch=$1

    _User=0
    [[ ! -z $2 ]] && _User=$2

    _User_id=$(id -u ${_User})
    llib_errored_exit

    # 检测权限
    if [[ $_Switch -eq 1 ]]; then

        if [[ ! $(id -u) -eq $_User_id ]]; then
            echo "需要 uid:${_User_id} 的权限执行"
            exit 1
        fi
    fi
}

# 主程序
main() {
    case $1 in

    info)
        mdadm -D $Raid_Name
        ;;
    status)
        cat /proc/mdstat
        ;;
    stop)
        read -t 5 -p '这项操作可能非常危险，要确定吗[y/N]' input
        # 如果时间到了没有输入则主动退出
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
        Raid_BlockNum=$(basename $Raid_Name_Num)
        # 以防万一检测一遍在执行
        [[ -f /sys/block/${Raid_BlockNum}/md/sync_action ]] || llib_errored_exit
        # 提示信息
        echo "检查会耗时很久的哦，没事不要乱用"
        echo "8秒后向 /sys/block/${Raid_BlockNum}/md/sync_action 写入 check"
        sleep 8
        # 执行
        echo check >/sys/block/${Raid_BlockNum}/md/sync_action
        # 向这个文件输入 idel 可以安全的暂停检查，重启也同样会安全暂停并在开机时继续
        ;;
    setTimeout)
        read -p "\"hdparm -S ?\":" Time_Out_value
        hdparm -S "$Time_Out_value" ${Raid_Devices[@]}
        ;;
    help)
        echo "help | info | status | mount | stop | check | setTimeout"
        ;;
    *)
        echo '非法参数'
        exit 1
        ;;

    esac
}

# 脚本从这里开始执行
# 这些操作很危险，永远不要相信用户的输入，数据无价。

# 将阵列名转换为设备编号而非有名称的链接，并检查他们是否存在
# 使用 (realpath -e) 是因为这样只解析存在的路径或文件，否则会报错
Raid_Name_Num=$(realpath -e $Raid_Name)
# 如果报错则给出提示，确保用户没有输错(阵列关闭了也没有块设备)
if [[ ! $? == 0 ]]; then
    read -t 5 -p '没有指定的块设备(可能是阵列已经关闭) 是否继续[y/N]' input
    # 如果时间到了没有输入则主动退出
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
fi

# 检查 Raid_Devices 是否存在且为块设备
for i in ${Raid_Devices[@]}; do
    [[ -b $i ]] || llib_errored_exit
done
# 删除临时变量
unset -v "i"

# 检查权限是否为 root(0)
llib_prompts_need_perm 1 0
# 主函数
main $@
# 无事发生就以0退出
exit 0
