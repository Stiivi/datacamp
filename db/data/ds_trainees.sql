DROP TABLE IF EXISTS `ds_trainees`;

CREATE TABLE `ds_trainees` (
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
  `first_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `ds_advokat_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`_record_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2344 DEFAULT CHARSET=utf8;
