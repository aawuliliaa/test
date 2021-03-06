#!/bin/bash
##############################################################
# File Name: install-lnmp.sh
# Version: V1.0
# Author: vita
# Organization: 
# Created Time : 2019-04-01 22:02:03
# Description:
##############################################################
source /etc/init.d/functions
playbookPath="/etc/ansible/playbook/qimo-homework"
ansibleHostsDir=/etc/ansible/hosts 
ansibleHostsDirBak=/etc/ansible/hosts.bak
###判断输入是否为空
isNull() {
    [ -z "$1" ]&&{
    action "you must input something!" /bin/false
    exit
    } 
}
###判断输入是否为数字
isNotNum() {
    expr $1 + 2 &>/dev/null
    [ $? -ne 0 ]&&{
        action "you can just input one number!" /bin/false
        exit
    }
}
###判断输入是否是IP，是IP返回1
isIpOrNot() {
    ##用于判断IP地址是否在0.0.0.0-255.255.255.255间，如果是，返回1，否则返回0
    return $(echo "$1"|grep -E '^([0-9]{1}|[1-9]{2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1}|[1-9]{2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1}|[1-9]{2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1}|[1-9]{2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$'|wc -l)
}
###该函数传两个参数，
###第一个用于匹配/etc/ansible/hosts文件，所以输入里面的[]host组名
###第二个参数是安装目录，用于判断软件是否已经安装
###这里采用备份，还原hosts文件的方式，并没有直接在原来的文件上修改
###用于判断hosts文件中的主机是否已经安装了相关软件，如果已经安装了，就不在安装，没有安装的也会进行提示
isInstalledOrNot() {
    mv  $ansibleHostsDir $ansibleHostsDirBak
    sed -rn "/$1/,/^\[/p" $ansibleHostsDirBak|grep -Ev '^#|^$'>$ansibleHostsDir
    hosts=$(egrep '^([0-9]{1,3}\.){3}([0-9]{1,3})$' $ansibleHostsDir)
    for host in $hosts;do
       echo "*******start to identify $host*******"
       installedOrNot=$(ansible $host -m shell -a "[ -d "$2" ]&&echo 1||echo 0"|tail -1)
       if [ "$installedOrNot" == "1" ];then
            sed -i "s/$host/#$host/g" /etc/ansible/hosts
            action "$host has already installed $1" /bin/false
            continue
        
        elif [ "$installedOrNot" == "0" ];then
            action "$host has not installed $1,you will install $1 " /bin/true
        else
            action "there is some error acces to $host!" /bin/false
       fi

    done
}
###恢复ansible的Hosts文件
recoverAnsibleHostsDir() {
    rm -rf $ansibleHostsDir
    mv $ansibleHostsDirBak $ansibleHostsDir
}
###查看/etc/ansible/hosts文件。用于查看是否还有主机没被注释，
###如果所有的都被注释了，说明都安装了，就提示不需要安装了
###否则就在没被注释的机器上安装相关软件
listHost() {
    return $(egrep '^([0-9]{1,3}\.){3}([0-9]{1,3})$' $ansibleHostsDir|wc -l)

}
installMysql() {
    isInstalledOrNot mysql "/application/mysql"
    listHost
    if [ $? -eq 0 ];then
        echo "==============there is not host for you to install mysql==================="
    else
        echo "==============start to install mysql=================="
#       ansible-playbook $playbookPath/4-mysql.yaml 2>&1 ./log/installMysql.log &
        echo "==============install mysql finished=================="
    fi
    recoverAnsibleHostsDir
    exit
}
installPhp() {
    isInstalledOrNot php "/application/php"
    listHost
    if [ $? -eq 0 ];then
        echo "==============there is not host for you to install php==================="
    else
        echo "==============start to install php=================="
#       ansible-playbook $playbookPath/5-php.yaml 2>&1 ./log/installPhp.log &
        echo "==============install php finished=================="
    fi
    recoverAnsibleHostsDir
    exit
}
installNginx() {
     isInstalledOrNot nginx "/application/nginx"
     listHost
     if [ $? -eq 0 ];then
        echo "==============there is not host for you to install nginx==================="
     else
        echo "==============start to install nginx=================="
#       ansible-playbook $playbookPath/6-nginx.yaml 2>&1 ./log/installNginx.log &
        echo "==============install nginx finished=================="
     fi
    recoverAnsibleHostsDir
    exit
}
###判断reinstall中输入的IP是否符合要求
judgeIp() {
    yourIp="$1"
    reinstallServer="$2"
    if [ ! -z "$yourIp" ];then
        for ip in $yourIp;do
            isIpOrNot $ip
            if [ $? -eq 1 ];then
                echo "ip-$ip is valuable"
            else
                echo "ip-$ip is invalid,you should input again!"
                exit
            fi
        done
        mv $ansibleHostsDir $ansibleHostsDirBak
        echo "[$reinstallServer]">$ansibleHostsDir
        for ip in $yourIp;do
            echo $ip>>$ansibleHostsDir
        done
    fi
}
reinstallMysql() {
    yourInputIp="$1"
    [ ! -z "$yourInputIp" ]&&{
    judgeIp "$yourInputIp" "mysql"
    }
    echo "==================start to reinstall mysql================="
#       ansible-playbook $playbookPath/4-mysql.yaml 2>&1 ./log/installMysql.log &
    echo "==================reinstall mysql ended===================="
    [ ! -z "$yourInputIp" ]&&{
    recoverAnsibleHostsDir
    }
    exit
}
reinstallPhp() {
    yourInputIp="$1"
    [ ! -z "$yourInputIp" ]&&{
    judgeIp "$yourInputIp" "php"
    }
    echo "==================start to reinstall php================="
#       ansible-playbook $playbookPath/5-php.yaml 2>&1 ./log/installphp.log &
    echo "==================reinstall php ended===================="
    [ ! -z "$yourInputIp" ]&&{
    recoverAnsibleHostsDir
    }
    exit
}
reinstallNginx() {
    yourInputIp="$1"
    [ ! -z "$yourInputIp" ]&&{
    judgeIp "$yourInputIp" "nginx"
    }
    echo "==================start to reinstall nginx================="
#       ansible-playbook $playbookPath/6-nginx.yaml 2>&1 ./log/installnginx.log &
    echo "==================reinstall nginx ended===================="
    [ ! -z "$yourInputIp" ]&&{
    recoverAnsibleHostsDir
    }
    exit
}
reinstallChose() {
    yourChose=$1
    yourInputIp="$2"
    case $yourChose in
        1)
            reinstallMysql "$yourInputIp"
            ;;
        2)
            reinstallPhp "$yourInputIp"
            ;;
        3)
            reinstallNginx "$yourInputIp"
            ;;
        4)
            exit
            ;;
        *)
            echo "you can only input [1|2|3]!"
    esac

}
reinstall() {
cat <<EOF
1.reinstall mysql
2.reinstall php
3.reinstall nginx
4.exit
message:
you can also input which host to reinstall
if you do not input ip,you will reinstall certain server at  cetain module list in /etc/ansible/hosts file
EOF
    read -p "which do you want to reinstall,:" yourNumber yourIp
    isNull "$yourNumber"
    isNotNum "$yourNumber"
    reinstallChose "$yourNumber" "$yourIp"
}
install() {
    case $1 in 
        1)
            installMysql
            ;;
        2)
            installPhp
            ;;
        3)
            installNginx
            ;;
        4)
            reinstall
            ;;
        5)
            exit
            ;;
        *)
            action "you can just input [1-5]!"
    esac
}
main(){
cat <<EOF
what do you want to do?
1.install mysql
2.install php
3.install nginx
4.reinstall
5.exit
EOF
    read -p "please input one number as list above:" yourChose
##之所以用“”把变量括起来，是因为当传值为23 2时，给函数传值，$1就是23了
    isNull "$yourChose"
    isNotNum "$yourChose"
    install $yourChose
}
main
