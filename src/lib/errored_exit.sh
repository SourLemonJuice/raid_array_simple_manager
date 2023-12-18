# errored_exit
# 如果上一个命令执行错误则以同样的报错码退出
llib_errored_exit(){
    _error_code=$?
    if [ ! $_error_code == 0 ];then
        echo "此前执行的命令执行错误 $_error_code"
        exit $_error_code
    fi
}
