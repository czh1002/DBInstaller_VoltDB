CREATE TABLE `tb_ocf_traced_user` (
  `Subscriber_Type` int(11) DEFAULT NULL,
  `Trace_Subscriber` varchar(15) NOT NULL DEFAULT '',
  PRIMARY KEY (`Trace_Subscriber`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `tb_ocf_visited_information_ne_l1_map` (
  `id` bigint(20) unsigned NOT NULL,
  `matching_method` char(1) NOT NULL DEFAULT '1',
  `ocf_vi_ne_code` varchar(40) NOT NULL,
  `priority` smallint(6) NOT NULL DEFAULT '600',
  `ocf_vi_country_id` varchar(2) NOT NULL,
  `ocf_vi_zone_id` bigint(20) unsigned DEFAULT NULL,
  `ocf_vi_plmn_id` bigint(20) unsigned DEFAULT NULL,
  `ocf_vi_operator_code` varchar(9) DEFAULT NULL,
  `ne_type` smallint(6) NOT NULL DEFAULT '1',
  `has_level2` char(1) NOT NULL DEFAULT 'N',
  `use_ne_timezone` char(1) NOT NULL DEFAULT 'Y',
  `remarks` varchar(128) DEFAULT NULL,
  `reserve1` varchar(20) DEFAULT NULL,
  `reserve2` varchar(20) DEFAULT NULL,
  `reserve3` varchar(20) DEFAULT NULL,
  `state_lifecycle` char(1) NOT NULL DEFAULT 'D',
  `effective_date` bigint(20) NOT NULL,
  `expire_date` bigint(20) DEFAULT NULL,
  `create_time` bigint(20) NOT NULL,
  `update_time` bigint(20) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `tb_ocf_result_code_map` (
  `ocf_internal_result_code` varchar(10) NOT NULL,
  `ocf_result_code` int(11) NOT NULL,
  `ocf_result_code_type` int(11) NOT NULL,
  `create_date` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `modify_date` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `eff_date` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `exp_date` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `remarks` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`ocf_internal_result_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE TB_OCF_SERVICE_TYPE (
serv_Context INT NOT NULL,
serv_Type INT NOT NULL,
description VARCHAR (20) NULL,
CONSTRAINT PRIMARY KEY (serv_Context)
);

create table TB_OCF_SYSTEM_PARAMETER  (
   service_type         int(11)                        not null,
   service_type_desc    VARCHAR(64)                    not null,
   para_key             VARCHAR(64)                    not null,
   para_key_desc        VARCHAR(64)                    not null,
   para_value           VARCHAR(256)                   not null,
   para_value_desc      VARCHAR(512)                   not null,
   create_date          bigint(20)                     not null,
   modify_date          bigint(20)                     not null,
   eff_date             bigint(20)                     not null,
   exp_date             bigint(20)                     not null,
   remarks              varchar(64),
   constraint PK_CM_SYSTEM_PARAMETER primary key (service_type, para_key)
);

CREATE TABLE TB_OCF_CALL_DIR (
serv_Type INT NOT NULL,
role_Node INT NOT NULL,
call_Dir VARCHAR (2) NOT NULL,
description VARCHAR (20) NULL,
CONSTRAINT PRIMARY KEY (serv_Type, role_Node)
);

create table TB_OCF_CALLED_AREA_CODE (
   id                   DECIMAL(9)                      not null,
   country_id           VARCHAR(2)                      not null,
   zone_id              DECIMAL(9),
   area_code            VARCHAR(40)                     not null,
   premium_number_class DECIMAL(6)                      default 0,
   operator_code        VARCHAR(9),
   plmn_id              DECIMAL(9),
   priority             DECIMAL(3)                      default 600 not null,
   reserve1             VARCHAR(128),
   reserve2             VARCHAR(128),
   reserve3             VARCHAR(128),
   reserve4             VARCHAR(128),
   reserve5             VARCHAR(128),
   remarks              VARCHAR(128),
   state_lifecycle      CHAR(1)                         default 'D' not null,
   effective_date       DECIMAL(14)                     not null,
   expire_date          DECIMAL(14),
   create_time          DECIMAL(14)                     not null,
   update_time          DECIMAL(14)                     not null,
   CONSTRAINT PRIMARY KEY (id)
);



INSERT INTO TB_OCF_SERVICE_TYPE (serv_Context, serv_Type, description) VALUES (32260,10, 'IMS Voice');
INSERT INTO TB_OCF_SERVICE_TYPE (serv_Context, serv_Type, description) VALUES (32251,20, 'Data');

/* Table: TB_OCF_SYSTEM_PARAMETER  Initalize                            */

Insert into TB_OCF_SYSTEM_PARAMETER(service_type, service_type_desc, PARA_KEY, PARA_KEY_DESC, PARA_VALUE, PARA_VALUE_DESC, CREATE_DATE, MODIFY_DATE, EFF_DATE, EXP_DATE)
Values (20, 'Parameter for common service', 'Validity_Time', 'Defualt Validity Time ', '30', '30 seconds', 20010101000000, 20010101000000, 20010101000000, 21010101000000);
Insert into TB_OCF_SYSTEM_PARAMETER(service_type, service_type_desc, PARA_KEY, PARA_KEY_DESC, PARA_VALUE, PARA_VALUE_DESC, CREATE_DATE, MODIFY_DATE, EFF_DATE, EXP_DATE)
Values (20, 'Parameter for common service', 'Timeout_Threshold', 'Defualt Timeout_Threshold  ', '5', '5 seconds', 20010101000000, 20010101000000, 20010101000000, 21010101000000);
Insert into TB_OCF_SYSTEM_PARAMETER(service_type, service_type_desc, PARA_KEY, PARA_KEY_DESC, PARA_VALUE, PARA_VALUE_DESC, CREATE_DATE, MODIFY_DATE, EFF_DATE, EXP_DATE)
Values (20, 'Parameter for common service', 'RAR_Retrys', 'Defualt RAR retry time  ', '3', '3 times', 20010101000000, 20010101000000, 20010101000000, 21010101000000);

/* Table: TB_OCF_CALL_DIR  Initalize                            */
INSERT INTO TB_OCF_CALL_DIR (serv_Type, role_Node, call_Dir, description) VALUES (10, 0, '0', 'Mobile Originated');
INSERT INTO TB_OCF_CALL_DIR (serv_Type, role_Node, call_Dir, description) VALUES (10, 1, '1', 'Mobile Terminated');

/* Table: TB_OCF_RESULT_CODE_MAP Initalize */
INSERT INTO `tb_ocf_result_code_map` VALUES ('0', 2001,0,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', 'Success');
INSERT INTO `tb_ocf_result_code_map` VALUES ('1', 5004, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', 'Current CCR ccRequestNumber should be larger than the last CCR ccRequestNumber');
INSERT INTO `tb_ocf_result_code_map` VALUES ('1001', 5004, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '1. Refund Not support for current version; 2.authApplicationId not valid! 3.Session ID not valid! 4.retransmit record extis,but no retransmit flag report!! 5.retransmit record and session extis,but no retransmit flag report!! 6.Session exists error 7.load session internal error happend!');
INSERT INTO `tb_ocf_result_code_map` VALUES ('1002', 5004, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', 'Invalid Service-Context-Id AVP value');
INSERT INTO `tb_ocf_result_code_map` VALUES ('1003', 5004, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', 'Invalid Role-of-Node AVP value');
INSERT INTO `tb_ocf_result_code_map` VALUES ('1004', 5004, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', 'Invalid Node-Functionality AVP value');
INSERT INTO `tb_ocf_result_code_map` VALUES ('1005', 5004, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', 'Invalid Access-Network-Information AVP value');
INSERT INTO `tb_ocf_result_code_map` VALUES ('1006', 5004, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', 'Invalid Called-Party-Address AVP format');
INSERT INTO `tb_ocf_result_code_map` VALUES ('1007', 5004, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', 'Invalid Request Type AVP value');
INSERT INTO `tb_ocf_result_code_map` VALUES ('1008', 5004, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', 'Invalid Request Action AVP value');
INSERT INTO `tb_ocf_result_code_map` VALUES ('1501', 5005, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', 'Missing Role-of-Node AVP in CCR-I');
INSERT INTO `tb_ocf_result_code_map` VALUES ('1502', 5005, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', 'Missing Node-Functionality AVP in CCR-I');
INSERT INTO `tb_ocf_result_code_map` VALUES ('1503', 5005, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', 'Missing Access-Network-Information AVP in CCR-I');
INSERT INTO `tb_ocf_result_code_map` VALUES ('1504', 5005, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', 'Missing Called-Party-Address AVP in CCR-I');
INSERT INTO `tb_ocf_result_code_map` VALUES ('3201', 5030, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', NULL);
INSERT INTO `tb_ocf_result_code_map` VALUES ('3202', 5030, 1,NULL, NULL, NULL, NULL, NULL);
INSERT INTO `tb_ocf_result_code_map` VALUES ('3209', 5030, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', NULL);
INSERT INTO `tb_ocf_result_code_map` VALUES ('4001', 5012, 1,NULL, NULL, NULL, NULL, NULL);
INSERT INTO `tb_ocf_result_code_map` VALUES ('4002', 5012, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', 'Invalid calculated Call Direction');
INSERT INTO `tb_ocf_result_code_map` VALUES ('4003', 5012, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', 'Calling/Called Numbers Invalid area code');
INSERT INTO `tb_ocf_result_code_map` VALUES ('5031', 5031, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '1.DIAMETER_RATING_FAILED 2.SLRE Rating Failed!');
INSERT INTO `tb_ocf_result_code_map` VALUES ('6020', 5002, 0,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '1.retransmit record extis,but no retransmit flag report and session not exits!! 2.no session found!');
INSERT INTO `tb_ocf_result_code_map` VALUES ('1101', 5004, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '1.Invalid Request Number reported by NE! 2.RatingGroup not reported by NE! 3.No MSCC reported by NE!');
INSERT INTO `tb_ocf_result_code_map` VALUES ('3002', 3002, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', 'OSGI Services are not ready');
INSERT INTO `tb_ocf_result_code_map` VALUES ('3003', 3003, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', 'Return Slave Error');
INSERT INTO `tb_ocf_result_code_map` VALUES ('5005', 5005, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', 'DIAMETER_MISSING_AVP(ABM CCR)');
INSERT INTO `tb_ocf_result_code_map` VALUES ('5012', 5012, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '1.There are no MSCC in ABM Rc CCA 2.Error happened in ABM 3.There are no multipleServicesCreditControl AVP in ABM Rc Event CCA 4.There are no multipleAcctBalances in Rc Event CCA Mscc whose result code is 2001! 5.DIAMETER_MISSING_AVP(ABM CCR:cannot find Subscription-Id data with Subscription-Id-Type = 0)');
INSERT INTO `tb_ocf_result_code_map` VALUES ('5030', 5030, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', 'DIAMETER_USER_UNKNOWN - The specified end user could not be found in the ABM');
INSERT INTO `tb_ocf_result_code_map` VALUES ('4012', 4012, 1,'2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', '2016-7-12 10:57:41', 'ABM Event CCA result code is 4012');