-- MySQL dump 10.10
--
-- Host: localhost    Database: wowitems
-- ------------------------------------------------------
-- Server version	5.0.27

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `auc_scan_item`
--

DROP TABLE IF EXISTS `auc_scan_item`;
CREATE TABLE `auc_scan_item` (
  `itemid` int(10) unsigned NOT NULL,
  `ilevel` smallint(5) unsigned default NULL,
  `itype` varchar(64) NOT NULL,
  `isub` varchar(64) default NULL,
  `isequip` smallint(5) unsigned default NULL,
  `price` int(10) unsigned NOT NULL,
  `tleft` tinyint(3) unsigned default NULL,
  `time` datetime NOT NULL,
  `day` datetime NOT NULL,
  `name` varchar(128) NOT NULL,
  `texture` varchar(64) default NULL,
  `count` smallint(5) unsigned NOT NULL,
  `quality` tinyint(3) unsigned default NULL,
  `canuse` smallint(5) unsigned default NULL,
  `ulevel` smallint(5) unsigned default NULL,
  `minbid` int(10) unsigned default NULL,
  `mininc` smallint(5) unsigned default NULL,
  `buyout` int(10) unsigned default NULL,
  `curbid` int(10) unsigned default NULL,
  `amhigh` tinyint(3) unsigned default NULL,
  `seller` varchar(32) NOT NULL,
  `id` int(10) unsigned default NULL,
  `suffix` int(11) NOT NULL,
  `factor` int(11) NOT NULL,
  `enchant` int(11) NOT NULL,
  `seed` smallint(5) unsigned default NULL,
  `realm` varchar(24) NOT NULL,
  `faction` varchar(16) NOT NULL,
  UNIQUE KEY `auc_scan_item_uniqueness` (`price`,`itemid`,`seller`,`day`,`realm`,`faction`,`suffix`,`factor`,`enchant`),
  KEY `name` (`name`),
  KEY `price` (`price`),
  KEY `buyout` (`buyout`),
  KEY `minbid` (`minbid`),
  KEY `time` (`time`),
  KEY `itemid` (`itemid`),
  KEY `itemid_2` (`itemid`,`suffix`,`factor`,`enchant`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `auc_scan_item_first_seen`
--

DROP TABLE IF EXISTS `auc_scan_item_first_seen`;
CREATE TABLE `auc_scan_item_first_seen` (
  `itemid` int(10) unsigned default NULL,
  `name` varchar(128) character set utf8 NOT NULL,
  `price_all` int(10) unsigned default NULL,
  `price` decimal(15,4) unsigned default NULL,
  `count` smallint(5) unsigned default NULL,
  `quality` tinyint(3) unsigned default NULL,
  `seller` varchar(32) character set utf8 default NULL,
  `realm` varchar(24) character set utf8 default NULL,
  `faction` varchar(16) character set utf8 default NULL,
  `first_seen` datetime
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `auction_metadata`
--

DROP TABLE IF EXISTS `auction_metadata`;
CREATE TABLE `auction_metadata` (
  `count` bigint(21) NOT NULL default '0'
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `auction_metadata_backup`
--

DROP TABLE IF EXISTS `auction_metadata_backup`;
CREATE TABLE `auction_metadata_backup` (
  `count` bigint(21) NOT NULL default '0'
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `charinfo`
--

DROP TABLE IF EXISTS `charinfo`;
CREATE TABLE `charinfo` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(12) NOT NULL,
  `realm_id` int(10) unsigned NOT NULL,
  `class` varchar(20) NOT NULL,
  `talent_spec` varchar(11) NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `charinfo_unique` (`name`,`realm_id`),
  KEY `charinfo_name` (`name`),
  KEY `charinfo_realm` (`realm_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `enchant_data`
--

DROP TABLE IF EXISTS `enchant_data`;
CREATE TABLE `enchant_data` (
  `id` int(10) unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `item`
--

DROP TABLE IF EXISTS `item`;
CREATE TABLE `item` (
  `name` varchar(128) character set utf8,
  `itemid` int(10) unsigned default NULL,
  `suffix` int(11) default NULL,
  `factor` int(11) default NULL,
  `enchant` int(11) default NULL,
  `quality` tinyint(3) unsigned default NULL,
  `itype` varchar(64) character set utf8,
  `isub` varchar(64) character set utf8 default NULL,
  `ulevel` smallint(5) unsigned default NULL,
  `ilevel` smallint(5) unsigned default NULL,
  `isequip` smallint(5) unsigned default NULL,
  `first_seen` datetime,
  `last_seen` datetime,
  `count` int(10) unsigned NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `item_backup`
--

DROP TABLE IF EXISTS `item_backup`;
CREATE TABLE `item_backup` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(128) character set utf8 NOT NULL,
  `itemid` int(10) unsigned NOT NULL default '0',
  `suffix` smallint(5) unsigned NOT NULL default '0',
  `factor` smallint(5) unsigned NOT NULL default '0',
  `enchant` smallint(5) unsigned NOT NULL default '0',
  `first_seen` datetime,
  `last_seen` datetime,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`,`itemid`,`suffix`,`factor`,`enchant`)
) ENGINE=MyISAM AUTO_INCREMENT=27980 DEFAULT CHARSET=latin1;

--
-- Table structure for table `item_base_names`
--

DROP TABLE IF EXISTS `item_base_names`;
CREATE TABLE `item_base_names` (
  `itemid` int(10) unsigned NOT NULL,
  `name` varchar(128) NOT NULL,
  PRIMARY KEY  (`itemid`),
  KEY `item_base_names_with_id` (`itemid`,`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `item_byfaction`
--

DROP TABLE IF EXISTS `item_byfaction`;
CREATE TABLE `item_byfaction` (
  `name` varchar(128) character set utf8,
  `itemid` int(10) unsigned NOT NULL,
  `suffix` int(11) NOT NULL,
  `factor` int(11) NOT NULL,
  `enchant` int(11) NOT NULL,
  `faction` varchar(16) character set utf8 NOT NULL,
  `quality` tinyint(3) unsigned default NULL,
  `itype` varchar(64) character set utf8,
  `isub` varchar(64) character set utf8 default NULL,
  `ulevel` smallint(5) unsigned default NULL,
  `ilevel` smallint(5) unsigned default NULL,
  `isequip` smallint(5) unsigned default NULL,
  `first_seen` datetime,
  `last_seen` datetime,
  `count` bigint(21) NOT NULL default '0',
  `volatility` double unsigned NOT NULL default '0',
  PRIMARY KEY  (`itemid`,`suffix`,`factor`,`enchant`,`faction`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `item_byitem`
--

DROP TABLE IF EXISTS `item_byitem`;
CREATE TABLE `item_byitem` (
  `name` varchar(128) character set utf8,
  `itemid` int(10) unsigned NOT NULL,
  `suffix` int(11) NOT NULL,
  `factor` int(11) NOT NULL,
  `enchant` int(11) NOT NULL,
  `quality` tinyint(3) unsigned default NULL,
  `itype` varchar(64) character set utf8,
  `isub` varchar(64) character set utf8 default NULL,
  `ulevel` smallint(5) unsigned default NULL,
  `ilevel` smallint(5) unsigned default NULL,
  `isequip` smallint(5) unsigned default NULL,
  `first_seen` datetime,
  `last_seen` datetime,
  `count` bigint(21) NOT NULL default '0',
  `volatility` double unsigned NOT NULL default '0',
  PRIMARY KEY  (`itemid`,`suffix`,`factor`,`enchant`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `item_byserver`
--

DROP TABLE IF EXISTS `item_byserver`;
CREATE TABLE `item_byserver` (
  `name` varchar(128) character set utf8,
  `itemid` int(10) unsigned NOT NULL,
  `suffix` int(11) NOT NULL,
  `factor` int(11) NOT NULL,
  `enchant` int(11) NOT NULL,
  `realm` varchar(24) character set utf8 NOT NULL,
  `faction` varchar(16) character set utf8 NOT NULL,
  `quality` tinyint(3) unsigned default NULL,
  `itype` varchar(64) character set utf8,
  `isub` varchar(64) character set utf8 default NULL,
  `ulevel` smallint(5) unsigned default NULL,
  `ilevel` smallint(5) unsigned default NULL,
  `isequip` smallint(5) unsigned default NULL,
  `first_seen` datetime,
  `last_seen` datetime,
  `count` bigint(21) NOT NULL default '0',
  `volatility` double unsigned NOT NULL default '0',
  PRIMARY KEY  (`itemid`,`suffix`,`factor`,`enchant`,`realm`,`faction`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `item_generic`
--

DROP TABLE IF EXISTS `item_generic`;
CREATE TABLE `item_generic` (
  `name` varchar(128) character set utf8,
  `itemid` int(10) unsigned default NULL,
  `quality` tinyint(3) unsigned default NULL,
  `itype` varchar(64) character set utf8,
  `isub` varchar(64) character set utf8 default NULL,
  `ulevel` smallint(5) unsigned default NULL,
  `ilevel` smallint(5) unsigned default NULL,
  `isequip` smallint(5) unsigned default NULL,
  `first_seen` datetime,
  `last_seen` datetime,
  `count` int(10) unsigned NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `item_generic_byfaction`
--

DROP TABLE IF EXISTS `item_generic_byfaction`;
CREATE TABLE `item_generic_byfaction` (
  `name` varchar(128) character set utf8,
  `itemid` int(10) unsigned NOT NULL,
  `faction` varchar(16) character set utf8 NOT NULL,
  `quality` tinyint(3) unsigned default NULL,
  `itype` varchar(64) character set utf8,
  `isub` varchar(64) character set utf8 default NULL,
  `ulevel` smallint(5) unsigned default NULL,
  `ilevel` smallint(5) unsigned default NULL,
  `isequip` smallint(5) unsigned default NULL,
  `first_seen` datetime,
  `last_seen` datetime,
  `count` bigint(21) NOT NULL default '0',
  `volatility` double unsigned NOT NULL default '0',
  PRIMARY KEY  (`itemid`,`faction`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `item_generic_byitem`
--

DROP TABLE IF EXISTS `item_generic_byitem`;
CREATE TABLE `item_generic_byitem` (
  `name` varchar(128) character set utf8,
  `itemid` int(10) unsigned NOT NULL,
  `quality` tinyint(3) unsigned default NULL,
  `itype` varchar(64) character set utf8,
  `isub` varchar(64) character set utf8 default NULL,
  `ulevel` smallint(5) unsigned default NULL,
  `ilevel` smallint(5) unsigned default NULL,
  `isequip` smallint(5) unsigned default NULL,
  `first_seen` datetime,
  `last_seen` datetime,
  `count` bigint(21) NOT NULL default '0',
  `volatility` double unsigned NOT NULL default '0',
  PRIMARY KEY  (`itemid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `item_generic_byserver`
--

DROP TABLE IF EXISTS `item_generic_byserver`;
CREATE TABLE `item_generic_byserver` (
  `name` varchar(128) character set utf8,
  `itemid` int(10) unsigned NOT NULL,
  `realm` varchar(24) character set utf8 NOT NULL,
  `faction` varchar(16) character set utf8 NOT NULL,
  `quality` tinyint(3) unsigned default NULL,
  `itype` varchar(64) character set utf8,
  `isub` varchar(64) character set utf8 default NULL,
  `ulevel` smallint(5) unsigned default NULL,
  `ilevel` smallint(5) unsigned default NULL,
  `isequip` smallint(5) unsigned default NULL,
  `first_seen` datetime,
  `last_seen` datetime,
  `count` bigint(21) NOT NULL default '0',
  `volatility` double unsigned NOT NULL default '0',
  PRIMARY KEY  (`itemid`,`realm`,`faction`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `item_price`
--

DROP TABLE IF EXISTS `item_price`;
CREATE TABLE `item_price` (
  `item_id` int(10) unsigned NOT NULL,
  `price` int(10) unsigned NOT NULL,
  `when_seen` datetime NOT NULL,
  KEY `when_seen` (`when_seen`),
  KEY `item_id` (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `item_quality`
--

DROP TABLE IF EXISTS `item_quality`;
CREATE TABLE `item_quality` (
  `id` tinyint(3) unsigned NOT NULL,
  `name` varchar(16) NOT NULL,
  `color` varchar(8) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `name` (`name`),
  KEY `color` (`color`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `item_suffix`
--

DROP TABLE IF EXISTS `item_suffix`;
CREATE TABLE `item_suffix` (
  `id` int(11) NOT NULL,
  `name` varchar(64) NOT NULL,
  `stat_1_name` varchar(32) default NULL,
  `stat_1_factor` float default NULL,
  `stat_2_name` varchar(32) default NULL,
  `stat_2_factor` float default NULL,
  `stat_3_name` varchar(32) default NULL,
  `stat_3_factor` float default NULL,
  PRIMARY KEY  (`id`),
  KEY `name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `price_history`
--

DROP TABLE IF EXISTS `price_history`;
CREATE TABLE `price_history` (
  `itemid` int(10) unsigned default NULL,
  `suffix` int(11) default NULL,
  `factor` int(11) default NULL,
  `enchant` int(11) default NULL,
  `time` datetime NOT NULL,
  `price` decimal(15,4) unsigned default NULL,
  `minbid` decimal(15,4) unsigned default NULL,
  `curbid` decimal(15,4) unsigned default NULL,
  `buyout` decimal(15,4) unsigned default NULL,
  `seller` varchar(32) character set utf8 default NULL,
  `realm` varchar(24) character set utf8 default NULL,
  `faction` varchar(16) character set utf8 default NULL,
  KEY `itemid` (`itemid`,`suffix`,`factor`,`enchant`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `price_history_by_faction`
--

DROP TABLE IF EXISTS `price_history_by_faction`;
CREATE TABLE `price_history_by_faction` (
  `itemid` int(10) unsigned NOT NULL,
  `faction` varchar(16) NOT NULL,
  `day` date NOT NULL,
  `rolling_25` float NOT NULL default '0',
  `rolling_50` float NOT NULL default '0',
  `rolling_75` float NOT NULL default '0',
  `rolling_average` float NOT NULL,
  `rolling_standard_deviation` float NOT NULL,
  `average` float NOT NULL,
  `standard_deviation` float NOT NULL,
  `auction_count` int(10) unsigned NOT NULL,
  KEY `itemid` (`itemid`,`faction`),
  KEY `day` (`day`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `price_history_by_item`
--

DROP TABLE IF EXISTS `price_history_by_item`;
CREATE TABLE `price_history_by_item` (
  `itemid` int(10) unsigned NOT NULL,
  `day` date NOT NULL,
  `rolling_25` float NOT NULL default '0',
  `rolling_50` float NOT NULL default '0',
  `rolling_75` float NOT NULL default '0',
  `rolling_average` float NOT NULL,
  `rolling_standard_deviation` float NOT NULL,
  `average` float NOT NULL,
  `standard_deviation` float NOT NULL,
  `auction_count` int(10) unsigned NOT NULL,
  KEY `itemid` (`itemid`),
  KEY `day` (`day`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `price_history_by_server`
--

DROP TABLE IF EXISTS `price_history_by_server`;
CREATE TABLE `price_history_by_server` (
  `itemid` int(10) unsigned NOT NULL,
  `realm` varchar(24) NOT NULL,
  `faction` varchar(16) NOT NULL,
  `day` date NOT NULL,
  `rolling_25` float NOT NULL default '0',
  `rolling_50` float NOT NULL default '0',
  `rolling_75` float NOT NULL default '0',
  `rolling_average` float NOT NULL,
  `rolling_standard_deviation` float NOT NULL,
  `average` float NOT NULL,
  `standard_deviation` float NOT NULL,
  `auction_count` int(10) unsigned NOT NULL,
  KEY `itemid` (`itemid`,`realm`,`faction`),
  KEY `day` (`day`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `price_history_generic`
--

DROP TABLE IF EXISTS `price_history_generic`;
CREATE TABLE `price_history_generic` (
  `itemid` int(10) unsigned default NULL,
  `time` datetime NOT NULL,
  `price` decimal(15,4) unsigned default NULL,
  `minbid` decimal(15,4) unsigned default NULL,
  `curbid` decimal(15,4) unsigned default NULL,
  `buyout` decimal(15,4) unsigned default NULL,
  `seller` varchar(32) character set utf8 default NULL,
  `realm` varchar(24) character set utf8 default NULL,
  `faction` varchar(16) character set utf8 default NULL,
  KEY `itemid` (`itemid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `realm`
--

DROP TABLE IF EXISTS `realm`;
CREATE TABLE `realm` (
  `id` int(10) unsigned NOT NULL,
  `name` varchar(20) default NULL,
  PRIMARY KEY  (`id`),
  KEY `realm_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `realm_faction_summary`
--

DROP TABLE IF EXISTS `realm_faction_summary`;
CREATE TABLE `realm_faction_summary` (
  `realm` varchar(24) character set utf8 default NULL,
  `faction` varchar(16) character set utf8 default NULL,
  `auction_count` bigint(21) NOT NULL default '0',
  `last_scanned` datetime,
  `first_scanned` datetime
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2007-11-30 20:06:47
