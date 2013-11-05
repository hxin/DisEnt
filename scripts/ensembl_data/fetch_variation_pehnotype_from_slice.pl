#!/usr/bin/perl


use strict;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::Exception qw(throw) ;
use DateTime;
use Data::Dumper;

#use PadWalker;




my $registry = 'Bio::EnsEMBL::Registry' ;
$registry-> load_registry_from_db(
             -host => 'ensembldb.ensembl.org' ,    # alternatively 'useastdb.ensembl.org'
             -user => 'anonymous'
	);
$registry->set_reconnect_when_lost();


# get a slice adaptor for the human core database
my $slice_adaptor = $registry->get_adaptor( 'Human', 'Core', 'Slice' );
my $vs_adaptor = $registry->get_adaptor('human','variation','variationset');
my $vs = $vs_adaptor->fetch_by_short_name('ph_variants');
my @c=(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,'X','Y');
foreach my $c(@c){
	# Obtain a slice covering the entire chromosome X
	my $slice = $slice_adaptor->fetch_by_region( 'chromosome', $c);
	#my $slice = $slice_adaptor->fetch_by_region( 'chromosome', $c,1e6, 2e6);
	# Get the variation features on the slice belonging to the variation set
	my $vfs = $vs->get_all_VariationFeatures_by_Slice($slice);
#	FOO:{
		foreach my $vf(@{$vfs}){
			my $var=$vf->variation();
			my $pfs=$var->get_all_PhenotypeFeatures();
			foreach my $pf (@{$pfs}) {			
					my $ef;
					if($pf->external_reference()){
						$ef=$pf->external_reference();
					}else{
						$ef='\N';
					}
					my $pt=$pf->phenotype();		
					print $var->name()."\t".$pf->seq_region_name()."\t".$pf->seq_region_start()."\t".$pf->seq_region_end()."\t".$pf->source ()."\t".$ef."\t".$pt->dbID ()."\t".$pt->description ()."\n";
			}
#			last FOO;	
#		}
	}
}

exit;
