#!/usr/bin/env bash

read_value=""

## 根据提示，读取用户输入
# $1 提示信息
# #2 value 的合法值的正则形式
# $3 默认值
function readInput(){
    read_value=""

    tip_msg="$1"
    value_regex="$2"
    default_value="$3"

    until  [[ $read_value =~ $value_regex ]];do
        read -p "${tip_msg}" read_value;read_value=${read_value:-$default_value}
    done
}

### shell 不能返回字符串，需要设置一个全局变量，函数里面修改全局变量的值
# read_value=""

#readInput "请输入 Port,  默认 22  :"  "^([0-9]{1,4}|[1-5][0-9]{4}|6[0-5]{2}[0-3][0-5])$" "22"
#echo " port : $read_value"
#
#readInput "请输入 api :" "^([0-9a-zA-Z]+)$"
#echo " port : $read_value"