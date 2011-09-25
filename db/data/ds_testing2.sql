DROP TABLE IF EXISTS `ds_testing2`;

CREATE TABLE `ds_testing2` (
  `_record_id` int(11) NOT NULL AUTO_INCREMENT,
  `created_by` varchar(255) DEFAULT NULL,
  `record_status` varchar(255) DEFAULT NULL,
  `updated_by` varchar(255) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `validity_date` date DEFAULT NULL,
  `quality_status` varchar(255) DEFAULT NULL,
  `is_hidden` tinyint(1) DEFAULT NULL,
  `batch_id` int(11) DEFAULT NULL,
  `test` varchar(255) DEFAULT NULL,
	`ico` int(11) DEFAULT NULL,
	`company_name` varchar(255) DEFAULT NULL,
	`company_address` varchar(255) DEFAULT NULL,
	`relation_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`_record_id`),
  KEY `test_index` (`test`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
