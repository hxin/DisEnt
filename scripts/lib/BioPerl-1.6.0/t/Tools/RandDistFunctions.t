# -*-Perl-*- Test Harness script for Bioperl
# $Id: RandDistFunctions.t 15112 2008-12-08 18:12:38Z sendu $

use strict;

BEGIN { 
    use lib '.';
    use Bio::Root::Test;
    
    test_begin(-tests => 5);
	
    use_ok('Bio::Tools::RandomDistFunctions');
}


ok my $dist = Bio::Tools::RandomDistFunctions->new();

ok($dist->rand_exponentional_distribution(1.0));
ok($dist->rand_geometric_distribution(0.9));
ok($dist->rand_normal_distribution);

# TODO? these tests seem pretty pointless!
