#!/usr/bin/perl
#This script is used to create all human_xxx homologue tables and insert homology data into NRG database.
#It also create species specified disease table base on OMIM and GeneRIF data from the database.
#This is a combine version of script homolog_pull.pl and homolog_dis.pl
#Could be used to update the databse or add new species into database

use strict;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::Exception qw(throw) ;
use DateTime;
#use PadWalker;

my $registry = 'Bio::EnsEMBL::Registry' ;
$registry-> load_registry_from_db(
            - host => 'ensembldb.ensembl.org' ,    # alternatively 'useastdb.ensembl.org'
             -user => 'anonymous'
);
$registry->set_reconnect_when_lost();
my $gene_adaptor = $registry-> get_adaptor( 'Human' , 'Core', 'Gene' ); throw ("Error when getting \$gene_adaptor") if(!$gene_adaptor);


############Fetch all Human Genes from EnsEMBL Core
#print "Fetching all Human Genes...";
my @genes = @{ $gene_adaptor->fetch_all }; throw("Error when Fetching Human Genes!\n")if( !@genes);
#print scalar(@genes). " human genes found! \t" .DateTime-> now."\n" ;
foreach(@genes){
	print $_->stable_id."\t".$_->slice->seq_region_name."\t".$_->start."\t".$_->end."\n";
}


exit;
