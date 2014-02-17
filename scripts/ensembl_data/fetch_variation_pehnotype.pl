#!/usr/bin/perl


use strict;
#use lib '/home/xin/Workspace/DisEnt/scripts/lib/BioPerl-1.6.0';
#use lib '/home/xin/Workspace/DisEnt/scripts/lib/ensembl-api/ensembl/modules';
#use lib '/home/xin/Workspace/DisEnt/scripts/lib/ensembl-api/ensembl-compara/modules';
#use lib '/home/xin/Workspace/DisEnt/scripts/lib/ensembl-api/ensembl-functgenomics/modules';
#use lib '/home/xin/Workspace/DisEnt/scripts/lib/ensembl-api/ensembl-variation/modules';
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::Exception qw(throw) ;
use DateTime;
use Data::Dumper;

#use PadWalker;


my($debug)=@ARGV;

#print getCurrentTime()."\n";
my $registry=connectEBI();
# Get a VariationSetAdaptor on the human variation database
my $vs_adaptor = $registry->get_adaptor( 'human', 'variation', 'variationset' );
# Get the variation set for the phenotype-associated variants.
my $vs = $vs_adaptor->fetch_by_short_name('ph_variants');
# Get pf adapter
my $pf_adaptor = $registry->get_adaptor('homo_sapiens', 'variation', 'phenotypefeature');


my $limit   = 9999999999999999;
if($debug == 'y'){
	$limit = 100
}
my $fetched = 0;


my $it      = $vs->get_Variation_Iterator()->grep(sub {$_->name =~ /^rs.+/});
# Get the first 10 examples and print some data from them
while ( $fetched++ < $limit && $it->has_next() ) {	
	my $var = $it->next();
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


}
exit;

sub connectEBI {
	my $registry = 'Bio::EnsEMBL::Registry' ;
	$registry-> load_registry_from_db(
             -host => 'ensembldb.ensembl.org' ,    # alternatively 'useastdb.ensembl.org'
             -user => 'anonymous'
	);
	$registry->set_reconnect_when_lost();
	return $registry;
}
