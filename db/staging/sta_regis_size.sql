/*
 Navicat MySQL Data Transfer

 Source Server         : localhost
 Source Server Version : 50513
 Source Host           : localhost
 Source Database       : datanest_staging

 Target Server Version : 50513
 File Encoding         : utf-8

 Date: 07/02/2011 21:50:44 PM
*/

SET NAMES utf8;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
--  Table structure for `sta_regis_size`
-- ----------------------------
DROP TABLE IF EXISTS `sta_regis_size`;
CREATE TABLE `sta_regis_size` (
  `id` int(10) unsigned DEFAULT NULL,
  `text` varchar(255) DEFAULT NULL,
  KEY `i_size` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Records of `sta_regis_size`
-- ----------------------------
BEGIN;
INSERT INTO `sta_regis_size` VALUES ('0', 'nezistený'), ('1', '0 zamestnancov'), ('2', '1 zamestnanec'), ('3', '2 zamestnanci'), ('4', '3-4 zamestnanci'), ('5', '5-9 zamestnancov'), ('6', '10-19 zamestnancov'), ('7', '20-24 zamestnancov'), ('11', '25-49 zamestnancov'), ('12', '50-99 zamestnancov'), ('21', '100-149 zamestnancov'), ('22', '150-199 zamestnancov'), ('23', '200-249 zamestnancov'), ('24', '250-499 zamestnancov'), ('25', '500-999 zamestnancov'), ('31', '1000-1999 zamestnancov'), ('32', '2000-2999 zamestnancov'), ('33', '3000-3999 zamestnancov'), ('34', '4000-4999 zamestnancov'), ('35', '5000-9999 zamestnancov'), ('36', '10000-19999 zamestnancov'), ('37', '20000-29999 zamestnancov'), ('38', '30000 zamestnancov a viac');
COMMIT;

SET FOREIGN_KEY_CHECKS = 1;
