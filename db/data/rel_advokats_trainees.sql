DROP TABLE IF EXISTS `rel_advokats_trainees`;

CREATE TABLE `rel_advokats_trainees` (
  `_record_id` int(11) NOT NULL AUTO_INCREMENT,
  `ds_advokat_id` int(11) DEFAULT NULL,
  `ds_trainee_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`_record_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1178 DEFAULT CHARSET=utf8;
