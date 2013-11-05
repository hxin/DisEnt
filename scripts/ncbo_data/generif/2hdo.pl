#!/usr/bin/perl

use strict;
use DBI;
use Data::Dumper;

use LWP::UserAgent;
use URI::Escape;  
use XML::LibXML;
use PadWalker;
use Data::Dumper;


my($db,$host,$user,$psw)=@ARGV;
my $dbh   = DBI->connect ( "dbi:mysql:database=$db;host=$host;port=3306" , $user , $psw ) or die $DBI::errstr;
my $sth = $dbh->prepare("SELECT id,gene_id,rif FROM GeneRIF_basic;");
$sth->execute();
my $dis_ref = {};
while ( my @row = $sth->fetchrow_array ) {
#	$dis_ref->{$row[0]}->{'gene_id'}=$row[1];
#	$dis_ref->{$row[0]}->{'rif'}=$row[2];
	ncbo_annotator($row[0],$row[1],$row[2]);
}

#	print Dumper(%{$dis_ref});

for my $id ( keys %{$dis_ref} ) {
#	ncbo_annotator($id,$dis_ref->{$id}->{'gene_id'},$dis_ref->{$id}->{'rif'});
}






sub ncbo_annotator{
my($source_id,$gene_id,$des)=@_;
#print Dumper(@ARGV);

$|=1;
#http://data.bioontology.org/documentation#nav_annotator
my $API_KEY = 'f4f6d2e7-7726-402c-a4b0-6dfc533ad94e';  # Login to BioPortal (http://bioportal.bioontology.org/login) to get your API key 
my $AnnotatorURL = 'http://data.bioontology.org/annotator'; 
my $ontologies='DOID';
my $text = "EZH2 Y641 mutations are not associated with follicular lymphoma";
$text = $des;


my $format = "xml"; #xml, tabDelimited, text


# create a user agent
my $ua = new LWP::UserAgent;
$ua->agent('Annotator Client Example - Perl');
# create a parse to handle the output 
my $parser = XML::LibXML->new();
my %parameters = (		apikey=>$API_KEY,
                        text => $text,
                        ontologies=>$ontologies,
                        format=>$format
                 );
my $url = URI->new($AnnotatorURL);
$url->query_form(%parameters);
my $response = $ua->get($url);

# Check the outcome of the response
if ($response->is_success) {
	my $time = localtime();
#    print "Call successful at $time\n";
  
  	#print $response->decoded_content;  # this line prints out unparsed response 
  	
    # Parse the response 
#    print "Format: $format\n";
    if ($format eq "xml") {
 		my ($M_ConceptREF) = parse_annotator_response($response, $parser);

	# Print something for the user
#    print scalar (keys %{$M_ConceptREF}), " concepts found\n";

		if(%{$M_ConceptREF}){
			foreach my $c (keys %{$M_ConceptREF}){
   			 	print $source_id,"\t",$gene_id,"\t",$c,"\n";
   			 }    
		}
  }
}
else {
	my $time = localtime();
    #print $res->status_line, " at $time\n";
	print $response->content, " at $time\n";
}


###################
# parse response
###################
sub parse_annotator_response {
	my ($res, $parser) = @_;
        my $dom = $parser->parse_string($res->decoded_content);
	my $root = $dom->getDocumentElement();
	my %MatchedConcepts;
	
	my $results = $root->findnodes('/annotationCollection/annotation');
	foreach my $annotation ($results->get_nodelist){
                # Sample XPATH to extract concept info if needed
       	$annotation->findvalue('./annotatedClass/id') =~ /.+DOID_(\d+)/;
        my $id =$1; 
#        print "id = ", $annotation->findvalue('./annotatedClass/id'),"\n";
        my $annotations=$annotation->findnodes('./annotationsCollection/annotations');
        foreach ($annotations->get_nodelist){
        	my $nodes=$_;
#        	print "text = ", $nodes->findvalue('./text'),"\n";
#			print "matchType = ", $nodes->findvalue('./matchType'),"\n\n";
			$MatchedConcepts{"DOID:".$id} = $nodes->findvalue('./text');
        }
	}
		
#	my $results = $root->findnodes('/annotationCollection/annotation/annotationsCollection/annotations');
#	foreach my $c_node ($results->get_nodelist){
#                # Sample XPATH to extract concept info if needed
#		print "text = ", $c_node->findvalue('text'),"\n";
#		print "matchType = ", $c_node->findvalue('matchType'),"\n";
#		$MatchedConcepts{$c_node->findvalue('text')} = $c_node->findvalue('text');
#	}
	
	return (\%MatchedConcepts);
}




}
