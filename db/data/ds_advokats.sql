DROP TABLE IF EXISTS `ds_advokats`;

CREATE TABLE `ds_advokats` (
  `_record_id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `updated_by` varchar(255) DEFAULT NULL,
  `record_status` varchar(255) DEFAULT NULL,
  `quality_status` varchar(255) DEFAULT NULL,
  `batch_id` int(11) DEFAULT NULL,
  `validity_date` date DEFAULT NULL,
  `is_hidden` tinyint(1) DEFAULT NULL,
  
  `name` varchar(255) DEFAULT NULL,
  `advokat_type` varchar(255) DEFAULT NULL,
  `street` varchar(255) DEFAULT NULL,
  `city` varchar(255) DEFAULT NULL,
  `zip` varchar(255) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `fax` varchar(255) DEFAULT NULL,
  `cell_phone` varchar(255) DEFAULT NULL,
  `languages` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `etl_loaded` datetime DEFAULT NULL,
  PRIMARY KEY (`_record_id`)
) ENGINE=InnoDB AUTO_INCREMENT=16105 DEFAULT CHARSET=utf8;
