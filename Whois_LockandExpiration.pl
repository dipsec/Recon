# 
# This script attempts to determine the lock status and expiration dates of one or more domains by
# querying the Network Solutions website and attempting to parse the results.
# 
# Chris Woodbury, Crowe Horwath LLP
# August 2009
# 

use strict;
use Getopt::Long;
use LWP::Simple;

my $singleDomain = "";			# Name of an individual domain (instead of an input file)
my $inputFile = "";				# Input file with list of domains
my $outputFile = "";			# Output CSV file
my $help = "";					# Flag to show help

# strip the options into their flags or variables
GetOptions('h' => \$help, 'd:s', => \$singleDomain, 'i:s', => \$inputFile, 'o:s' => \$outputFile );

# Test to see if the help flag was thrown, if so, display help and quit.
if ( $help ){
	showHelp();
	exit;
}
# Display help if required parameters are blank
if ( $inputFile eq "" and $singleDomain eq "" ) {
	print "\nWARNING: Domain(s) to check must be specified with -i or -d.\n\n";
	showHelp();
	exit;
}



if ( $singleDomain ne "" )
{
	my $lockStatus = checkDomain( $singleDomain );
}
else
{
	open (INPUTFILE,"$inputFile") || die ("Could not open $inputFile for reading");
	if ( $outputFile ne "" ) {
		open (OUTPUTFILE,">$outputFile") || die ("Could not open $outputFile for writing");
	}
	
	while ( my $domainName = <INPUTFILE> )
	{
		chomp( $domainName );
		checkDomain( $domainName );
	}
	
	close( INPUTFILE );
	if ( $outputFile ne "" ) {
		close( OUTPUTFILE );
	}
}




sub checkDomain()
{
	my $domainName = $_[0];
	
	my $lockStatus = "";
	my $expirationDate = "";
	
	my $requestUrl = "http://www.networksolutions.com/whois/registry-data.jsp?domain=" . $domainName;
	my $whoisHtml = get( $requestUrl );
	
	if ( ! defined $whoisHtml )
	{
		print STDERR "Error making GET request to Network Solutions for $domainName\n";
	}
	else
	{
		$lockStatus = getLockStatus( $domainName, $whoisHtml );
		$expirationDate = getExpirationDate( $domainName, $whoisHtml );
	}
	
	outputStatus( $domainName, $lockStatus, $expirationDate );
}

sub getLockStatus()
{
	my $domainName = $_[0];
	my $whoisHtml = $_[1];
	
	my $lockStatus = "";
	
	if ( $whoisHtml =~ m/Status\:\s*(.+)[\r\n](.*Status\:\s*(.+)[\r\n])?(.*Status\:\s*(.+)[\r\n])?/i )
	{
		$lockStatus = $1;
		if ( $3 ne "" ) {
			$lockStatus = "$lockStatus|$3";
		}
		if ( $5 ne "" ) {
			$lockStatus = "$lockStatus|$5";
		}
	}
	
	return $lockStatus;
}

sub getExpirationDate()
{
	my $domainName = $_[0];
	my $whoisHtml = $_[1];
	
	my $expirationDate = "";
	
	if ( $whoisHtml =~ m/Expir.*?\:\s*(.+)[\r\n]/i )
	{
		$expirationDate = $1;
	}
	
	return $expirationDate;
}

sub outputStatus()
{
	my $domainName = $_[0];
	my $lockStatus = $_[1];
	my $expirationDate = $_[2];
	
	# if expiration date has commas in it, quote the whole string so that it won't break the CSV
	if ( $expirationDate =~ m/,/ ) {
		$expirationDate = "\"$expirationDate\"";
	}
	
	if ( $outputFile ne "" ) {
		print OUTPUTFILE "$domainName,$lockStatus,$expirationDate\n";
	} else {
		print STDOUT "$domainName,$lockStatus,$expirationDate\n";
	}
}

sub showHelp() {
	print "A script to pull the lock status and expiration dates for one or more domains.\n";
	print "\n";
	print "Arguments:\n";
    print "    -i    An input file with a list of domains\n";
    print "    -d    A single domain name to test\n";
    print "    -o    Output CSV file path and filename\n";
	print "Flags:\n";
    print "    -h    Prints this help\n";
    print "\n";
	print "Examples:\n";
	print "whoisLockStatus.pl -i domains.txt -o whoisLockStatus.csv\n";
	print "whoisLockStatus.pl -d google.com\n";
}
