# -*-Perl-*- Test Harness script for Bioperl
# $Id: chaosxml.t 15112 2008-12-08 18:12:38Z sendu $

use strict;

BEGIN {
	use lib '.';
	use Bio::Root::Test;
	
	test_begin(-tests => 2,
			   -requires_module => 'Data::Stag');
	
	use_ok('Bio::SeqIO');
}

my $verbose = test_debug();

# currently chaosxml is write-only
my $in = Bio::SeqIO->new(-format => 'genbank',
								 -verbose => $verbose,
								 -file => test_input_file('AE003644_Adh-genomic.gb'));

my $seq = $in->next_seq;

my $out_file = test_output_file();
my $out = Bio::SeqIO->new(-file => ">$out_file",
								  -verbose => $verbose,
								  -format => 'chaosxml');
$out->write_seq($seq);
ok (-e $out_file);
