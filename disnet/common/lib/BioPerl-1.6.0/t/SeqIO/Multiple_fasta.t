# -*-Perl-*- Test Harness script for Bioperl
# $Id: Multiple_fasta.t 15112 2008-12-08 18:12:38Z sendu $

use strict;

BEGIN {     
    use lib '.';
    use Bio::Root::Test;
    
    test_begin(-tests => 9);
	
	use_ok('Bio::SeqIO');
}

my $in = Bio::SeqIO->new(-file => test_input_file('multifa.seq') , '-format' => 'Fasta');
ok $in;
my $c=0;
while ( my $seq = $in->next_seq() ) {
    ok($seq);
    $c++;
}
is $c,6, "all sequences in the file";
