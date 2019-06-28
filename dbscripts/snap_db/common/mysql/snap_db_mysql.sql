CREATE TABLE IF NOT EXISTS ATOM_SEQUENCE
(
    SEQUENCE               VARCHAR(200)   NOT NULL,
    VALUE                  BIGINT,
    CONSTRAINT PK_ATOM_SEQUENCE PRIMARY KEY (SEQUENCE)
);

CREATE TABLE IF NOT EXISTS EXCHANGE_RATE
(
    ID                      INT(11)  NOT NULL ,
    SRC_CURRENCY            NUMERIC(6)  NULL,
    TARGET_CURRENCY         NUMERIC(6) NULL,
    RATE                    NUMERIC (20,5) NULL,
    START_DATE              NUMERIC(14) NOT NULL,
    EXPIRED_DATE            NUMERIC(14),
    LAST_UPDATE_TIME        NUMERIC(14)  NULL,
    CONSTRAINT PK_EXCHANGE_RATE PRIMARY KEY (ID)
) ;

CREATE INDEX IDX_EXCHANGE_RATE ON EXCHANGE_RATE(SRC_CURRENCY,TARGET_CURRENCY,START_DATE,EXPIRED_DATE);

CREATE TABLE LICENSE_AUDIT_DETAILS  (
   id                               NUMERIC(18)                 NOT NULL,
   batch_id                             NUMERIC(18),
   server_name                      VARCHAR(128),                       
   session_server               VARCHAR(128),                       
   server_address               VARCHAR(128),
   statistic_key                            VARCHAR(128),
   statistic_type                           NUMERIC(2)                 NOT NULL,
   protocol                                     NUMERIC(2)                 NOT NULL,
   conn_type                                    VARCHAR(40),
   module                                           VARCHAR(40),
   time_begin                                   DATETIME,
   time_collect                             DATETIME,
   value_average_from_begin     NUMERIC(18)                 NOT NULL,
   value_peak_from_begin            NUMERIC(18)                 NOT NULL,
   licensable                                   BOOLEAN                 NOT NULL,   
   constraint PK_LICENSE_AUDIT_DETAILS primary key (id)
);

CREATE TABLE LICENSE_AUDIT_REC  (
   id                               NUMERIC(18)                 NOT NULL,
   collect_date                     VARCHAR(14),
   module                               VARCHAR(40),                       
   signature                        VARCHAR(64),                       
   average_tps                      NUMERIC(18)                 NOT NULL,
   average_subscriber_count     NUMERIC(18)                 NOT NULL,
   average_concurrent_session   NUMERIC(18)                 NOT NULL,
   peak_tps                                     NUMERIC(18)                 NOT NULL,
   peak_subscriber_count            NUMERIC(18)                 NOT NULL,
   peak_concurrent_session      NUMERIC(18)                 NOT NULL,
   tps_status                                   NUMERIC(4)                 NOT NULL,
   subscriber_count_status      NUMERIC(4)                 NOT NULL,
   concurrent_session_status    NUMERIC(4)                 NOT NULL,
   suspect_flag                             NUMERIC(4)                 NOT NULL,   
   constraint PK_LICENSE_AUDIT_REC primary key (id)
);

CREATE TABLE `tracing_table` (
	`user_id` VARCHAR(15) NOT NULL,
	`StartTime` DATETIME NULL DEFAULT NULL,
	`EndTime` DATETIME NULL DEFAULT NULL,
	`tracing_session_id` INT(11) NULL DEFAULT NULL,	
	PRIMARY KEY (`user_id`)
) COLLATE='utf8_general_ci' ENGINE=InnoDB;

CREATE TABLE trace_data (
  id int(11) NOT NULL AUTO_INCREMENT,
  user_subscriber_id varchar(20) DEFAULT NULL,
  user_msisdn varchar(20) DEFAULT NULL,
  user_session_id varchar(255) DEFAULT NULL,
  result_code int(11) DEFAULT NULL,
  app_message_type varchar(20) DEFAULT NULL,
  message_data text,
  request_timestamp datetime(6) NULL DEFAULT NULL,
  answer_timestamp datetime(6)  NULL DEFAULT NULL,
  network_event_timestamp datetime(6) NULL DEFAULT NULL,
  entry_timestamp datetime(6)  NULL DEFAULT NULL,
  client_session_server_name varchar(50) DEFAULT NULL,
  client_module_name varchar(50) DEFAULT NULL,
  server_session_server_name varchar(50) DEFAULT NULL,
  server_module_name varchar(50) DEFAULT NULL,
  PRIMARY KEY (id)
)  ENGINE=InnoDB DEFAULT CHARSET=latin1;

create table `result_table` (
`result_code` VARCHAR(20) NOT NULL,
`name` VARCHAR(50) NOT NULL DEFAULT "",
PRIMARY KEY (`result_code`)
);

CREATE TABLE `command_table` (
	`command_code` VARCHAR(20) NOT NULL,
	`command_name` VARCHAR(50) NOT NULL DEFAULT '',
	`application` VARCHAR(50) NOT NULL DEFAULT '',
	`protocol` VARCHAR(50) NOT NULL DEFAULT '',	
	PRIMARY KEY (`command_code`)
);

insert into command_table (command_code,command_name,application,protocol) values ('Ps_SPR', 'SPR Provision','SPRP','HTTP');
insert into command_table (command_code,command_name,application,protocol) values ('Ps_ABM', 'ABM Provision','SPRP','HTTP');
insert into command_table (command_code,command_name,application,protocol) values ('Ps1_SPR', 'SPR Provision','SPRS','NMERPC');
insert into command_table (command_code,command_name,application,protocol) values ('Ps1_ABM', 'ABM Provision','ABM','NMERPC');
insert into command_table (command_code,command_name,application,protocol) values ('Rc_ACR', 'Credit Control','ABM','Diameter');
insert into command_table (command_code,command_name,application,protocol) values ('Rc_RAR', 'Re-Auth','ABM','Diameter');
insert into command_table (command_code,command_name,application,protocol) values ('Rc_ASR', 'Abort Session','ABM','Diameter');
insert into command_table (command_code,command_name,application,protocol) values ('Ro_CCR', 'Credit Control','OCF','Diameter');
insert into command_table (command_code,command_name,application,protocol) values ('Ro_RAR', 'Re-Auth','OCF','Diameter');
insert into command_table (command_code,command_name,application,protocol) values ('Ro_ASR', 'Abort Session','OCF','Diameter');
insert into command_table (command_code,command_name,application,protocol) values ('Sy_SLR_OCF', 'Spending Limit','OCF','Diameter');
insert into command_table (command_code,command_name,application,protocol) values ('Sy_SNR_OCF', 'Status Notification','OCF','Diameter');
insert into command_table (command_code,command_name,application,protocol) values ('Sy_STR_OCF', 'Session Termination','OCF','Diameter');
insert into command_table (command_code,command_name,application,protocol) values ('Re_PRQ', 'Price','SLRE','NMERPC');
insert into command_table (command_code,command_name,application,protocol) values ('Nc', 'Notification','MNS','NMERPC');
insert into command_table (command_code,command_name,application,protocol) values ('Gx_CCR', 'Credit Control','PS','Diameter');
insert into command_table (command_code,command_name,application,protocol) values ('Gx_RAR', 'Re-Auth','PS','Diameter');
insert into command_table (command_code,command_name,application,protocol) values ('Gx_ASR', 'Abort Session','PS','Diameter');
insert into command_table (command_code,command_name,application,protocol) values ('Sy_SLR_PCRF', 'Spending Limit','PS','Diameter');
insert into command_table (command_code,command_name,application,protocol) values ('Sy_SNR_PCRF', 'Status Notification','PS','Diameter');
insert into command_table (command_code,command_name,application,protocol) values ('Sy_STR_PCRF', 'Session Termination','PS','Diameter');
insert into command_table (command_code,command_name,application,protocol) values ('Rx_AAR', 'Authorization Authentication','PS','Diameter');
insert into command_table (command_code,command_name,application,protocol) values ('Rx_RAR', 'Re-Auth','PS','Diameter');
insert into command_table (command_code,command_name,application,protocol) values ('Rx_STR', 'Session Termination','PS','Diameter');
insert into command_table (command_code,command_name,application,protocol) values ('Rx_ASR', 'Abort Session','PS','Diameter');

insert into ATOM_SEQUENCE (SEQUENCE, VALUE) VALUES('SEQ_AUDIT_PRIMARY',1);
insert into ATOM_SEQUENCE (SEQUENCE, VALUE) VALUES('SEQ_AUDIT_DETAILS',1);