# 检测并提示提示用户需要别的权限
# 依赖: errored_exit
# (应用/用户)权限 == Permissions == perm
# 参数:
# $1 == Switch( * || 1 )(default on == 1)
# $2 == User( username || 1000 )(default root == 0 )
llib_prompts_need_perm(){
    _Switch=1
    [[ ! -z $1 ]] && _Switch=$1

    _User=0
    [[ ! -z $2 ]] && _User=$2

    _User_id=$(id -u ${_User})
    llib_errored_exit

    # 检测权限
    if [[ $_Switch -eq 1 ]];then

        if [[ ! $(id -u) -eq $_User_id ]];then
            echo "需要 ${_User} 的权限执行"
            exit 1
        fi
    fi
}
