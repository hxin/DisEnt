SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL';

DROP SCHEMA IF EXISTS `mydb` ;
CREATE SCHEMA IF NOT EXISTS `mydb` DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci ;
SHOW WARNINGS;
USE `mydb` ;

-- -----------------------------------------------------
-- Table `mydb`.`ontology`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`ontology` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `mydb`.`ontology` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `name` VARCHAR(255) NOT NULL ,
  `def` TEXT NULL ,
  `link` VARCHAR(255) NULL ,
  PRIMARY KEY (`id`, `name`) ,
  UNIQUE INDEX `name_UNIQUE` (`name` ASC) )
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `mydb`.`ontology_term`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`ontology_term` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `mydb`.`ontology_term` (
  `ontology_id` INT NOT NULL ,
  `id` VARCHAR(255) NOT NULL ,
  `name` VARCHAR(255) NOT NULL ,
  `def` TEXT NULL ,
  `comment` TEXT NULL ,
  `is_obsolete` TINYINT(1) NOT NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `mydb`.`ontology_term_synonym`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`ontology_term_synonym` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `mydb`.`ontology_term_synonym` (
  `term_id` VARCHAR(255) NOT NULL ,
  `term_synonym` TEXT NOT NULL )
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `mydb`.`ontology_term_dbxref`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`ontology_term_dbxref` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `mydb`.`ontology_term_dbxref` (
  `term_id` VARCHAR(255) NOT NULL ,
  `xref_dbname` VARCHAR(45) NOT NULL ,
  `xref_id` VARCHAR(45) NOT NULL )
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `mydb`.`source`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`source` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `mydb`.`source` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `name` VARCHAR(45) NOT NULL ,
  `description` TEXT NULL ,
  `link` VARCHAR(255) NULL ,
  `table_name` VARCHAR(45) NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `mydb`.`mapping_tool`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`mapping_tool` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `mydb`.`mapping_tool` (
  `id` INT NOT NULL ,
  `name` VARCHAR(45) NULL ,
  `des` VARCHAR(45) NULL ,
  `link` VARCHAR(45) NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `mydb`.`ontology_term2term`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`ontology_term2term` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `mydb`.`ontology_term2term` (
  `term1_id` VARCHAR(255) NOT NULL ,
  `term2_id` VARCHAR(255) NOT NULL ,
  `relationship` VARCHAR(45) NOT NULL )
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `mydb`.`ontology_term_altid`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`ontology_term_altid` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `mydb`.`ontology_term_altid` (
  `term_id` VARCHAR(255) NOT NULL ,
  `alt_id` VARCHAR(255) NOT NULL )
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `mydb`.`human_gene`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`human_gene` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `mydb`.`human_gene` (
  `ensembl_id` VARCHAR(45) NOT NULL ,
  `chromosome_name` VARCHAR(45) NOT NULL ,
  `start_position` INT NOT NULL ,
  `end_position` INT NOT NULL ,
  PRIMARY KEY (`ensembl_id`) )
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `mydb`.`entrez2ensembl`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`entrez2ensembl` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `mydb`.`entrez2ensembl` (
  `tax_id` INT NULL ,
  `entrezs_id` INT NOT NULL ,
  `ensembl_id` VARCHAR(45) NOT NULL )
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `mydb`.`human_homolog`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`human_homolog` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `mydb`.`human_homolog` (
  `human` VARCHAR(45) NOT NULL ,
  `homolog` VARCHAR(45) NOT NULL ,
  `homolog_type` VARCHAR(80) NOT NULL ,
  `dn` FLOAT NULL DEFAULT 0 ,
  `ds` FLOAT NULL DEFAULT 0 ,
  `species` VARCHAR(255) NOT NULL )
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `mydb`.`gene_history_entrez`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`gene_history_entrez` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `mydb`.`gene_history_entrez` (
  `tax_id` INT NOT NULL ,
  `gene_id` VARCHAR(45) NULL ,
  `discontinued_id` VARCHAR(45) NOT NULL ,
  `discontinued_symbol` VARCHAR(255) NULL ,
  `discontinue_date` VARCHAR(45) NULL )
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `mydb`.`source_v2p`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`source_v2p` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `mydb`.`source_v2p` (
  `variation_id` VARCHAR(45) NOT NULL ,
  `chromosome_name` VARCHAR(45) NOT NULL ,
  `position` INT NOT NULL ,
  `study_source` VARCHAR(255) NULL ,
  `study_ref` VARCHAR(255) NULL ,
  `phenotype` VARCHAR(500) NULL )
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `mydb`.`d2g`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`d2g` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `mydb`.`d2g` (
  `id` INT NOT NULL ,
  `gene` VARCHAR(45) NULL ,
  `disease` VARCHAR(45) NULL ,
  `source_id` VARCHAR(45) NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `mydb`.`human_variation`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`human_variation` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `mydb`.`human_variation` (
  `variation_id` VARCHAR(45) NOT NULL ,
  `chromosome_name` VARCHAR(45) NOT NULL ,
  `position` INT NOT NULL ,
  PRIMARY KEY (`variation_id`) )
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `mydb`.`human_variation2gene`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`human_variation2gene` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `mydb`.`human_variation2gene` (
  `variation_id` VARCHAR(45) NOT NULL ,
  `ensembl_id` VARCHAR(45) NOT NULL ,
  `position` VARCHAR(2) NOT NULL )
ENGINE = InnoDB;

SHOW WARNINGS;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

