# some doc here
#


=head1 NAME

Xin::DB

=cut

# Let the code begin...

package Xin::NCBI;

use Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw();

# use module
use lib "/home/xin/perl5/lib/perl5";

use strict;
use XML::Twig;
use Bio::DB::EUtilities;
use Bio::DB::MeSH;
use Data::Dumper;
use DateTime;
use DBI;


=head2 findCountForMeshTermInPubmed

 Title   : findCountForMeshTermInPubmed
 Usage   : my $count = findCountForMeshTermInPubmed('meshTerm')
 Function: Return a count of the mesh term in pubmed search 'meshTerm[MeSH Terms]'
 Returns : a number
 Args    : a meshTerm name       'Alzheimer Disease'

=cut

sub findCountForMeshTermInPubmed {
	my $mesh    = shift @_;
	return &esearchCount($mesh . '[MeSH Terms]');
}

sub esearchCount{
	my $term    = shift @_;
	my $factory_result= &esearch($term);
	return $factory_result->get_count;
}

sub esearch{
	my $term  = shift @_;
	my $factory = Bio::DB::EUtilities->new(
		-eutil => 'esearch',
		-db    => 'pubmed',
		-term  => $term,		
		#-retmax => 100000
	);
	
	return $factory;	
}

sub esearchIDs{
	my $term    = shift @_;
	my $factory=&esearch($term);
	if ($factory->get_count > 99999) 
		{die('too many result! Use esearchIdsLarge eutilities to do mutilple chunk get');}
	return $factory->get_ids;			
}

sub esearchIDsLarge{
	my $term    = shift @_;
	my ($retmax, $retstart) = (100000,0);
	my $factory = Bio::DB::EUtilities->new(
		-eutil => 'esearch',
		-db    => 'pubmed',
		-term  => $term,
		-usehistory => 'y'
	);
	my $count = $factory->get_count;
	my $hist  = $factory->next_History || die 'No history data returned';
	#print Dumper($hist);
	$factory->set_parameters(-eutil   => 'efetch',
                         -rettype => 'uilist',
                         -history => $hist);
    my $retry = 0;
	my $error=0;
	my @ids;
	my $size;
	RETRIEVE_SEQS:
	while ($retstart < $count) {
		$size=scalar(@ids);
	   	 $factory->set_parameters(-retmax   => $retmax,
	                             -retstart => $retstart,
	                              -history => $hist,
	                             -retmode => 'text',
	                             );
	    #print $factory->get_Response->content;exit;
	    eval{
	    	my @accs = split(m{\n},$factory->get_Response->content);
	    	
	    	foreach(@accs){
	    		if(!($_ =~ /^\d/)){
	    			$error=1;
	    		}
	    	}	
	    	if($error==0){
	    		push(@ids, @accs);
	    	}    	       	
	    };
	    if ($@) {
	        die "Server error: $@.  Try again later" if $retry == 5;
	        print STDERR "Server error, redo #$retry\n";
	        $retry++ && redo RETRIEVE_SEQS;
	    }
	    
	    
	    if($error){
	    	print "resubmitting esearch...\n";
	    	$factory = Bio::DB::EUtilities->new(
				-eutil => 'esearch',
				-db    => 'pubmed',
				-term  => $term,
				-usehistory => 'y'
			);
			$hist  = $factory->next_History || die 'No history data returned';
			$factory->set_parameters(-eutil   => 'efetch',
                         -rettype => 'uilist',
                         -history => $hist);
            $error=0;  
	    	#print "Query translation: ",$factory->get_query_translation,"\n";
	    	#my @t=split(m{\n},$factory->get_Response->content);
	    	#print $t[0];
	    	#select(undef, undef, undef, 3);
	    }else{
	    	$retstart += $retmax;
	    	printf "Retrieved %d sizeofArray:%d [%.4f%%]\t(%d)\t%s\t \n",$retstart,scalar(@ids),$retstart*100/$count,$count,Xin::Utilities::getCurrentTime();
	    }
	}
	return @ids;
}
	
#	$retmax = 500;
#for ($retstart = 0; $retstart < $count; $retstart += $retmax) {
#        $efetch_url = $base ."efetch.fcgi?db=nucleotide&WebEnv=$web";
#        $efetch_url .= "&query_key=$key&retstart=$retstart";
#        $efetch_url .= "&retmax=$retmax&rettype=fasta&retmode=text";
#        $efetch_out = get($efetch_url);
#        print OUT "$efetch_out";
#}
#}

=head2 findMeshTermsForPubmedIds

 Title   : findMeshTermsForPubmedIds
 Usage   : my %pubmed2mesh = findMeshTermsForPubmedIds(@pubmed_ids)
 Function: find the mesh terms for a give list of pubmed_ids in pubmed
 Returns : hash   hash{17719017}=@(meshs) hash{18258338}=@(meshs)
 Args    : ref a list of pubmed_ids      my @pubmed_ids = (17719017,18258338);

=cut

sub findMeshTermsForPubmedIds{
	my @pubmed_ids = @{shift @_};	
	
	##epost the ids ni case its too big
	my $factory = Bio::DB::EUtilities->new(-eutil          => 'epost',
   	                                   -db             => 'pubmed',
                                       -id             => \@pubmed_ids,
                                       -keep_histories => 1);
	my $hist = $factory->next_History;
	
	##efetch abstract 
	$factory = Bio::DB::EUtilities->new(-eutil   => 'efetch',
						 -db 	 => 'pubmed',
                         -rettype => 'abstract',
                         -history => $hist);                     
    my $retry = 0;
	my ($retmax, $retstart) = (100,0);
	our $currentId;
	our %pubmed2mesh;
	our $error=0;
	RETRIEVE_SEQS:
	while ($retstart < scalar(@pubmed_ids)) {
		 my $size=scalar(keys %pubmed2mesh);
	   	 $factory->set_parameters(-retmax   => $retmax,
	                             -retstart => $retstart,
	                             -history => $hist
	                             );
	    
	    #print $factory->get_Response->content;exit;
	    eval{
	    	my $result=$factory->get_Response->content;
	    	my $twig =new XML::Twig( twig_handlers => { MeshHeading => \&MeshHeading,PMID=>\&PMID,ERROR=>\&ERROR } );
			$twig->parse( $result );
	
			sub MeshHeading {
				##called everytime when hit a tag <MeshHeading>
				my ( $twig, $MeshHeading ) = @_;
				push( @{$pubmed2mesh{$currentId}}, $MeshHeading->first_child('DescriptorName')->text );
				#print "\t" . $MeshHeading->first_child('DescriptorName')->text . "\n";
			}
			sub PMID{
				my ( $twig, $PMID ) = @_;
				$currentId=$PMID->text;
			} 
			
			sub ERROR{
				my ( $twig, $ERROR ) = @_;
				print $ERROR->text;
				$error=1;
			}      	
	    };
	    if ($@) {
	        die "Server error: $@.  Try again later" if $retry == 5;
	        print STDERR "Server error, redo #$retry\n";
	        $retry++ && redo RETRIEVE_SEQS;
	    }
	    
	    if($error){
	    	#print "Query translation: ",$factory->get_query_translation,"\n";
	    	#redo the esearch to get a new env and start where you fail
	    	print "resubmitting esearch...\n";
	    	$factory = Bio::DB::EUtilities->new(-eutil          => 'epost',
   	                                   -db             => 'pubmed',
                                       -id             => \@pubmed_ids,
                                       -keep_histories => 1);
			$hist = $factory->next_History;
			
			##efetch abstract 
			$factory = Bio::DB::EUtilities->new(-eutil   => 'efetch',
								 -db 	 => 'pubmed',
		                         -rettype => 'abstract',
		                         -history => $hist);                 
	    	$error=0;
	    	#my @t=split(m{\n},$factory->get_Response->content);
	    	#print $t[2];
	    }else{
	    	$retstart += $retmax;
	    	printf "Retrieved %d sizeofArray:%d [%.4f%%]\t(%d)\t%s\t \n",$retstart,scalar(keys %pubmed2mesh),$retstart*100/scalar(@pubmed_ids),scalar(@pubmed_ids),Xin::Utilities::getCurrentTime();
	    } 

	}
	return %pubmed2mesh;
}                  
                         
                         
                         
                         

#		my $result=$factory->get_Response->content;
#		#print $factory->get_Response->content;
#		my $twig =new XML::Twig( twig_handlers => { MeshHeading => \&MeshHeading,PMID=>\&PMID } );
#		our $currentId;
#		our %pubmed2mesh;
#		$twig->parse( $result );
#
#		sub MeshHeading {
#			##called everytime when hit a tag <MeshHeading>
#			my ( $twig, $MeshHeading ) = @_;
#			push( @{$pubmed2mesh{$currentId}}, $MeshHeading->first_child('DescriptorName')->text );
#			#print "\t" . $MeshHeading->first_child('DescriptorName')->text . "\n";
#		}
#		sub PMID{
#			my ( $twig, $PMID ) = @_;
#			$currentId=$PMID->text;
#		}
#		return %pubmed2mesh;
#	}






=head2 parseXMLMeshFile

 Title   : parseXMLMeshFile
 Usage   : parseXMLMeshFile('mesh.xml','output.txt')
 Function: parse the Mesh xml file from http://www.nlm.nih.gov/mesh/filelist.html
 			use XML Twig lib configed to be effective for loading hugh xml file  http://search.cpan.org/~mirod/XML-Twig-3.42/
			extract the id, name and tree number from the file and save in output.txt file
			some MeSH don't have tree number!!
 Returns : hash   hash{17719017}=@(meshs) hash{18258338}=@(meshs)
 Args    : (source file,outut file)
=cut

sub parseXMLMeshFile {
	my $sourceFile=shift @_;
	my $output=shift @_;
	open (MYFILE, '>>'.$output);
	
	my $twig = new XML::Twig(
		twig_handlers => { DescriptorRecord => \&DescriptorRecord }    
	);                                

	$twig->parsefile($sourceFile); # build the twig

	sub DescriptorRecord {
		my ( $twig, $DescriptorRecord ) = @_;
		my $id = $DescriptorRecord->first_child('DescriptorUI')->text;
		my $name =$DescriptorRecord->first_child('DescriptorName')->text;
		my $tree_number;
		if ( $DescriptorRecord->has_child('TreeNumberList') ) {
			my @numbers = map { $_->children_text }
			$DescriptorRecord->first_child('TreeNumberList');
			$tree_number = join( ';', @numbers );
		}
		else {
			$tree_number = '';
		}
		print MYFILE $id . "\t" . $name . "\t" . $tree_number . "\n";
		$twig->purge;
	}
}


=head2 findGoodMeshTermFromPubMedIds

 Title   : findGoodMeshTermFromPubMedIds
 Usage   : my @pubmed_ids=(17719017,18258338,18280617,18359537);
			my %meshWight=Xin::NCBI::calculateMeshTermWeightByPubmedIds(\@pubmed_ids);
			print Dumper(%meshWight);
 Function: The function first search ncbi for all the meshes for the each pubmed_ids,
 			then mesure the count of each mesh in the provided pubmed_ids as local count.(how many times does this mesh appear in these pubmed_ids)
 			Then for each mesh, query ncbi to find its global count.(how many times does this mesh appear in the whole pubmed db)
 Returns : hash{mesh}={"LocalCount"=>$count,'GlobalCount'=>$count}
 Args    : ref list of pubmed_ids

=cut

sub calculateMeshTermWeight{
	print "finding mesh terms for the submited list of ids...\n";
	my %pubmed2mesh=findMeshTermsForPubmedIds(shift @_);
	
	print "finding mesh terms local count...\n";
	my %meshLocal=findMeshTermLocalFrequency(\%pubmed2mesh);

	my @allMeshes;
	while( my ($k, $v) = each %pubmed2mesh){
		foreach(@{$v}){
			push(@allMeshes,$_);
		}
	}
	@allMeshes=Xin::Utilities::getUnique(\@allMeshes);
	
	print "finding mesh terms global count(total:".scalar(@allMeshes).". this take some time)...\n";
	my %meshGlobal=findMeshTermGlobalFrequency(\@allMeshes);

	my %return;
	for my $mesh(keys %meshLocal){
		$return{$mesh}={"LocalCount"=>$meshLocal{$mesh},'GlobalCount'=>$meshGlobal{$mesh},'Weight'=>($meshLocal{$mesh}/scalar(keys %pubmed2mesh))/(($meshGlobal{$mesh}+1)/21766349)};
	}
	
	return %return;
}

=head2 findMeshTermLocalFrequency

 Title   : findMeshTermLocalFrequency
 Usage   : findMeshTermLocalFrequency(\%pubmed2mesh)
 Function: given a pubmed2mesh hash, find the mesh term frequency in these pubmed ids
 Returns : hash $hash{mesh}=$count
 Args    : hash ref 

=cut
sub findMeshTermLocalFrequency{
	my %pubmed2mesh = %{shift @_};
	my %meshLocalCount; 

	for my $pubmed_id(keys %pubmed2mesh){
		my @meshes=@{$pubmed2mesh{$pubmed_id}};
		for my $mesh(@meshes){
			if (exists $meshLocalCount{$mesh}){
				$meshLocalCount{$mesh}++;
			}else{
				$meshLocalCount{$mesh}=1;
			}
		}
	}
	return %meshLocalCount;
}

=head2 findMeshTermGlobalFrequency

 Title   : findMeshTermGlobalFrequency
 Usage   : findMeshTermGlobalFrequency(\%pubmed2mesh)
 Function: given a list of mesh terms, find the mesh term frequency in Pubmed DB
 Returns : hash $hash{mesh}=$count
 Args    : array_ref

=cut
sub findMeshTermGlobalFrequency{
	my @meshes=@{shift @_};
	my %meshGlobalCount;
	my $count;
	for my $mesh(@meshes){
			$meshGlobalCount{$mesh}=findCountForMeshTermInPubmed($mesh);
			print $count++."/".scalar(@meshes)."\t".$mesh."------------>".$meshGlobalCount{$mesh}."\n";
	};
	return %meshGlobalCount;
}



1;
