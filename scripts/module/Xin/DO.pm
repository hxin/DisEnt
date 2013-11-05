# some doc here
#
#
#

=head1 NAME

Xin::DO

=cut

# Let the code begin...

package Xin::DO;

use Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw();


use strict;
use Data::Dumper;

=head2 connectEBI

 Title   : connectEBI
 Usage   : my $registry = connectEBI
 Returns : db handle

=cut

sub parseDOFile{
	my $file_path=shift @_;
	my %return;
	my $line;
	my $start=0;
	my $line_count=0;
	my $current_id;
	open FILE, "<", $file_path or die $!;
READLINE:while ( <FILE> ) {
        $line=$_;
        chomp($line);
#       print Dumper(%return) if $line_count++==100;
#		last if $line_count++==3;
#		exit if $line_count>100;
        if($line =~ m/^\[Term\]/){
        	#start
        	$start=1;
        	#print $line;
        	next READLINE;        
        }
		if($start){
			if($line =~ m/^id:/){
	        	$current_id=(split(/ /, $line,2))[1];
	        	$return{$current_id}={};
	        	$return{$current_id}->{'synonyms'}=[];
	        	$return{$current_id}->{'xrefs'}=[];
	        	$return{$current_id}->{'parents'}=[];
	        	next READLINE;       
	        }elsif($line =~ m/^name:/){
	        	my $name=(split(/ /,$line,2))[1];
	        	$return{$current_id}->{'name'}=$name;
	        	next READLINE;
	        }elsif($line =~ m/^def:/){
	        	my $def=(split(/ /,$line,2))[1];
	        	$return{$current_id}->{'def'}=$def;
	        	next READLINE;
	        }elsif($line =~ m/^comment:/){
	        	my $comment=(split(/ /,$line,2))[1];
	        	$return{$current_id}->{'comment'}=$comment;
	        	next READLINE;
	        }elsif($line =~ m/^synonym:/){
	        	my $s=(split(/ /, $line,2))[1];
	        	push(@{$return{$current_id}->{'synonyms'}},$s);
	        	next READLINE;
	        }elsif($line =~ m/^xref:/){
	        	my $ref=(split(/ /,$line,2))[1];
	        	push(@{$return{$current_id}->{'xrefs'}},$ref);
	        	next READLINE;
	        }elsif($line =~ m/^is_a:/){
	        	my $parent=(split(/ /,$line,2))[1];
	        	$parent=(split(/ ! /,$parent,2))[0];
	        	push(@{$return{$current_id}->{'parents'}},$parent);
	        	next READLINE;
	        }elsif($line =~ m/^is_obsolete:/){
	        	my $obsolete=(split(/ /,$line,2))[1];
	        	$return{$current_id}->{'is_obsolete'}=$obsolete;
	        	next READLINE;
	        }elsif($line =~ m/^subset:/){
	        	#do nothing
	        	next READLINE;
	        }elsif($line =~ m/^\n/ ){
	        	#end
	        	$start=0;
	        	$current_id=0;
	        	next READLINE;
			}
		}#end start
    }
    return \%return;
}




sub findChildren{
	my ($dbh,$term)=@_;
	my $sth = $dbh->prepare("SELECT term_id FROM xin2.DO_term2term where is_a=?;");
	$sth->execute($term);
	return $sth->fetchall_arrayref;	
}

sub findChildren_array{
	my ($dbh,$term)=@_;
	my $sth = $dbh->prepare("SELECT term_id FROM xin2.DO_term2term where is_a=?;");
	$sth->execute($term);
	my @return;
	while ( my @row = $sth->fetchrow_array ) {
		push(@return,$row[0]);
	}
	return @return;	
}



sub hasChildren{
	my ($dbh,$term)=@_;
	my $sth = $dbh->prepare("SELECT term_id FROM xin2.DO_term2term where is_a=?;");
	$sth->execute($term);
	my $rows = $sth->rows;
	return ($rows == 0) ? 0 : 1;
}


##
#my $dbh=Xin::DB::connectNRG();
#my $t1='DOID:13078';
#my @done=findAllParents($dbh,$t1,());
#print Dumper(@done);
##
sub findAllParents{
	my ($dbh,$term,@done)=@_;
	my @t=findParents($dbh,$term);
	if(@t){
		foreach(@t){
			@done=findAllParents($dbh,$_,@done);
		}
	}
	push(@done,$term);	
	return @done;
}

sub findParents{
	my ($dbh,$term)=@_;
	my $sth = $dbh->prepare("SELECT distinct is_a FROM xin2.DO_term2term where term_id=?;");
	$sth->execute($term);
	my @ps;
	while ( my @row = $sth->fetchrow_array ) {
		push(@ps,$row[0]);
	}
	return (!@ps)? ():@ps; 
}


sub isChildof{
	my($dbh,$p,$c)=@_;
	my @done=findAllParents($dbh,$c,());
	return Xin::Utilities::isExistInArray($p,\@done);
}


# 'DOID:0014667' => [
#                              {
#                                'STY' => 'Disease',
#                                'String' => 'disease of metabolism',
#                                'Source ID' => 'T5',
#                                'SUI' => 'T100004',
#                                'LUI' => 'L100004',
#                                'TUI' => 'T001',
#                                'Term_Type' => 'PT',
#                                'Term_Status' => 'P',
#                                'SAB' => 'HDO'
#                              },
#                              {
#                                'STY' => 'Disease',
#                                'String' => 'metabolic disease ',
#                                'Source ID' => 'T5',
#                                'SUI' => 'T100010',
#                                'LUI' => 'L100010',
#                                'TUI' => 'T001',
#                                'Term_Type' => 'NP',
#                                'Term_Status' => 'S',
#                                'SAB' => 'HDO'
#                              }
#                            ]
sub buildDOObjectFromDB{
my $dbh=Xin::DB::connectNRG();
my $LUI=100000;
my $SUI=100000;
my $SAB="HDO";
my $Source_id="T5";
my $STY="Disease";
my $TUI="T001";
my $do={};
my $sth = $dbh->prepare("SELECT * FROM xin2.DO_terms where is_obsolete='false';");
$sth->execute();
while ( my @row = $sth->fetchrow_array ) {
	$do->{$row[0]}=[];
	my $hash={};
	
	#MRCON
	$hash->{'String'}=$row[1];
	$hash->{'SUI'}="T".$SUI++;
	$hash->{'LUI'}="L".$LUI++;
	$hash->{'Term_Status'}="P";
	#MRSO
	$hash->{'SAB'}=$SAB;
	$hash->{'Term_Type'}="PT";
	$hash->{'Source ID'}="T5";
	#MRSTY
	$hash->{'TUI'}=$TUI;
	$hash->{'STY'}=$STY;
	
	
	push(@{$do->{$row[0]}},$hash);
	
}
foreach my $id(keys %{$do}){
	$sth = $dbh->prepare("
SELECT synonym FROM xin2.DO_synonyms where term_id=?
union distinct
select distinct umls.STR from xin2.DO_do2umls as d left join umls.MRCONSO as umls on d.umls_acc=umls.CUI
where umls.LAT='ENG' and do_acc=?;");
	$sth->execute($id,$id);
	while ( my @row = $sth->fetchrow_array ) {
		#$row[0] =~ m/^"(.+)".+\[(.+)\]/;
		#$row[0] =~ m/^"(.+)"/;
		my $hash;
		
		#MRCON
		$hash->{'String'}=$row[0];
		$hash->{'SUI'}="T".$SUI++;
		$hash->{'LUI'}="L".$LUI++;
		$hash->{'Term_Status'}="S";
		#MRSO
		$hash->{'SAB'}=$SAB;
		$hash->{'Term_Type'}="NP";
		$hash->{'Source ID'}="T5";
		#MRSTY
		$hash->{'TUI'}=$TUI;
		$hash->{'STY'}=$STY;
		
		push(@{$do->{$id}},$hash);
	}
}
return $do;
}


sub createMRCON{
	my ($do,$dir)=@_;
	open (MYFILE, ">$dir/MRCON");
	foreach my $c(keys %{$do}){
		foreach my $t(@{$do->{$c}}){
			printf MYFILE "%s|ENG|%s|%s|PF|%s|%s|0|\n",$c,$t->{'Term_Status'},$t->{'LUI'},$t->{'SUI'},$t->{'String'};	
		}
	}
	close (MYFILE);	
}

sub createMRSO{
	my ($do,$dir)=@_;
	open (MYFILE, ">$dir/MRSO");
	foreach my $c(keys %{$do}){
		foreach my $t(@{$do->{$c}}){
			printf MYFILE "%s|%s|%s|%s|%s|%s|0|\n",$c,$t->{'LUI'},$t->{'SUI'},$t->{'SAB'},$t->{'Term_Type'},$t->{'Source ID'};
		}
	}
	close (MYFILE);	
}

sub createMRSAT{
	##can be empty
	my ($do,$dir)=@_;
	open (MYFILE, ">$dir/MRSAT");
	close (MYFILE);	
}


sub createMRSAB{
	my ($do,$dir)=@_;
	open (MYFILE, ">$dir/MRSAB");
	print MYFILE "C4000006|C4000006|DO_2013|HDO|Human Disease Ontology|||||||||0|26368|8695||||ENG|ascii|Y|Y|";
	close (MYFILE);	
}

sub createMRRANK{
	my ($do,$dir)=@_;
	open (MYFILE, ">$dir/MRRANK");
	printf MYFILE "%d|%s|%s|%s|\n",200,"HDO","PT","N";
	printf MYFILE "%d|%s|%s|%s|\n",100,"HDO","NP","N";
	close (MYFILE);	
}

sub createMRSTY{
	my ($do,$dir)=@_;
	open (MYFILE, ">$dir/MRSTY");
	print MYFILE "10652|T001|Disease Semantic Type|";
	close (MYFILE);
}





1;
