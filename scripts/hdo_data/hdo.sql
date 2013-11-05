DROP TABLE IF EXISTS DO_terms;
CREATE TABLE `DO_terms` (
  `term_id` varchar(45) NOT NULL,
  `name` varchar(200) DEFAULT NULL,
  `def` text DEFAULT NULL,
  `comment` text DEFAULT NULL,
  `is_obsolete` tinyint(1) NOT NULL DEFAULT '0',
  KEY `is_obsolete` (`is_obsolete`),
  PRIMARY KEY (`term_id`),
  KEY `name` (`name`)
) ENGINE=InnoDB;



DROP TABLE IF EXISTS DO_term2term;
CREATE TABLE `DO_term2term` (
  `term_id` varchar(45) DEFAULT NULL,
  `is_a` varchar(45) DEFAULT NULL,
  KEY `term_id` (`term_id`),
  KEY `is_a` (`is_a`)
) ENGINE=InnoDB;



DROP TABLE IF EXISTS DO_synonyms;
CREATE TABLE `DO_synonyms` (
  `term_id` varchar(45) DEFAULT NULL,
  `synonym` text DEFAULT NULL,
   KEY `term_id` (`term_id`)
) ENGINE=InnoDB;


DROP TABLE IF EXISTS DO_xrefs;
CREATE TABLE `DO_xrefs` (
  `term_id` varchar(45) DEFAULT NULL,
  `xref_name` varchar(60) DEFAULT NULL,
  `xref_id` varchar(50) NOT NULL,
    KEY `term_id` (`term_id`),
  KEY `xref_name` (`xref_name`),
  KEY `xref_id` (`xref_id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS DO_altids;
CREATE TABLE `DO_altids` (
  `term_id` varchar(45) DEFAULT NULL,
  `alt_id` varchar(60) DEFAULT NULL,
  KEY `term_id` (`term_id`),
  KEY `alt_id` (`alt_id`)
) ENGINE=InnoDB;
