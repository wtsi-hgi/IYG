#!/usr/bin/env python
"""Import genotyping data to an Inside your Genome Database"""
from gnome_sudoku.main import profile_me
from gi.overrides.GLib import Variant

__author__ = "Sam Nicholls <sn8@sanger.ac.uk>"
__copyright__ = "Copyright (c) 2012 Genome Research Ltd."
__version__ = 1.0
__license__ = "GNU Lesser General Public License V3"
__maintainer__ = "Sam Nicholls <sam@samnicholls.net>"

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

class Data_Loader:
    """Provides functions to facilitate loading of data into an IYG Database"""

    def __init__(self, args):
        """Initialise the Database Connection and Cursor, call Execute"""
        print args.host, args.barcodes
        
        self.db = self.connect(args.user, args.host, args.port, args.name)
        self.cur = self.db.cursor()
        self.execute(args)

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
            

    def execute(self, args):
        """Open file handlers and calls functions in the required order to 
        import the data to the IYG database"""

        barcodes_file = open(args.barcodes, 'r')
        snps_file = open(args.snps, 'r')
        trait_variants_file = open(args.trait_variants, 'r')
        results_map_file = open(args.results + '.map', 'r')
        #separate option
        results_ped_file = open(args.results + '.ped', 'r')


        # option : -- purgeall, if not: purge everything except for results
        self.purge_db()
# --
        users = self.import_profiles(barcodes_file)
        snps = self.import_snps(snps_file)
        self.import_trait_variants(trait_variants_file, snps)
        # --flag to do this, if yoiu specified either map, ped or results.csv, do purge all and import results
        self.import_results(results_map_file, results_ped_file, users, snps)

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

        users_dict = {}
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
                users_dict[barcode] = self.cur.lastrowid
            except MySQLdb.Error, e:
                print "[FAIL]\tBarcode %s not added to database" % barcode
                print "\tError %d: %s" % (e.args[0], e.args[1])

        barcodes.close()
        return users_dict

    def import_snps(self, snps):
        """Process the SNP data file, inserting SNP and Variant rows to the
        database for each SNP and trio of genotypes"""
        print "[READ]\tImporting SNP List"

        snp_dict = {}
        seen = []
        for record in snps:
            if record[0] == "#": #Skip comments
                continue

            s = {}
            fields = record.strip().split("\t")
            rsid = fields[0]
            name = fields[1]
            desc = fields[2]
            genotypes = fields[3]

            if rsid in seen:
                print "[WARN]\tSkipping duplicate SNP "+rsid
                continue

            try:
                self.cur.execute(
                    "INSERT INTO snps (rs_id, name, description)"
                    "VALUES (%s, %s, %s)", (rsid, name, desc))
                self.db.commit()
                snp_dbid = self.cur.lastrowid
            except MySQLdb.Error, e:
                print "[FAIL]\tSNP %s not added to database" % rsid
                print "\tError %d: %s" % (e.args[0], e.args[1])
                continue
            
            s['genotypes'] = {}
            for g in genotypes.split(","):
                g = g.strip() # Remove any spaces between commas
                try:
                    self.cur.execute(
                        "INSERT INTO variants (snp_id, genotype, popfreq)"
                        "VALUES (%s, %s, %s)", (snp_dbid, g, 0))
                    self.db.commit()
                    s['genotypes'][g] = self.cur.lastrowid
                except MySQLdb.Error, e:
                    print ("[FAIL]\tGenotype %s for SNP %s not added to database" 
                        % (g, rsid))
                    print "\tError %d: %s" % (e.args[0], e.args[1])

            seen.append(rsid)
            s['dbid'] = snp_dbid
            snp_dict[rsid] = s

        snps.close()
        return snp_dict

    def import_trait_variants(self, trait_variants, snps):
        """Process the Trait-Variant Relationship file, adding each Trait to
        the database along with a row for each Variant for all SNPs that are
        listed below the Trait"""
        print "[READ]\tImporting Trait-Variant Relationships"
        current_trait_dbid = 0
        current_snp = ""

        lineno = 1
        for line in trait_variants:
            fields = line.strip().split("\t")

            # Trait Record
            if fields[0] == "=":
                name = fields[1]
                desc = fields[2]
                predictability = fields[3]
                handler = fields[4]

                if handler == "-":
                    handler = "" # IYG Web will use default trait handler

                try:
                    self.cur.execute(
                        "INSERT INTO traits (name, description, active_flag, "
                        "predictability, handler) VALUES (%s, %s, %s, %s, %s)", 
                        (name, desc, 1, predictability, handler))
                    self.db.commit()
                    current_trait_dbid = self.cur.lastrowid

                except MySQLdb.Error, e:
                    current_trait_dbid = 0
                    print "[FAIL]\tTrait '%s' not added to database" % name
                    print "\tError %d: %s" % (e.args[0], e.args[1])

            # SNP Record for Current Trait
            elif fields[0] == ">":
                if current_trait_dbid == 0:
                    continue

                if fields[1] in snps:
                    current_snp = fields[1]
                else:
                    current_snp = ""
                    print ("[WARN]\tSNP %s not found in SNP import " % fields[1])
                    continue

            # Variant Record for Current SNP
            elif fields[0] == ">>":
                if current_trait_dbid == 0 or not current_snp:
                    # Skip this record if the current trait or SNP are not set
                    continue

                genotype = fields[1]
                value = fields[2]
                desc = fields[3]

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
                        "Genotype %s at Line# %s not added to database" % 
                        (name, current_snp, genotype, lineno))
                    print "\tError %d: %s" % (e.args[0], e.args[1])

            lineno += 1
        trait_variants.close()

    def import_results_CSV(self, results, users, snps):
        """Process the CSV of genotype call results, adding a new result record
        for each row with a valid call"""
        print "[READ]\tImporting Results File"

        popcounts = {} # Store counts for each detected variant
        errors = { # Used to suppress repeating errors
            'snps': [],
            'barcodes': []}

        for i in range(0, 16):
            results.readline() #Skip the header information

        lineno = 17
        for row in results:
            fields = row.strip().split(",")
            
            # Do not insert failed calls
            if fields[10] == "No Call":
                continue

            current_barcode = fields[6].strip()
            if current_barcode not in users:
                if current_barcode not in errors['barcodes']:
                    print ("[WARN]\tBarcode# %s not found in profile import" 
                        % (current_barcode))
                    errors['barcodes'].append(current_barcode)
                continue
            else:
                profile_dbid = users[current_barcode]

            current_snp_rs = fields[3]
            if current_snp_rs not in snps:
                if current_snp_rs not in errors['snps']:
                    print ("[WARN]\tSNP %s not found in SNP import" 
                        % (current_snp_rs))
                    errors['snps'].append(current_snp_rs)
                continue

            confidence = fields[9]
            call = ''.join(fields[11].split(":"))

            if call == "":
                continue
            
            # Check the call for this SNP was imported
            if call in snps[current_snp_rs]['genotypes']:
                variant_dbid = snps[current_snp_rs]['genotypes'][call]
            elif call[::-1] in snps[current_snp_rs]['genotypes']:
                variant_dbid = snps[current_snp_rs]['genotypes'][call[::-1]]
            else:
                print ("[WARN]\tGenotype %s for SNP %s not found in SNP import" 
                    % (call, current_snp_rs))
                continue
            # unknown confidence
            confidence = 101
        
            #Update the count for this variant
            if variant_dbid not in popcounts:
                popcounts[variant_dbid] = 1
            else:
                popcounts[variant_dbid] += 1
                
            try:
                self.cur.execute(
                    "INSERT INTO results (profile_id, variant_id, confidence) "
                    "VALUES (%s, %s, %s)", (profile_dbid, variant_dbid, confidence))
                self.db.commit()
            except MySQLdb.Error, e:
                print "[FAIL]\tResult at Line# %s not added to database" % lineno
                print "\tError %d: %s" % (e.args[0], e.args[1])
            
            lineno += 1

        results.close()
        self.update_popfreqs(snps, popcounts)

    def import_results(self, map_data, results, users, snps):
        """Process the CSV of genotype call results, adding a new result record
            for each row with a valid call"""
        print "[READ]\tImporting Results File (PED)"
        
        popcounts = {} # Store counts for each detected variant
        errors = { # Used to suppress repeating errors
            'snps': [],
            'barcodes': []}
        
        #parse the header information
        header_names = []
        for header_item in map_data:
            snp = header_item.strip().split("\t");
            header_names.append(snp[1])

        for current_snp_rs in header_names:
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
            if current_barcode not in users:
                if current_barcode not in errors['barcodes']:
                    print ("[WARN]\tBarcode# %s not found in profile import" 
                           % (current_barcode))
                    errors['barcodes'].append(current_barcode)
                continue
            else:
                profile_dbid = users[current_barcode]
            
            # now parse the SNPs
            for snp_pos in range(0,len(header_names)):
                current_snp_rs = header_names[snp_pos]
                
                if current_snp_rs not in snps:
                    continue
                
                call = fields[6+snp_pos*2]+fields[6+snp_pos*2+1]
                
                if call == "00":
                    continue
                
                # Check the call for this SNP was imported
                if call in snps[current_snp_rs]['genotypes']:
                    variant_dbid = snps[current_snp_rs]['genotypes'][call]
                elif call[::-1] in snps[current_snp_rs]['genotypes']:
                    variant_dbid = snps[current_snp_rs]['genotypes'][call[::-1]]
                else:
                    print ("[WARN]\tGenotype %s for SNP %s not found in SNP import" 
                           % (call, current_snp_rs))
                    continue
                
                #Update the count for this variant
                if variant_dbid not in popcounts:
                    popcounts[variant_dbid] = 1
                else:
                    popcounts[variant_dbid] += 1
             
                '''query = """INSERT INTO `data` (frame, sensor_row, sensor_col, value) VALUES (%s, %s, %s, %s ) """

                for row, col, frame in zip(rows, cols, frames):
                        values.append((frame, row, col, data[row,col,frame]))
                    cur.executemany(query, values)'''

                valuesTuples.append((profile_dbid, variant_dbid)) 
#                try:
#                    self.cur.execute(
#                                     "INSERT INTO results (profile_id, variant_id, confidence) "
#                                     "VALUES (%s, %s, 101)", (profile_dbid, variant_dbid))
#                    self.db.commit()
#                except MySQLdb.Error, e:
#                    print "[FAIL]\tResult at Line# %s not added to database" % lineno
#                    print "\tError %d: %s" % (e.args[0], e.args[1])
#          
            lineno += 1
          
        try:
            query = """INSERT INTO results (profile_id, variant_id, confidence) VALUES (%s, %s, 101)"""
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
    parser.add_argument('--host', metavar="", default="127.0.0.1",
        help=("Database Host [default: 127.0.0.1]"))
    parser.add_argument('--port', type=int, metavar="", default="3380",
        help=("Database Port [default: 3390]"))
    parser.add_argument('--name', metavar="", default="iyg",
        help=("Database Name [default: iyg]"))
    parser.add_argument('user', metavar="user",
        help=("Database User"))
    parser.add_argument('--barcodes', metavar="barcodes",
        help=("New line delimited list of *consenting* barcodes"))
    parser.add_argument('--snps', metavar="snps",
        help=("SNP Data File"))
    parser.add_argument('--trait_variants', metavar="trait_variants",
        help=("Trait-Variant Relationship File"))
    parser.add_argument('--results', metavar="results",
        help=("Fluidigm Results (Converted to CSV)"))
    Data_Loader(parser.parse_args())
# everything except for results
