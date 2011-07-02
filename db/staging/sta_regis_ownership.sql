/*
 Navicat MySQL Data Transfer

 Source Server         : localhost
 Source Server Version : 50513
 Source Host           : localhost
 Source Database       : datanest_staging

 Target Server Version : 50513
 File Encoding         : utf-8

 Date: 07/02/2011 21:50:32 PM
*/

SET NAMES utf8;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
--  Table structure for `sta_regis_ownership`
-- ----------------------------
DROP TABLE IF EXISTS `sta_regis_ownership`;
CREATE TABLE `sta_regis_ownership` (
  `id` int(10) unsigned DEFAULT NULL,
  `text` varchar(255) DEFAULT NULL,
  KEY `i_ownership` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Records of `sta_regis_ownership`
-- ----------------------------
BEGIN;
INSERT INTO `sta_regis_ownership` VALUES ('0', 'Zatiaľ nezistené'), ('1', 'Medzinárodné s prevažujúcim verejným sektorom'), ('2', 'Súkromné tuzemské'), ('3', 'Družstevné'), ('4', 'Štátne'), ('5', 'Vlastníctvo územnej samosprávy'), ('6', 'Vlastníctvo združení, politických strán a cirkví'), ('7', 'Zahraničné'), ('8', 'Medzinárodné s prevažujúcim súkromným sektorom'), ('9', 'Zmiešané (kombinácia 1 až 8)');
COMMIT;

SET FOREIGN_KEY_CHECKS = 1;
