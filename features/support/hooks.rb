Before('@ds_testing_table') do
  ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS `ds_testings`')
  ActiveRecord::Base.connection.execute(
      'CREATE TABLE `ds_testings` (
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
  `id` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`_record_id`),
  KEY `test_index` (`test`)
) ENGINE=InnoDB AUTO_INCREMENT=1397 DEFAULT CHARSET=utf8;'
  )
end

After('@cleanup_files_after') do
  Dir.glob("#{Rails.root}/files/*_test.csv").each do |filepath|
    File.delete(filepath)
  end
end