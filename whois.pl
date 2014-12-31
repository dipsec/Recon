#!/usr/bin/perl

###################################################
# whois.pl
#
# v.0.1 06/28/2007 - J. Claudius - (Initial Draft)
# v.0.2 06/29/2007 - V. McLain - (Added -i, -d, -o opt codes)
# v.0.3 06/29/2007 - J. Claudius - (Added more comments, fixed usage to reflect opts, added examples)
# v.0.4 06/29/2007 - D. McKnight- (Added pretty pretty ASCII art and fixed opts calls)
# v0.5 07/07/2007 - V. McLain - (Changed output to individual files)
# v0.6 07/10/2007 - J. Claudius - (Added more consistency to usage info)
# v0.7 08/06/2007 - L. Morris - Added parsing functionality to output and output to Word Document
# ---------------------------------------------------------------------------------------------------------
# This perl script is designed to help automate the process of performing WHOIS 
# lookups and increase the consistency of what is recorded as evidence.
# ---------------------------------------------------------------------------------------------------------
# Need help? 
# Please send all bugs and functionality requests to JClaudius or VMcLain
#
# For any questions or comments relating to MS Word functionality
# please contact LMorris
###################################################

#Define includes
use Net::Whois::Raw qw($OMIT_MSG whois);
use Getopt::Std;

#Define opts
our($opt_i, $opt_d, $opt_o, $opt_h, $opt_p);

@a_Searches = (
			{	'name' => 'Registrant', 
				'display' => 'Registrant:', 
			},
			{	'name' => 'Domain Name:', 
				'display' => 'Domain Name:', 
				'singleline' => 1,
			},
			{	'name' => 'Record Expires on', 
				'display' => 'Record Expiry Date:', 
				'singleline' => 1,
			},
			{	'name' => 'Administrative Contact', 
				'display' => 'Administrative Contact:',
			},
			{	'name' => 'Technical Contact', 
				'display' => 'Technical Contact:',
			},
			{	'name' => 'Domain Servers', 
				'display' => 'Domain Servers:',
				'iplookup' => 1
			},
		);

#Gather opts values
getopts('i:d:o:h:p');

#Print usage if opt requirements not met
&usage if ($opt_h || (!$opt_i && !$opt_d));

#Perform who is if -d defined
&do_whois($opt_d) if $opt_d;

#Pull domains from file if -i defined
if ($opt_i) {
	open(DFILE, $opt_i) or die("[-] ERROR: File $opt_i can't be opened.\n");
	my @domains = <DFILE>;
	close(DFILE);
	#Loop through domains and call WHOIS subroutine
	foreach(@domains) {
		&do_whois(trim($_));
	}
}


#Print pretty pretty USAGE
sub usage() {
	print '  _    _  _   _  _____  ____  ___    ____  __'."\n";   
	print ' ( \/\/ )( )_( )(  _  )(_  _)/ __)  (  _ \(  )'."\n";  
	print '  )    (  ) _ (  )(_)(  _)(_ \__ \   )___/ )(__'."\n";
	print ' (__/\__)(_) (_)(_____)(____)(___/()(__)  (____)'."\n";
	print "\n whois.pl Version 0.7 \n";
	print "\n Usage: \n\t whois.pl -d <domainname> -o [outputdir] \n";
	print "\n Help:";
	print "\n \t -d: <domainname>: Single domain name";
	print "\n \t -i: <inputfile>: Input from list of domains";
	print "\n \t -o: [outputdir]: Output results to this directory";
	print "\n \t -h: Print this help summary page";
	print "\n \t -p: Parse the output into report style MS Word Documents\n";
	print "\n Examples:";
	print "\n \t whois.pl -d example.com";
	print "\n \t whois.pl -d example.com -o C:\\out";
	print "\n \t whois.pl -i listofdomainnames.txt -o C:\\out";
	print "\n \t whois.pl -p -i listofdomainnames.txt -o C:\\out";
	print "\n \t Hint\: Use \"\.\" to reference the local directory\n";
	exit;
}

#Print WHOIS
sub do_whois($) {
	#Perform WHOIS Lookup
	my $dname = $_[0];
	my $w_results = whois($dname);

	#Print Results
	if($w_results){
		print $w_results if !$opt_o && !$opt_p;
		&raw_output_file($dname, $w_results) if ($opt_o && !$opt_p);
		&parsed_output_file($dname, $w_results) if $opt_p;
	}
	
	#This should rarely happen but might as well have something spit out if it ever meets this condition
	else{
		print "[-] WARNING: No WHOIS result returned for ".$_[0]."\n";
	}
}

#Write output files
sub raw_output_file($$) {

	my $dname = $_[0];
	chomp($dname); # for some reason, a chomp of $_[0] doesn't work but this does? -vitaly
	my $ofile = "$opt_o\\WHOIS_$dname\.txt";
	
	if (!-d $opt_o) { 
		print "[*] $opt_o doesn't exist, creating it now.\n";
		mkdir($opt_o);
	}
	
    print "[*] Writing to $ofile\n";
	open(OUTF, "+>>$ofile") or die ("[-] ERROR: Can't open $ofile. \(Check for proper write permissions.\)\n");
	print OUTF $_[1];
	close(OUTF);

}

#################################################################
# The following code uses the Win32::OLE extensions to the 
# Microsoft ActiveX controls to create a Word table with the 
# information that we generally keep in reports.
#
# parsed_output_file()
#  ARGUMENTS: 1: (string) Directory for file Output
#             2: (string) WHOIS Results
#  RETURNS:   None
#################################################################

#Parse Output File for Info We Want
sub parsed_output_file() {
	my $v_Domain = $_[0];
	chomp($v_Domain);
	my @a_OutputFile = split(/\n/, $_[1]);
	my $v_OutputDir = "$opt_o\\WHOIS_PARSED\.txt";
	my $v_NumSearches = $#a_Searches+1;
	my $o_Word = null;
	my $o_Doc = null;
	my $o_Range = null;
	my $o_Table = null;

	if($opt_o) {
		use Win32::OLE;
		use Net::Nslookup;
		$o_Word = Win32::OLE->new('Word.Application') or
			die "Unable to start MS Word: $!\n";
		$o_Word->{'Visible'} = 0;
		$o_Doc = $o_Word->Documents->Add;
		$o_Table = $o_Doc->Tables->Add($o_Word->Selection->Range, $v_NumSearches, 2);
		$o_Table->Select();
	}

	my $c_Key = 1;
	for ($c_Search = 0; $c_Search <= $#a_Searches; $c_Search++) {
		$v_Search = $a_Searches[$c_Search]{'name'};
		my $v_Tmp = '';

		for($c_Line = 0; $c_Line <= $#a_OutputFile; $c_Line++) {
			$v_OutputFileLine = $a_OutputFile[$c_Line];

			if($v_OutputFileLine =~ /$v_Search/i) {

				if($opt_o) {
					$o_Table->Cell($c_Key,1)->{VerticalAlignment} = 'wdCellAlignVerticalCenter';
					$o_Table->Cell($c_Key,1)->Range->Font->{Bold} = 1;
					$o_Table->Cell($c_Key,1)->Range->ParagraphFormat->{Alignment} = 'wdAlignParagraphCenter';
					$o_Table->Cell($c_Key,1)->Range->{Text} = $a_Searches[$c_Search]{'display'};
				}
				print $v_Search."\n" if !$opt_o;

				if(defined $a_Searches[$c_Search]{'singleline'}) {

					$v_OutputFileLine =~ /$v_Search(.*)$/i;

					if($opt_o) {
						$o_Table->Cell($c_Key ,2)->Range->{Text} = trim($1);
					}
					print $v_OutputFileLine."\n" if !$opt_o;

				} else {
					for ($i = 1; 1==1; $i++) {
						if($a_OutputFile[$c_Line + $i] =~ /^\s*$/) {
							last;
						}

						if(defined $a_Searches[$c_Search]{'iplookup'}) {
							$tmp_Hostname = trim($a_OutputFile[$c_Line + $i]);
							$tmp_IP = nslookup(trim($a_OutputFile[$c_Line + $i]));
							$v_Tmp .= "$tmp_Hostname($tmp_IP)\n";
						} else {
							$v_Tmp .= trim($a_OutputFile[$c_Line + $i])."\n";
						}
					} # for i

					if($opt_o) {
						$o_Table->Cell($c_Key, 2)->Range->{Text} = $v_Tmp;
					}
					print $v_Tmp if !$opt_o;

				} #if $a_Searches
				last;
			} #if v_OutputFileLine
		} #for c_Line
		$c_Key++;
	} #foreach
	
	if($opt_o) {
		my $v_OutFile = "$opt_o\\WHOIS-$v_Domain\.doc";
    	print "[*] Writing \"$v_Domain\" to MS Word document $v_OutFile\n";
		$o_Doc->SaveAs($v_OutFile);
		$o_Doc->Close();
		$o_Word->Quit();
	}
}

sub trim() {
	my $v_String = shift;
	$v_String =~ s/^\s+//;
	$v_String =~ s/\s+$//;
	return $v_String;
}
