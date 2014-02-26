#!/usr/bin/perl
use strict;
use lib '/home/xin/Workspace/DisEnt/scripts/lib/BioPerl-1.6.0';
use lib '/home/xin/Workspace/DisEnt/scripts/lib/ensembl-api/ensembl/modules';
use lib '/home/xin/Workspace/DisEnt/scripts/lib/ensembl-api/ensembl-compara/modules';
use lib '/home/xin/Workspace/DisEnt/scripts/lib/ensembl-api/ensembl-functgenomics/modules';
use lib '/home/xin/Workspace/DisEnt/scripts/lib/ensembl-api/ensembl-variation/modules';
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::Exception qw(throw) ;
use DateTime;
use Data::Dumper;

#use PadWalker;

#print getCurrentTime()."\n";
my $registry=connectEBI();
# Get a VariationSetAdaptor on the human variation database
my $vs_adaptor = $registry->get_adaptor( 'human', 'variation', 'variationset' );
# Get the variation set for the phenotype-associated variants.
my $vs = $vs_adaptor->fetch_by_short_name('ph_variants');

my @vs_subsets = @{$vs_adaptor->fetch_all_by_super_VariationSet($vs)};
foreach(@vs_subsets){
	print $_->short_name ()." ";
}




sub connectEBI {
	my $registry = 'Bio::EnsEMBL::Registry' ;
	$registry-> load_registry_from_db(
             -host => 'ensembldb.ensembl.org' ,    # alternatively 'useastdb.ensembl.org'
             -user => 'anonymous'
	);
	$registry->set_reconnect_when_lost();
	return $registry;
}
