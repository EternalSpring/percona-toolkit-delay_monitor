#!/bin/sh

cd `dirname "$0"`/.
cur_path=`pwd`
logDir="${cur_path}/logs"
if [ ! -e ${logDir} ] ;then
      mkdir ${logDir}
fi

tmp_path="${cur_path}/tmp"
if [ ! -e ${tmp_path} ] ;then
      mkdir ${tmp_path}
fi
export WgetLog="${cur_path}/alarm_sms.log"
export WgetFile="${tmp_path}/.wget_file"

timestamp=`date '+%Y%m%d'`
monitor_delay_log="${logDir}/monitor_delay_log.log-${timestamp}"
if [ ! -e ${monitor_delay_log} ];then
    touch ${monitor_delay_log}
fi


#############################消息通知函数#####################################
SendNote() {
   wget -nv -t1 -O ${WgetFile} -a ${WgetLog} http://sendsms.do?appKey=dbmp_monitor\&msg="$1"
   sleep 2
   num=2
   until [ "$num" -gt 10 -o `cat ${WgetFile} |grep -i "ok" |wc -l` != 0 ]; do
       wget -nv -t1 -O ${WgetFile} -a ${WgetLog} http://sendsms.do?appKey=dbmp_monitor\&msg="$1"
           sleep 2
           num=$(($num + 1))
   done
   if [ `cat ${WgetFile} |grep -i "ok" |wc -l` = 0 ] ; then
       echo "send message fail, date:`date` message:$1" >> ${WgetLog}
       cat ${WgetFile}|grep -i "errmsg" >>  ${WgetLog}
   else
       echo "send message success, date:`date` message:$1" >> ${WgetLog}
   fi
return 0
}

############# delay monitor  ###########################################
delay_threshold_value=200          ########延时告警阀值(秒)
reboot_threshold_value=10        ########延时重启阀值(秒)
slave_info=$1
IPADDR="(`/sbin/ifconfig |grep 'inet addr'|awk -F':' '{print $2}'|awk '{print $1}'|head -1`)"
HOSTNAME=`hostname |sed -n 's/$//pg'`

cat ${slave_info} | grep -v "^#" | grep -v "^$" | while read  db_slave_ip db_slave_port db_slave_user db_slave_password master_server_id repl_info channel
do

####假定为四川-内蒙是双主同步,凡是 内蒙主 同步过来的,因为PT更新的主库是heartbeatnm,所以需要在对应从库上检查heartbeatnm表同步过来的时间戳时间,同理,凡是 四川主 同步过来的,从库上监控heartbeatsc表.
if [[ ${repl_info} = *"nm_master"*"->"* ]]
then
seconds_behind_master_tmp=`/opt/percona-toolkit-2.2.14/bin/pt-heartbeat -D ottermonitor --table heartbeatnm  --check -u${db_slave_user} -p${db_slave_password} -P${db_slave_port} -h${db_slave_ip} --master-server-id ${master_server_id}`
#echo "heartbeatnm ${repl_info}"
else
seconds_behind_master_tmp=`/opt/percona-toolkit-2.2.14/bin/pt-heartbeat -D ottermonitor --table heartbeat  --check -u${db_slave_user} -p${db_slave_password} -P${db_slave_port} -h${db_slave_ip} --master-server-id ${master_server_id}`
#echo "heartbeat ${repl_info}"
fi
###延时告警监控
seconds_behind_master=`echo ${seconds_behind_master_tmp%.*}`
minutes_behind_master=`expr ${seconds_behind_master} / 60`
if (( ${seconds_behind_master} > ${delay_threshold_value} ));then
     timestamp=`date '+%Y-%m-%d %H:%M:%S'`
     delay_msg="monitor:${repl_info}  delay_time:${minutes_behind_master}min  slave_db(${db_slave_ip}:${db_slave_port})  time:${timestamp} from:${IPADDR} "
     echo "${delay_msg}">>${monitor_delay_log}
     SendNote "${delay_msg}"
fi
###延时重启监控
if (( ${seconds_behind_master} > ${reboot_threshold_value} ));then
   #模拟登陆-获取用户cookie
   echo "login and try to reboot channel!  delay_time=${seconds_behind_master}s  channel=${channel}  repl_info=${repl_info}">>${monitor_delay_log}
   curl -i -s -d "action=user_action&event_submit_do_login=1&_fm.l._0.n=dba_lihch&_fm.l._0.p=dbalihch123" http://login.htm  -c /tmp/cookie>>${monitor_delay_log}
   #关闭channel
   echo "shutdown channel channel=${channel} repl_info=${repl_info}">>${monitor_delay_log}
   curl -i -s -d "action=channelAction&channelId=${channel}&status=stop&eventSubmitDoStatus=true" http://channel_list.htm   -b /tmp/cookie>>${monitor_delay_log}
   #开启channel
   echo "start channel channel=${channel} repl_info=${repl_info}">>${monitor_delay_log}
   curl -i -s -d "action=channelAction&channelId=${channel}&status=start&eventSubmitDoStatus=true" http://channel_list.htm   -b /tmp/cookie>>${monitor_delay_log}
  #SendNote “monitor:try to reboot channel:${channel}! delay_time:${minutes_behind_master}min  ${repl_info} time:${timestamp} from:${IPADDR}"
fi

done
