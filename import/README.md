#IYG Import
A Python script to import data to an IYG Web MySQL database.
<br />IYG Web can be found at <a href="https://github.com/wtsi-hgi/IYG-Web.git">IYG Web</a>.

##Requirements
* <a href="http://sourceforge.net/projects/mysql-python/">MySQLdb</a> (apt-get install python-mysqldb)
* IYG Web <a href="https://github.com/wtsi-hgi/IYG-Web/blob/master/iyg.sql">iyg.sql</a> structure deployed to a MySQL instance

##Usage
`./import.py db_user barcodes snps trait_variants results [--host] [--name] [-h]`

##Import Files
Example data files are provided in the example\_data/ directory.

##Contributors
* Sam Nicholls &lt;sn8@sanger.ac.uk&gt;

##License
IYG Import is distributed under the GNU Lesser General Public License (LGPL 3).
<br />See LICENSE.txt

##Copyright
Copyright &copy; 2012 Genome Research Ltd.
