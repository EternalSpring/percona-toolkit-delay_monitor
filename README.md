# percona-toolkit-delay_monitor
采用PT工具，脚本监控主从库之间的同步延时


db_permissions.sql  主从监控权限脚本
slave_info.cnf      主从同步配置文件
delay_monitor.sh    延时监控脚本
software            pt 安装包
start.txt           pt启动指令


crontab 设置
*/5 * * * * sh /root/delay_monitor.sh  /root/delay_monitor.cnf> /dev/null 2>&1
定时执行扫描监控设置
