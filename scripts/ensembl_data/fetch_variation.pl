#!/usr/bin/perl


use strict;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::Exception qw(throw) ;
use DateTime;

#print getCurrentTime()."\n";
my $registry=connectEBI();
$registry->set_reconnect_when_lost();
# Get a VariationSetAdaptor on the human variation database
my $vs_adaptor = $registry->get_adaptor( 'human', 'variation', 'variationset' );
# Get the variation set for the phenotype-associated variants.
my $vs = $vs_adaptor->fetch_by_short_name('ph_variants');
# Get pf adapter
my $pf_adaptor = $registry->get_adaptor('homo_sapiens', 'variation', 'phenotypefeature');

my $limit   = 99999999999;
my $fetched = 0;



my $it      = $vs->get_Variation_Iterator();
# Get the first 10 examples and print some data from them
while ( $fetched++ < $limit && $it->has_next() ) {	
	my $var = $it->next();
	my @vararion_features=@{$var->get_all_VariationFeatures()};
	
	for my $feat(@vararion_features){		
		my $chr=$feat->slice()->seq_region_name();
		my $start=$feat->start();
		my $end=$feat->end();
		print $var->name()."\t".$chr."\t".$start."\t".$end."\n";
	}
}
exit;




sub connectEBI {
	my $registry = 'Bio::EnsEMBL::Registry' ;
	$registry-> load_registry_from_db(
             -host => 'ensembldb.ensembl.org' ,    # alternatively 'useastdb.ensembl.org'
             -user => 'anonymous'
	);
	return $registry;
}
