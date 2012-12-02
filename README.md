#IYG Web
A web application written in Perl to serve genotyping results without the use of cookies or sessions; primarily for the Sanger Institute's "Inside your Genome" project.
<br />IYG Web requires <a href="https://github.com/SamStudio8/IYG-Web-Lib.git">IYG Web Lib</a>.

##Requirements
###IYG Web
* Web Server with Perl
* Python
* MySQL

###Perl
* <a href="https://github.com/SamStudio8/IYG-Web-Lib.git">IYG Web Lib</a>
* Moose
* DBI
* Crypt::OpenPGP
* CGI
* HTML::Template

###Python
Additionally, the data loader script requires:
* <a href="http://sourceforge.net/projects/mysql-python/">MySQLdb</a> (apt-get install python-mysqldb)

##Installation
* Deploy IYG Web to www directory
* Deploy IYG Web Lib to an appropriate Perl library directory
* Import the database structure (mysql < iyg.sql)
* Update database and private key credentials in iyg.conf and move safely outside of www, ensuring that the user who serves the application has the appropriate permissions to read the configuration
* Add the path to your configuration file in the App class
* Enter your public key in templates/login.tmpl and ensure the user who serves the application has the corresponding private key in its keyring
* Use the data loader to load results to the database

##Disclaimer
IYG Web is a tad rough around the edges and there will certainly be better ways to execute some of the things that have been done.
Notably you should be aware that:

* Database and Barcode Decryption Errors are not handled gracefully
* Results "Handlers" would have been much nicer as Moose classes
* A Renderer Moose class to handle tasks such as checking for the presence of a user's public id or barcode and calling the appropriate Result "Handler" would also have been nice
* Moose classing in general was somewhat abused

##Contributors
* Sam Nicholls &lt;sn8@sanger.ac.uk&gt;

##License
###IYG Web
IYG Web (including IYG Web Lib) is distributed under the GNU Affero General Public License (AGPL 3).
<br />See LICENSE.txt

###Bootstrap
IYG Web is distributed with Twitter Bootstrap which is available under Apache License v2.0

###jQuery and jQuery UI
IYG Web makes use of jQuery and jQuery UI APIs, both of which are distributed under the MIT License.

###Javascript Encryption
IYG Web is distributed with a series of Javascript files inside the encrypt/ directory, check the headers of these files for license information.
<br />Note the ambiguous reference to "the BSD License" at encrypt/sha1.js:6 refers to the Modified BSD License.

###IE Upgrade Warning
IYG Web is distributed with "ie6-upgrade-warning", which is made available under the MIT License.

##Copyright
Copyright &copy; 2012 Genome Research Ltd.
