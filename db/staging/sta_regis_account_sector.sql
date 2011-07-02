/*
 Navicat MySQL Data Transfer

 Source Server         : localhost
 Source Server Version : 50513
 Source Host           : localhost
 Source Database       : datanest_staging

 Target Server Version : 50513
 File Encoding         : utf-8

 Date: 07/02/2011 21:50:26 PM
*/

SET NAMES utf8;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
--  Table structure for `sta_regis_account_sector`
-- ----------------------------
DROP TABLE IF EXISTS `sta_regis_account_sector`;
CREATE TABLE `sta_regis_account_sector` (
  `id` int(10) unsigned DEFAULT NULL,
  `text` varchar(255) DEFAULT NULL,
  KEY `i_account_sector` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Records of `sta_regis_account_sector`
-- ----------------------------
BEGIN;
INSERT INTO `sta_regis_account_sector` VALUES ('11001', 'Verejné nefinančné korporácie'), ('11002', 'Súkromné nefinančné korporácie'), ('11003', 'Nefinančné korporácie pod zahraničnou kontrolou'), ('12100', 'Národná banka Slovenska'), ('12201', 'Verejné ostatné finančné inštitúcie'), ('12202', 'Súkromné ostatné finančné inštitúcie'), ('12203', 'Ostatné finančné inštitúcie pod zahraničnou kontrolou'), ('12301', 'Verejní ostatní finanční sprostredkovatelia okrem poisťovacích korporácií a penzijných fondov'), ('12302', 'Súkromní ostatní finanční sprostredkovatelia okrem poisťovacích korporácií a penzijných fondov'), ('12303', 'Ostatní finanční sprostredkovatelia okrem poisťovacích korporácií a penzijných fondov pod zahraničnou kontrolou'), ('12401', 'Verejné finančné pomocné inštitúcie'), ('12402', 'Súkromné finančné pomocné inštitúcie'), ('12403', 'Finančné pomocné inštitúcie pod zahraničnou kontrolou'), ('12501', 'Verejné poisťovacie korporácie a penzijné fondy'), ('12502', 'Súkromné poisťovacie korporácie a penzijné fondy'), ('12503', 'Poisťovacie korporácie a penzijné fondy pod zahraničnou kontrolou'), ('13110', 'Ústredná štátna správa'), ('13130', 'Miestna samospráva'), ('13140', 'Fondy sociálneho zabezpečenia'), ('14100', 'Fyzické osoby podnikajúce na základe živnostenského zákona a iných právnych predpisov nezapísané v obchodnom registri'), ('15000', 'Neziskové inštitúcie slúžiace domácnostiam'), ('21200', 'Inštitúcie EÚ'), ('22000', 'Ostatné medzinárodné inštitúcie');
COMMIT;

SET FOREIGN_KEY_CHECKS = 1;
