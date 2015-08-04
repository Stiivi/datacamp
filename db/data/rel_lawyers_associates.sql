DROP TABLE IF EXISTS `rel_lawyers_associates`;

CREATE TABLE `rel_lawyers_associates` (
  `_record_id` int(11) NOT NULL AUTO_INCREMENT,
  `ds_lawyer_id` int(11) DEFAULT NULL,
  `ds_associate_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`_record_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1178 DEFAULT CHARSET=utf8;
