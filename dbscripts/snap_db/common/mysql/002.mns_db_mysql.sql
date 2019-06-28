DROP TABLE IF EXISTS `hi_mns_notifications`;
CREATE TABLE `hi_mns_notifications` (
  `notification_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `message_template_id` varchar(64) DEFAULT NULL,
  `source` varchar(20) DEFAULT NULL,
  `channel` varchar(20) DEFAULT NULL,
  `subscriber_id` bigint(20) DEFAULT NULL,
  `partition_id` int(20) DEFAULT NULL,
  `target` varchar(64) DEFAULT NULL,
  `language` varchar(20) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `message_request_title` text,
  `message_request_body` text,
  `retry_times` int(20) DEFAULT NULL,
  `status` int(2) DEFAULT NULL,
  `result_code` varchar(64) DEFAULT NULL,
  `result_desc` varchar(255) DEFAULT NULL,
  `last_update_time` datetime DEFAULT NULL,
  `snme` varbinary(2048) DEFAULT NULL,
  `notify_others` int(2) DEFAULT NULL,
  PRIMARY KEY (`notification_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `low_mns_notifications`;
CREATE TABLE `low_mns_notifications` (
  `notification_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `message_template_id` varchar(64) DEFAULT NULL,
  `source` varchar(20) DEFAULT NULL,
  `channel` varchar(20) DEFAULT NULL,
  `subscriber_id` bigint(20) DEFAULT NULL,
  `partition_id` int(20) DEFAULT NULL,
  `target` varchar(64) DEFAULT NULL,
  `language` varchar(20) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `message_request_title` text,
  `message_request_body` text,
  `retry_times` int(20) DEFAULT NULL,
  `status` int(2) DEFAULT NULL,
  `result_code` varchar(64) DEFAULT NULL,
  `result_desc` varchar(255) DEFAULT NULL,
  `last_update_time` datetime DEFAULT NULL,
  `snme` varbinary(2048) DEFAULT NULL,
  `notify_others` int(2) DEFAULT NULL,
  PRIMARY KEY (`notification_id`)
) ENGINE=InnoDB AUTO_INCREMENT=260 DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `mns_notifications_history`;
CREATE TABLE `mns_notifications_history` (
  `history_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `message_template_id` varchar(64) DEFAULT NULL,
  `source` varchar(20) DEFAULT NULL,
  `channel` varchar(20) DEFAULT NULL,
  `subscriber_id` bigint(20) DEFAULT NULL,
  `partition_id` int(20) DEFAULT NULL,
  `target` varchar(64) DEFAULT NULL,
  `language` varchar(20) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `message_request_title` text,
  `message_request_body` text,
  `retry_times` int(20) DEFAULT NULL,
  `status` int(2) DEFAULT NULL,
  `result_code` varchar(64) DEFAULT NULL,
  `result_desc` varchar(255) DEFAULT NULL,
  `last_update_time` datetime DEFAULT NULL,
  `snme` varbinary(2048) DEFAULT NULL,
  `notify_others` int(2) DEFAULT NULL,
  `priority` varchar(10) DEFAULT NULL,
  PRIMARY KEY (`history_id`)
) ENGINE=InnoDB AUTO_INCREMENT=253 DEFAULT CHARSET=utf8;
