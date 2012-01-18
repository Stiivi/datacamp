DROP TABLE IF EXISTS `dc_updates`;

CREATE TABLE `dc_updates` (
  `_record_id` int(11) NOT NULL AUTO_INCREMENT,
  `updateable_id` int(11),
  `updateable_type` varchar(255),
  
  `column_name` varchar(255),
  `original_value` text,
  `new_value` text,
  PRIMARY KEY (`_record_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1178 DEFAULT CHARSET=utf8;
