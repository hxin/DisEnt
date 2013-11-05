#!/usr/bin/perl


use strict;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::Exception qw(throw) ;
use DateTime;

#print getCurrentTime()."\n";
my $registry=connectEBI();
$registry->set_reconnect_when_lost();
print 1;
# Fetch a variation object
my $var_adaptor = $registry->get_adaptor('human', 'variation', 'variation');
print 2;
#my $var = $var_adaptor->fetch_by_name('rs693');
print "fetch it...";

#my $var = $var_adaptor->fetch_all_by_source('OMIM');
my $var_iterator = $var_adaptor->fetch_Iterator;
while(my $v = $var_iterator->next){
	print $v->source(), ':',$v->name(), ".",$v->version,"\n";
}


sub connectEBI {
	my $registry = 'Bio::EnsEMBL::Registry' ;
	$registry-> load_registry_from_db(
             -host => 'ensembldb.ensembl.org' ,    # alternatively 'useastdb.ensembl.org'
             -user => 'anonymous'
	);
	return $registry;
}
