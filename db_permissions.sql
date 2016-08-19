te database delaymonitor;
CREATE USER ''@'' IDENTIFIED BY '';
GRANT all privileges ON ottermonitor.* TO ''@'' IDENTIFIED BY '';
grant super on *.* to ''@'';
use ottermonitor;

CREATE TABLE heartbeatsc (ts varchar(26) NOT NULL,server_id int unsigned NOT NULL PRIMARY KEY,file varchar(255) DEFAULT NULL,position bigint unsigned DEFAULT NULL,relay_master_log_file varchar(255) DEFAULT NULL,exec_master_log_pos bigint unsigned DEFAULT NULL);

CREATE TABLE heartbeatnm (ts varchar(26) NOT NULL,server_id int unsigned NOT NULL PRIMARY KEY,file varchar(255) DEFAULT NULL,position bigint unsigned DEFAULT NULL,relay_master_log_file varchar(255) DEFAULT NULL,exec_master_log_pos bigint unsigned DEFAULT NULL);

CREATE TABLE heartbeatgd (ts varchar(26) NOT NULL,server_id int unsigned NOT NULL PRIMARY KEY,file varchar(255) DEFAULT NULL,position bigint unsigned DEFAULT NULL,relay_master_log_file varchar(255) DEFAULT NULL,exec_master_log_pos bigint unsigned DEFAULT NULL);

