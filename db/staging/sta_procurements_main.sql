delimiter $$

CREATE TABLE `sta_procurements` (
  `id` int(11) NOT NULL DEFAULT '0',
  `year` int(11) DEFAULT NULL,
  `bulletin_id` int(11) DEFAULT NULL,
  `procurement_id` varchar(255) DEFAULT NULL,
  `customer_ico` bigint(20) DEFAULT NULL,
  `supplier_ico` bigint(20) DEFAULT NULL,
  `procurement_subject` text,
  `price` decimal(16,2) DEFAULT NULL,
  `currency` varchar(255) DEFAULT NULL,
  `is_vat_included` tinyint(1) DEFAULT NULL,
  `customer_ico_evidence` text,
  `supplier_ico_evidence` text,
  `subject_evidence` text,
  `price_evidence` text,
  `procurement_type_id` int(11) DEFAULT NULL,
  `document_id` bigint(20) DEFAULT NULL,
  `source_url` varchar(255) DEFAULT NULL,
  `date_created` datetime DEFAULT NULL,
  `etl_loaded_date` datetime DEFAULT NULL,
  `supplier_name` text,
  `customer_name` text,
  `is_price_part_of_range` tinyint(1) DEFAULT NULL,
  `note` text
) ENGINE=MyISAM DEFAULT CHARSET=utf8$$