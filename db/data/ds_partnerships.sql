DROP TABLE IF EXISTS `ds_lawyer_partnerships`;

CREATE TABLE `ds_lawyer_partnerships` (
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
  `partnership_type` varchar(255) DEFAULT NULL,
  `registry_number` varchar(255) DEFAULT NULL,
  `ico` varchar(255) DEFAULT NULL,
  `dic` varchar(255) DEFAULT NULL,
  `street` varchar(255) DEFAULT NULL,
  `city` varchar(255) DEFAULT NULL,
  `zip` varchar(255) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `fax` varchar(255) DEFAULT NULL,
  `cell_phone` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `sak_id` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`_record_id`)
) ENGINE=InnoDB AUTO_INCREMENT=16105 DEFAULT CHARSET=utf8;
