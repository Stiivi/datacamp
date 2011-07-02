delimiter $$

CREATE TABLE `sta_regis_main` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `doc_id` int(11) DEFAULT NULL,
  `ico` bigint(20) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `legal_form` int(11) DEFAULT NULL,
  `date_start` date DEFAULT NULL,
  `date_end` date DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `region` varchar(255) DEFAULT NULL,
  `activity1` int(11) DEFAULT NULL,
  `activity2` int(11) DEFAULT NULL,
  `account_sector` int(11) DEFAULT NULL,
  `ownership` int(11) DEFAULT NULL,
  `size` int(11) DEFAULT NULL,
  `source_url` varchar(255) DEFAULT NULL,
  `date_created` datetime DEFAULT NULL,
  `etl_loaded_date` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index2` (`ico`)
) ENGINE=MyISAM AUTO_INCREMENT=1166254 DEFAULT CHARSET=utf8$$

