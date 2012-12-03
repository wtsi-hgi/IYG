#!/usr/bin/env python
"""Import genotyping data to an Inside your Genome Database"""

__author__ = "Sam Nicholls <sn8@sanger.ac.uk>"
__copyright__ = "Copyright (c) 2012 Genome Research Ltd."
__version__ = 1.0
__license__ = "GNU Lesser General Public License V3"
__maintainer__ = "Joshua Randall <joshua.randall@sanger.ac.uk>"

#This program is free software: you can redistribute it and/or modify it under
#the terms of the GNU Lesser General Public License as published by the Free
#Software Foundation; either version 3 of the License, or (at your option) any
#later version.
#
#This program is distributed in the hope that it will be useful, but WITHOUT
#ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
#details.
#
#You should have received a copy of the GNU Lesser General Public License along
#with this program.  If not, see <http://www.gnu.org/licenses/>.

import MySQLdb # apt-get install python-mysqldb
import string
import random
import csv
import argparse
import re

class Delimited_text_header:
    """Process header line of TSV/CSV delimited text file"""
    def __init__(self, tsv_file, separator="\t"):
        """Get the header line from a tsv_file 
        (must be called immediately after opening before reading any lines)"""

        line = tsv_file.next()
        self._columns = {}
        self._headers = {}
        header_list = re.split(separator, line.strip())

        coli = 0
        for header in header_list:
            self._columns[header] = coli
            self._headers[coli] = header
            coli += 1

    def get_header_for_col(self, col):
        return self._headers[col]

    def get_col_for_header(self, header):
        return self._columns[header]

    def index_list(self, fields, header):
        field = fields[self._columns[header]]
        return field


class Data_Loader:
    """Provides functions to facilitate loading of data into an IYG Database"""

    def __init__(self, args):
        """Initialise the Database Connection and Cursor, call import_main"""
        print(args.__dict__)
        self.db = self.connect(args.db_user, args.db_host, args.db_port, args.db_name)

        self.cur = self.db.cursor()
        self.import_main(args)
        
        
    def connect(self, user, host, port, name):
        """Attempts to connect to the database with the user, host and name
        parameters and prompts for the password."""
        password = raw_input("Password: ")
        try:
            return MySQLdb.connect(
                user=user,
                passwd=password,
                host=host,
                port=port,
                db=name)
        except MySQLdb.OperationalError, e:
            print "[FAIL]\tUnable to Establish Database Connection"
            print "\tError %d: %s" % (e.args[0], e.args[1])
            exit(0)

    def import_main(self, args):
        """Open file handlers and calls functions in the required order to 
        import the data to the IYG database"""

        if(args.purge_all is not None):
            self.purge_db()

        if(args.barcodes_file is not None):
            barcodes_file = open(args.barcodes_file, 'r')
            self.import_profiles(barcodes_file)
 
        if(args.snp_info_file is not None):
            snp_info = open(args.snp_info_file, 'r')
            self.import_snp_info(snp_info)
        
        if(args.trait_info_file is not None):
            trait_info = open(args.trait_info_file, 'r')
            traits = self.import_trait_info(trait_info)

        if(args.snp_trait_genotype_effect_file is not None):
            snp_trait_genotype_effect = open(args.snp_trait_genotype_effect_file, 'r')
            self.import_snp_trait_genotype_effect(snp_trait_genotype_effect)

        if(args.results_file is not None):
            results_map = open(args.results_file + '.map', 'r')
            results_ped = open(args.results_file + '.ped', 'r')
            self.import_results_ped(results_map, results_ped)

        self.cur.close()
        self.db.close()

    def purge_db(self):
        """Purge the current data from the database"""
        print "[_DB_]\tPurging Existing Records before New Import"

        try:
            self.cur.execute("DELETE FROM profiles")
            self.cur.execute("DELETE FROM snps")
            self.cur.execute("DELETE FROM traits")
            self.db.commit()
        except MySQLdb.OperationalError, e:
            print "[FAIL]\tUnable to purge current records before new import"
            print "\tError %d: %s" % (e.args[0], e.args[1])
            exit(0)

    def import_profiles(self, barcodes):
        """Process the list of barcodes, inserting a new profile row in the
        database for each consenting barcode"""
        print "[READ]\tImporting Barcode List"

        SALT_CHARS = string.ascii_uppercase + string.digits

        for line in barcodes:
            if line[0] == "#": #Skip comments
                continue

            barcode = line.strip()

            # Generate a public id by salting the barcode
            public_id = (barcode +
                ''.join(random.choice(SALT_CHARS) for char in range(10)))

            try:
                self.cur.execute(
                    "INSERT INTO profiles (barcode, consent_flag, public_id)"
                    "VALUES (%s, %s, SHA1(%s))", (barcode, 1, public_id))
                self.db.commit()
            except MySQLdb.Error, e:
                print "[FAIL]\tBarcode %s not added to database" % barcode
                print "\tError %d: %s" % (e.args[0], e.args[1])

        barcodes.close()


        

    def import_snp_info(self, snp_info):
        """Process the SNP data file, inserting SNP and Variant rows to the
        database for each SNP and trio of genotypes"""
        print "[READ]\tImporting SNP Info"

        header = Delimited_text_header(snp_info, "\t")

        seen = []
        for line in snp_info:
            fields = line.strip().split("\t")

            # SNP Info Record 
            # SNP     Genos   Ploidy
            rsid = header.index_list(fields,"SNP")
            name = rsid
            desc = rsid
            genotypes = header.index_list(fields,"Genos")
            ploidy = header.index_list(fields,"Ploidy")

            if rsid in seen:
                print "[WARN]\tSkipping duplicate SNP "+rsid
                continue

            try:
                self.cur.execute(
                    "INSERT INTO snps (rs_id, name, description, ploidy)"
                    "VALUES (%s, %s, %s, %s)", (rsid, name, desc, ploidy))
                self.db.commit()
                snp_dbid = self.cur.lastrowid 
            except MySQLdb.Error, e:
                print "[FAIL]\tSNP %s not added to database" % rsid
                print "\tError %d: %s" % (e.args[0], e.args[1])
                continue
            
            # s['genotypes'] = {}
            for g in genotypes.split(","):
                g = g.strip() # Remove any spaces between commas
                try:
                    self.cur.execute(
                        "INSERT INTO variants (snp_id, genotype, popfreq)"
                        "VALUES (%s, %s, %s)", (snp_dbid, g, 0))
                    self.db.commit()
                    # s['genotypes'][g] = self.cur.lastrowid
                except MySQLdb.Error, e:
                    print ("[FAIL]\tGenotype %s for SNP %s not added to database" 
                        % (g, rsid))
                    print "\tError %d: %s" % (e.args[0], e.args[1])

            seen.append(rsid)
            #s['dbid'] = snp_dbid
            #snp_dict[rsid] = s

        snp_info.close()
        #return snp_dict


    def import_trait_info(self, trait_info):
        """Process the Traits file, adding each Trait to the database"""
        print "[READ]\tImporting Traits"

        header = Delimited_text_header(trait_info, "\t")

        for line in trait_info:
            fields = line.strip().split("\t")

            # Trait Info Record 
            # TraitName       ShortName       Desc    Pred    Units   Mean    SD      Type
            name = header.index_list(fields,"TraitName")
            short_name = header.index_list(fields,"ShortName")
            description = header.index_list(fields,"Desc")
            predictability = header.index_list(fields,"Pred")
            units = header.index_list(fields,"Units")
            mean = header.index_list(fields,"Mean")
            sd = header.index_list(fields,"SD")
            handler = header.index_list(fields,"Type")

            if mean == "NA":
                mean = None

            if sd == "NA":
                sd = None

            if handler == "-":
                handler = "" # IYG Web will use default trait handler

            try:
                self.cur.execute(
                    "INSERT INTO traits (name, description, predictability, active_flag, handler, "
                    "short_name, units, mean, sd) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)", 
                    (name, description, predictability, 1, handler, short_name, units, mean, sd))
                self.db.commit()
                current_trait_dbid = self.cur.lastrowid

            except MySQLdb.Error, e:
                current_trait_dbid = 0
                print "[FAIL]\tTrait '%s' not added to database" % name
                print "\tError %d: %s" % (e.args[0], e.args[1])

        trait_info.close()


    def import_snp_trait_genotype_effect(self, snp_trait_genotype_effect):
        """Process the SNP-trait-genotype-effect file, inserting rows to the
        database for each SNP-trait and trio of genotypes"""
        print "[READ]\tImporting SNP-trait-genotype-effect file"

        header = Delimited_text_header(snp_trait_genotype_effect, "\t")

        seen = []
        for line in snp_info:
            fields = line.strip().split("\t")

            # SNP-trait-genotype-effect file
            # SNP     Trait   Genotype        Effect
            rsid = header.index_list(fields,"SNP")
            trait = header.index_list(fields,"Trait")
            genotype = header.index_list(fields,"Genotype")
            value = header.index_list(fields,"Effect")
            desc = value
 
            if current_trait_dbid == 0 or not current_snp:
                # Skip this record if the current trait or SNP are not set
                continue
            
            if genotype in snps[current_snp]['genotypes']:
                variant = snps[current_snp]['genotypes'][genotype]
            elif genotype[::-1] in snps[current_snp]['genotypes']:
                variant = snps[current_snp]['genotypes'][genotype[::-1]]
            else:
                print ("[WARN]\t"+genotype+
                       " variant not found in SNP import for SNP "+current_snp)
                continue

            try:
                self.cur.execute(
                    "INSERT INTO variants_traits (variant_id, trait_id, "
                    "value, description) VALUES (%s, %s, %s, %s)",
                    (variant, current_trait_dbid, value, desc))
                self.db.commit()
            except MySQLdb.Error, e:
                print ("[FAIL]\tTrait-Variant for Trait '%s', SNP %s and "
                       "Genotype %s not added to database" % 
                       (name, current_snp, genotype))
                print "\tError %d: %s" % (e.args[0], e.args[1])
                
            trait_variants.close()
                

    def import_results_ped(self, results_map, results_ped):
        """Process the PED/MAP, adding a new result record for each SNP-sample with a valid call"""
        print "[READ]\tImporting Results File (PED/MAP)"
        
        popcounts = {} # Store counts for each detected variant
        errors = { # Used to suppress repeating errors
            'snps': [],
            'barcodes': []}
        
        #parse the header information
        header_names = []
        for header_item in results_map:
            snp = header_item.strip().split("\t");
            header_names.append(snp[1])

        for current_snp_rs in header_names:
            snp_info = get_snp_info(current_snp_rs)

            if current_snp_rs not in snps:
                if current_snp_rs not in errors['snps']:
                    print ("[WARN]\tSNP %s not found in SNP import" 
                           % (current_snp_rs))
                    errors['snps'].append(current_snp_rs)
                continue

        valuesTuples = []
        lineno = 1
        for row in results:
            fields = row.strip().split(" ")

            # get the user this row corresponds to
            current_barcode = fields[1].strip()
            profile_dbid = get_profile_dbid(current_barcode)
            if not profile_dbid:
                print ("[WARN]\tBarcode# %s not found in DB and is being skipped."
                           % (current_barcode))
                errors['barcodes'].append(current_barcode)
                continue

            # now parse the SNPs
            for snp_pos in range(0,len(header_names)):
                current_snp_rs = header_names[snp_pos]

                
                snp_info = get_snp_info(current_snp_rs)
                if not snp_info:
                    print ("[WARN]\tSNP %s not found in DB and is being skipped." % (snp_info))
                    continue
                
                call = fields[6+snp_pos*2]+fields[6+snp_pos*2+1]
                
                if call == "00":
                    continue
                
                # Check the call for this SNP was imported
                variant_dbid = get_variant_dbid(current_snp_rs, call)
                if not variant_dbid:
                    print ("[WARN]\tGenotype %s for SNP %s not found in DB" 
                           % (call, current_snp_rs))
                    continue
                
                # Update the count for this variant
                # TODO: this should be moved to after the import!
                if variant_dbid not in popcounts:
                    popcounts[variant_dbid] = 1
                else:
                    popcounts[variant_dbid] += 1
              
                valuesTuples.append((profile_dbid, variant_dbid)) 
          
            lineno += 1
          
        try:
            query = """INSERT INTO results (profile_id, variant_id, confidence) VALUES (%s, %s, 100)"""
            self.cur.executemany(query, valuesTuples)   
        except MySQLdb.Error, e:
            print "[FAIL]\tResults not added in the database"
            print "\tError %d: %s" % (e.args[0], e.args[1])
               
        results.close()
        self.update_popfreqs(snps, popcounts)


    def update_popfreqs(self, snps, popcounts):
        """Using the counters from the results import, calculate the population
        frequency for each variant at each SNP site and update the database"""

        for snp in snps:
            snp_variants = dict(((k,popcounts[k]) for k in snps[snp]['genotypes'].values() if k in popcounts))
            total = sum(snp_variants.values())

            for v in snp_variants:
                current_freq = (float(snp_variants[v])/float(total)) * 100
                try:
                    self.cur.execute(
                        "UPDATE variants SET popfreq = %s WHERE variant_id = %s",
                        (round(current_freq, 4), v))
                    self.db.commit()
                except MySQLdb.Error, e:
                    print ("[FAIL]\tPopulation frequency for variant at SNP %s"
                        " with DBID %s was not updated" % (snp, v))
                    print "\tError %d: %s" % (e.args[0], e.args[1])

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=(
        "Import genotyping data to an Inside your Genome Database"))

    # options that can override defaults
    parser.add_argument('--db-host', metavar="db_host", default="127.0.0.1", dest="db_host",
        help=("Database Host [default: 127.0.0.1]"))
    parser.add_argument('--db-port', type=int, metavar="db_port", default="3380", dest="db_port",
        help=("Database Port [default: 3390]"))
    parser.add_argument('--db-name', metavar="db_name", default="iyg", dest="db_name",
        help=("Database Name [default: iyg]"))

    # required "option" to specify database username (will prompt for password, which can be piped into stdin)
    parser.add_argument('--db-user', metavar="db_user", dest="db_user", required=True,
        help=("Database User"))

    # optional options
    parser.add_argument('--purge-all', dest="purge_all", action='store_true',
        help=("Purge all data from database before starting."))

    # optional files from which to import (if none are specified, nothing is done)

    ## you need a barcodes file loaded first which will limit samples to those listed
    parser.add_argument('--barcodes-file', metavar="barcodes_file", dest="barcodes_file",
        help=("New line delimited list of *consenting* barcodes"))

    ## then you need to load trait info, snp info, and snp-trait-genotype-effect files
    parser.add_argument('--trait-info-file', metavar="trait_info_file", dest="trait_info_file",
        help=("Trait Info File"))
    parser.add_argument('--snp-info-file', metavar="snp_info_file", dest="snp_info_file", 
        help=("SNP Info File"))
    parser.add_argument('--snp-trait-genotype-effect-file', metavar="snp_trait_genotype_effect_file", dest="snp_trait_genotype_effect_file",
        help=("SNP-Trait-Genotype-Effect File"))

    ## finally, you need to load the results either from a CSV or PED/MAP
    parser.add_argument('--results-file', metavar="results_file", dest="results_file",
        help=("Fluidigm Results (Converted to CSV)"))

    Data_Loader(parser.parse_args())


