SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

CREATE SCHEMA IF NOT EXISTS `iyg` ;
USE `iyg` ;

-- -----------------------------------------------------
-- Table `iyg`.`profiles`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `iyg`.`profiles` ;

CREATE  TABLE IF NOT EXISTS `iyg`.`profiles` (
  `profile_id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
  `barcode` VARCHAR(15) NOT NULL ,
  `consent_flag` TINYINT(1) UNSIGNED NOT NULL ,
  `public_id` VARCHAR(40) NOT NULL ,
  PRIMARY KEY (`profile_id`) )
ENGINE = InnoDB
AUTO_INCREMENT = 1
DEFAULT CHARACTER SET = latin1;

CREATE UNIQUE INDEX `barcode` ON `iyg`.`profiles` (`barcode` ASC) ;


-- -----------------------------------------------------
-- Table `iyg`.`snps`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `iyg`.`snps` ;

CREATE  TABLE IF NOT EXISTS `iyg`.`snps` (
  `snp_id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
  `rs_id` VARCHAR(40) NOT NULL ,
  `name` VARCHAR(255) NOT NULL ,
  `description` TEXT NOT NULL ,
  PRIMARY KEY (`snp_id`) )
ENGINE = InnoDB
AUTO_INCREMENT = 1
DEFAULT CHARACTER SET = latin1;

CREATE INDEX `rs_id` ON `iyg`.`snps` (`rs_id` ASC) ;


-- -----------------------------------------------------
-- Table `iyg`.`variants`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `iyg`.`variants` ;

CREATE  TABLE IF NOT EXISTS `iyg`.`variants` (
  `variant_id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
  `snp_id` INT(10) UNSIGNED NOT NULL ,
  `genotype` VARCHAR(5) NOT NULL ,
  `popfreq` DECIMAL(10,4) NOT NULL ,
  PRIMARY KEY (`variant_id`) ,
  CONSTRAINT `snp_id`
    FOREIGN KEY (`snp_id` )
    REFERENCES `iyg`.`snps` (`snp_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
AUTO_INCREMENT = 1
DEFAULT CHARACTER SET = latin1;

CREATE UNIQUE INDEX `snp_genotype_composite` ON `iyg`.`variants` (`snp_id` ASC, `genotype` ASC) ;

CREATE INDEX `snp_id` ON `iyg`.`variants` (`snp_id` ASC) ;

CREATE INDEX `snp_id_idx` ON `iyg`.`variants` (`snp_id` ASC) ;


-- -----------------------------------------------------
-- Table `iyg`.`results`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `iyg`.`results` ;

CREATE  TABLE IF NOT EXISTS `iyg`.`results` (
  `result_id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT ,
  `profile_id` INT(11) UNSIGNED NOT NULL ,
  `variant_id` INT(11) UNSIGNED NOT NULL ,
  `confidence` DECIMAL(5,2) NOT NULL ,
  PRIMARY KEY (`result_id`) ,
  CONSTRAINT `profile_id`
    FOREIGN KEY (`profile_id` )
    REFERENCES `iyg`.`profiles` (`profile_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `result_variant_id`
    FOREIGN KEY (`variant_id` )
    REFERENCES `iyg`.`variants` (`variant_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
AUTO_INCREMENT = 1
DEFAULT CHARACTER SET = latin1;

CREATE INDEX `profile_variant_composite` ON `iyg`.`results` (`profile_id` ASC, `variant_id` ASC) ;

CREATE INDEX `profle_id_idx` ON `iyg`.`results` (`profile_id` ASC) ;

CREATE INDEX `variant_id_idx` ON `iyg`.`results` (`variant_id` ASC) ;


-- -----------------------------------------------------
-- Table `iyg`.`traits`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `iyg`.`traits` ;

CREATE  TABLE IF NOT EXISTS `iyg`.`traits` (
  `trait_id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
  `name` VARCHAR(255) NOT NULL ,
  `description` TEXT NOT NULL ,
  `predictability` INT(1) NOT NULL ,
  `active_flag` TINYINT(1) UNSIGNED NOT NULL ,
  `handler` VARCHAR(50) NOT NULL ,
  PRIMARY KEY (`trait_id`) )
ENGINE = InnoDB
AUTO_INCREMENT = 1
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `iyg`.`variants_traits`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `iyg`.`variants_traits` ;

CREATE  TABLE IF NOT EXISTS `iyg`.`variants_traits` (
  `variant_trait_id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
  `variant_id` INT(10) UNSIGNED NOT NULL ,
  `trait_id` INT(10) UNSIGNED NOT NULL ,
  `value` VARCHAR(255) NOT NULL ,
  `description` TEXT NOT NULL ,
  PRIMARY KEY (`variant_trait_id`) ,
  CONSTRAINT `trait_id`
    FOREIGN KEY (`trait_id` )
    REFERENCES `iyg`.`traits` (`trait_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `variant_id`
    FOREIGN KEY (`variant_id` )
    REFERENCES `iyg`.`variants` (`variant_id` )
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
AUTO_INCREMENT = 1
DEFAULT CHARACTER SET = latin1;

CREATE UNIQUE INDEX `snp_variant_composite` ON `iyg`.`variants_traits` (`variant_id` ASC, `trait_id` ASC) ;

CREATE INDEX `variant_id` ON `iyg`.`variants_traits` (`variant_id` ASC) ;

CREATE INDEX `trait_id_idx` ON `iyg`.`variants_traits` (`trait_id` ASC) ;

CREATE INDEX `variant_id_idx` ON `iyg`.`variants_traits` (`variant_id` ASC) ;



SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
