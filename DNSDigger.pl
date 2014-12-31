########################################################################
# DNSdigger.pl version 0.1
# ----------------------------------------------------------------------
# Author:	Laura Guay
#		laura.guay@crowehorwath.com
#
# Purpose:  	To query DNS servers and identify the following records
#			MX, A, NS, PTR, TXT
#
# Note: SRV records are not supported within perl nslookup at the time of writing this script
#
# $changelog$
#   	08JAN2009 - Creation (L.Guay)
#	
########################################################################
########################################################################
#
# Usage Notes:
#    -d    Input File (List of domain names to query eg. google.com, yahoo.com)
#    -h    Print this help
#
# Example:
# dnsdigger.pl -d domainnames.txt
#
########################################################################
use Getopt::Long;      # Easy parsing of options
use Net::Nslookup;	   # Have nslookup functionality within the script

my $domainfile = '';		# Input file for list of domain names to query for  hostnames
my $help = '';				# Was help requested?
my $header = '';			#Header to display in output
my $desc = '';
-
# strip the options into their flags or variables
GetOptions('h' => \$help, 'd:s' => \$domainfile, 'l' => \$header);

#test to see if the help flag was thrown, if so, display help and quit.  Also display help if a file was not provided
if ($help or $domainfile=~/^$/){
	print "A perl script to query DNS servers for MX, A, NS, PTR, and TXT records.\n";
	print "\n";
	print "Flags:\n";
	print "    -d    Input File (List of domain names to query)\n";
	print "    -l    Print header in output (DOMAIN,IP-ADDRESS,HOSTNAME,SOURCE)\n";
	print "    -h    Print this help\n";
	print "\n";
	print "Example:\n";
	print "    dnsdigger.pl -d domainnames.txt\n";
	print "    dnsdigger.pl -d domainnames.txt -l print\n";
	print "    dnsdigger.pl -d domainnames.txt > output.txt\n";
	exit;	# end the perl script
}

#Open domain name file specified into an array @domainnames or error if input file cannot be read
open (domain,$domainfile) || die ("Could not open $domainfile");
@domainnames = <domain>;

if ($header){
	$desc = "DOMAIN,IP-ADDRESS,HOSTNAME,SOURCE\n";
	print $desc;
}

#Go through each line of the domain file & get domain name
foreach $domain (@domainnames) {
	chomp($domain);		#Clear any formatting before and after text on line
	
	my @recordTypes = ( "MX", "A", "NS", "PTR", "TXT" );
	
	foreach $recordType (@recordTypes) {
		my @recordValues = nslookup( host => $domain, type => $recordType );
		foreach $recordValue (@recordValues) {
			chomp( $recordValue );
			
			writeLine( $recordValue, $recordType );
		}
	}
}

sub writeLine {
	my $recordValue = $_[0];
	my $recordType = $_[1];
	my $hostname = "";
	my $ipAddress = "";
	
	# test to see if the record value is already an IP address
	if ( $recordValue =~ m/(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/ )
	{
		$ipAddress = $recordValue;
	}
	else
	{
		$hostname = $recordValue;
		$ipAddress = nslookup $recordValue;
	}
	
	print $domain.",".$ipAddress.",".$hostname.",".$recordType."\n";
}