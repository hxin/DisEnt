# some doc here
#
#
#

=head1 NAME

Xin::DB

=cut

# Let the code begin...

package Xin::EBI;

use Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw();

# use module
use lib '/home/xin/Dropbox/work/Phd/myperl/ensembl/modules';
use lib '/home/xin/Dropbox/work/Phd/myperl/lib64/perl5/' ;
use lib '/home/xin/Dropbox/work/Phd/myperl/ensembl-variation/modules';
use lib '/home/xin/Dropbox/work/Phd/myperl/ensembl-compara/modules';


use strict;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::Exception qw(throw) ;
use Data::Dumper;

=head2 connectEBI

 Title   : connectEBI
 Usage   : my $registry = connectEBI
 Returns : db handle

=cut

sub connectEBI {
	my $registry = 'Bio::EnsEMBL::Registry' ;
	
	$registry-> load_registry_from_db(
            - host => 'ensembldb.ensembl.org' ,    # alternatively 'useastdb.ensembl.org'
             -user => 'anonymous'
	);
	
	return $registry;
}


=head2 fetchallHumanGenesfromEnsEMBLCore

 Title   : fetchallHumanGenesfromEnsEMBLCore
 Usage   : @human_genes=fetchallHumanGenesfromEnsEMBLCore($registry)
 Function: fetch all the human genes into an array
 Returns : array [gene1,gene2...]
 Args    : $registry
=cut

sub fetchallHumanGenesfromEnsEMBLCore{
	my $registry=shift @_;
	$registry=connectEBI() if !$registry;
	my $gene_adaptor =$registry-> get_adaptor( 'Human' , 'Core', 'Gene' ); throw ("Error when getting \$gene_adaptor") if(!$gene_adaptor);
	my @genes = @{ $gene_adaptor->fetch_all }; throw("Error when Fetching Human Genes!\n")if( !@genes);
	
	return @genes;
}

=head2 fetchHomologyGeneForHumanGene

 Title   : fetchHomologyGeneForHumanGene
 Usage   : fetchHomologyGeneForHumanGene($registry, \@genes)
 Function: foreach human gene,fetch its homology from ensembl. Current only print out the result.
 Returns : 
 Args    : $registry \@human_genes
=cut

sub fetchHomologyGeneForHumanGene{			
	my $registry=shift @_;
	$registry=connectEBI() if !$registry;
	my @genes=@{shift @_};
	############Edit this to add more species. The name can be found in Ensembl Compara in table [genomedb]
	my @species_list=("drosophila_melanogaster","rattus_norvegicus","mus_musculus","saccharomyces_cerevisiae");
	my %species_names = ( "drosophila_melanogaster" => "fly",
         			  "rattus_norvegicus" => "rat",
          			  "mus_musculus" => "mouse",
         			  "saccharomyces_cerevisiae" =>"yeast");
         			  
	my $member_adaptor = $registry-> get_adaptor('Multi' ,'compara', 'Member');      throw ("Error when getting \$member_adaptor") if(!$member_adaptor);
	my $homology_adaptor = $registry-> get_adaptor('Multi' , 'compara', 'Homology');            throw( "Error when getting \$homology_adaptor!" )if( !$homology_adaptor) ;
	
	while(my $gene = shift @genes){
	             if($gene){
	                         my $member = $member_adaptor-> fetch_by_source_stable_id('ENSEMBLGENE' ,$gene ->stable_id());            
	                         if($member){
	                                     #Get all orthologues or paralogues for one particular human gene
	                                     #push these information into a list @human_xxx_homologues                             
	                                     #human_fly 
	                                     foreach(@species_list){
	                                     	my $fullName=$_;
	                                     	my $shortName=$species_names{$fullName};
	                                     	my @homologues = @{$homology_adaptor->fetch_all_by_Member_paired_species($member, $fullName)};
	                                     	if(@homologues){                                              
	                                                 while(my $h= shift @homologues){
	                                                 	 my @pair = @{$h->gene_list};
	                                                 	 my $human_gene_id;
									                     my $orthologue_gene_id;
									                     ##check which is huamn gene
	                                                 	 if($pair[1]->get_Gene ->display_id =~ /^ENSG/)
	                                                 	 { 
		                                                 	 $human_gene_id = $pair[1]->get_Gene ->display_id;
									                         $orthologue_gene_id = $pair[0]->get_Gene ->display_id;
	                                                 	 }else{
	                                                 	 	 $human_gene_id = $pair[0]->get_Gene ->display_id;
									                         $orthologue_gene_id = $pair[1]->get_Gene ->display_id;
	                                                 	 }
								                         my $dn_ds = $h -> dnds_ratio? $h-> dnds_ratio : "NA";
								                         my $type = $h -> description;
								                         print $human_gene_id. "\t".$orthologue_gene_id. "\t".$dn_ds. "\t".$type. "\n";
	                                                 }                                                                            
	                                   		  }                           
	                                     }      
	                                                            
	                                               
	                        }           
	            }                       
	}
}

=head2 fetchallHumanGenesfromEnsEMBLCore

 Title   : fetchallHumanGenesfromEnsEMBLCore
 Usage   : @human_genes=fetchallHumanGenesfromEnsEMBLCore($registry)
 Function: fetch all the human genes into an array
 Returns : array [gene1,gene2...]
 Args    : $registry
=cut

sub getGeneLocation{
	my $registry=shift @_;
	my $gene=shift @_;
	my %result;
	$result{'chr'}=$gene->slice->seq_region_name;
	$result{'start'}=$gene->start;
	$result{'end'}=$gene->end;
	return %result;
}



sub getGeneByStableId{
	my $registry=shift @_;
	my $id=shift @_;
	my $gene_adaptor =$registry->get_adaptor( "human", "core", "gene" );
 	my $gene = $gene_adaptor->fetch_by_stable_id($id);
 	return $gene;
}

sub getVariationByName{
	my $registry=shift @_;
	my $name=shift @_;
	my $va_adaptor = $registry->get_adaptor('human', 'variation', 'variation');
 	my $var = $va_adaptor->fetch_by_name($name); 
 	return $var;
}

sub getVariationLocation{
	my $registry=shift @_;
	my $var=shift @_;
	my %result;
	my @vararion_features=@{$var->get_all_VariationFeatures()};
	for my $feat(@vararion_features){
		$result{'chr'}=$feat->slice()->seq_region_name();
		$result{'start'}=$feat->start();
		$result{'end'}=$feat->end();
	}
	return %result;
}

sub getVariationsLocation{
	my $registry= connectEBI;
	my @vars=@{shift @_};
	my %return;
	foreach(@vars){
		my $id=$_;
		my %hash=getVariationLocation($registry,getVariationByName($registry,$id));
		$return{$id}=\%hash;
	}
	return %return;
}

#sub getGWASVariation{
#	my $registry= connectEBI;
#	
#	# Get a VariationSetAdaptor on the human variation database
#	my $vs_adaptor = $registry->get_adaptor( 'human', 'variation', 'variationset' );
#	# Get the variation set for the phenotype-associated variants.
#	my $vs = $vs_adaptor->fetch_by_short_name('ph_nhgri');
#
#	my $limit   = 999999999;
#	my $fetched = 0;
#	my $it      = $vs->get_Variation_Iterator();
#	my $ref;
#	my $ref_db;
#	my $ref_id;
#	my @result;
#
#	# Get the first 10 examples and print some data from them
#	while ( $fetched < $limit && $it->has_next() ) {
#		my %hash;		
#		my $var = $it->next();
#		
#		# Get the VariationAnnotation objects for the variation
#	  	my $annotations = $var->get_all_VariationAnnotations();
#
#	  	# Loop over the annotations and print the phenotypes
#	  	foreach my $annotation (@{$annotations}) {  		
#	  		$hash{'variation_id'}=$var->name;
#	  		$hash{'phenotype_description'}=$annotation->phenotype_description();
#	  		
#			my $ref=$annotation->external_reference();
#			 if (index($ref, ':') != -1) {
#			 	($ref_db,$ref_id)=split(/:/, $ref);
#			 }elsif (index($ref, '/') != -1) {
#				($ref_db,$ref_id)=split(/\//, $ref);
#			 }
#			$hash{'ref_db'}=$ref_db;
#			$hash{'ref_id'}=$ref_id;
#	  	}	
#		$fetched++;
#		push(@result,\%hash);
#	}
#	return @result;
#}

sub getAllPhenotypeAssociatedVariationAndNearbyGenes{
	my $var_set_name=shift @_;
	my $registry= connectEBI;
	my $wide=200000;
	my %return;

	# Get a VariationSetAdaptor on the human variation database
	my $vs_adaptor = $registry->get_adaptor( 'human', 'variation', 'variationset' );
	# Get the variation set for the phenotype-associated variants.
	my $vs = $vs_adaptor->fetch_by_short_name('ph_variants');
	# Get pf adapter
	my $pf_adaptor = $registry->get_adaptor('homo_sapiens', 'variation', 'phenotypefeature');
	my $limit   = 2;
	my $fetched = 0;
	my $it      = $vs->get_Variation_Iterator();

	# Get the first 10 examples and print some data from them
	while ( $fetched < $limit && $it->has_next() ) {	
		my $var = $it->next();	
		
		my $genes_ref=getNearGenesByVariation($registry,$var,$wide);
		foreach my $gene(@{$genes_ref}){
				push (@{$return{$var->name()}->{'Genes'}},$gene->display_id()); 
		}
		
		my %location=getVariationLocation($registry,$var);
		push (@{$return{$var->name()}->{'Location'}},\%location); 
		
		
		
		my $pts_ref=getPhenotypesByVariation($registry,$var);
		$return{$var->name()}->{'Phenotypes'}=$pts_ref;
		
		
		$fetched++;
	}
	return %return;
}

sub getPhenotypesByVariation{
	my ($registry,$var)= @_;
	my @return;
	# Get pf adapter
	my $pf_adaptor = $registry->get_adaptor('homo_sapiens', 'variation', 'phenotypefeature');
	my $pfs=$var->get_all_PhenotypeFeatures();
	foreach my $pf (@{$pfs}) {
			my %tmp;
			$tmp{'source'}=$pf->source ();
			
			if($pf->external_reference()){
					$tmp{'external_reference'}=$pf->external_reference();
			}else{
				$tmp{'external_reference'}='null';
			}
			my $pt=$pf->phenotype();
			$tmp{'ensembl_phenotype_id'}=$pt->dbID ();
			$tmp{'phenotype_description'}=$pt->description ();
			push(@return,\%tmp);
	}
	return \@return;
}


sub getSliceByVatiation{
	my ($registry,$var,$wide)= @_;
	my %location=getVariationLocation( $registry,$var );
	my $slice_adaptor = $registry->get_adaptor( 'Human', 'Core', 'Slice' );
	my $slice = $slice_adaptor->fetch_by_region( 'chromosome', $location{'chr'}, $location{'start'}-$wide, $location{'end'}+$wide);
	return $slice;    
}

sub getNearGenesByVariation{
	my ($reg,$var,$wide)=@_;
	my $slice=getSliceByVatiation($reg,$var,$wide);
	my @genes=@{$slice->get_all_Genes};
	return \@genes;
}

sub getNearestGeneByVariation{
	my ($dbh,$reg,)=@_;
}



1;
