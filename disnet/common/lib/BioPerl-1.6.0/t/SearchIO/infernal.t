# -*-Perl-*- Test Harness script for Bioperl
# $Id: SearchIO_infernal.t 14672 2008-04-22 21:42:50Z cjfields $

use strict;

BEGIN {
    use lib '.';
    use Bio::Root::Test;
    
    test_begin(-tests => 316);
    
    use_ok('Bio::SearchIO');
}

my ($searchio, $result, $iter, $hit, $hsp, $algorithm, $meta);

### Infernal ####

$searchio = Bio::SearchIO->new( -format => 'infernal',
                                -file   => test_input_file('test.infernal'),
                                # version is reset to the correct one by parser
                                -version => 0.7, 
                                -model => 'Purine',
                                -query_acc => 'RF00167',
                                -query_desc => 'Purine riboswitch',
                                -database => 'b_sub.fas',
                                -hsp_minscore => 40,
                                -convert_meta => 0,
                               );

$result = $searchio->next_result;
isa_ok($result, 'Bio::Search::Result::ResultI');
$algorithm = $result->algorithm;
is($result->algorithm, 'CMSEARCH', "Result $algorithm");
is($result->algorithm_reference, undef, "Result $algorithm reference");
is($result->algorithm_version, 0.7, "Result $algorithm version");
is($result->available_parameters, 0, "Result parameters");
is($result->available_statistics, 0, "Result statistics");
is($result->database_entries, '', "Result entries");
is($result->database_letters, '', "Result letters");
is($result->database_name, 'b_sub.fas', "Result database_name");
is($result->num_hits, 2, "Result num_hits");
is($result->program_reference, undef, "Result program_reference");
is($result->query_accession, 'RF00167', "Result query_accession");
is($result->query_description, 'Purine riboswitch', "Result query_description");
is($result->query_length, 102, "Result query_length");
is($result->query_name, 'Purine', "Result query_name");

$hit = $result->next_hit;
$hit->verbose(2);

isa_ok($hit, 'Bio::Search::Hit::HitI');
is($hit->ncbi_gi, '2239287', "Hit GI");
is($hit->accession, 'U51115.1', "Hit accession");
is($hit->algorithm, 'CMSEARCH', "Hit algorithm");
is($hit->bits, 81.29, "Hit bits");
is($hit->description, '', "Hit description"); # no hit descs yet
is($hit->locus, 'BSU51115', "Hit locus");
is($hit->n, 2, "Hit n");
is($hit->name, 'gi|2239287|gb|U51115.1|BSU51115', "Hit name");
is($hit->num_hsps, 2, "Hit num_hsps");

# These Bio::Search::Hit::HitI methods are currently unimplemented in
# Bio::Search::Hit::ModelHit; they may be integrated over time but will require
# some reconfiguring for Model-based searches

eval { $hit->length_aln() };
like($@, qr'length_aln not implemented for Model-based searches',
     "Hit length_aln() not implemented");
eval {$hit->num_unaligned_hit};
like($@, qr'num_unaligned_hit/num_unaligned_sbjct not implemented for Model-based searches',
     "Hit num_unaligned_hit() not implemented");
eval {$hit->num_unaligned_query};
like($@, qr'num_unaligned_query not implemented for Model-based searches',
     "Hit num_unaligned_query() not implemented");
eval {$hit->num_unaligned_sbjct};
like($@, qr'num_unaligned_hit/num_unaligned_sbjct not implemented for Model-based searches',
     "Hit num_unaligned_sbjct() not implemented");
eval {$hit->start};
like($@, qr'start not implemented for Model-based searches','Hit start not implemented');
eval {$hit->end};
like($@, qr'end not implemented for Model-based searches','Hit end not implemented');
eval {$hit->strand};
like($@, qr'strand not implemented for Model-based searches','Hit strand not implemented');
eval {$hit->logical_length};
like($@, qr'logical_length not implemented for Model-based searches','Hit logical_length not implemented');
eval {$hit->frac_aligned_hit};
like($@, qr'frac_aligned_hit not implemented for Model-based searches','Hit frac_aligned_hit not implemented');
eval{$hit->frac_aligned_query};
like($@, qr'frac_aligned_query not implemented for Model-based searches','Hit frac_aligned_query not implemented');
eval {$hit->frac_conserved};
like($@, qr'frac_conserved not implemented for Model-based searches','Hit frac_conserved not implemented');
eval{$hit->frac_identical};
like($@, qr'frac_identical not implemented for Model-based searches','Hit frac_identical not implemented');
eval{$hit->matches};
like($@, qr'matches not implemented for Model-based searches','Hit matches not implemented');
eval{$hit->gaps};
like($@, qr'gaps not implemented for Model-based searches','Hit gaps not implemented');
eval{$hit->frame};
like($@, qr'frame not implemented for Model-based searches','Hit frame not implemented');
eval {$hit->range};
like($@, qr'range not implemented for Model-based searches','Hit range not implemented');
eval {$hit->seq_inds};
like($@, qr'seq_inds not implemented for Model-based searches','Hit seq_inds not implemented');

# p() works but there are no evalues yet for Infernal output, so catch and check...
eval {$hit->p};
like($@, qr'P-value not defined. Using expect\(\) instead',
     "No p values");

is($hit->length, 0, "Hit length");
is($hit->overlap, 0, "Hit overlap");
is($hit->query_length, 102, "Hit query_length");
is($hit->rank, 1, "Hit rank");
is($hit->raw_score, 81.29, "Hit raw_score");
is($hit->score, 81.29, "Hit score");
float_is($hit->significance, undef);

$hsp = $hit->next_hsp;
isa_ok($hsp, 'Bio::Search::HSP::HSPI');
is($hsp->algorithm, 'CMSEARCH', "HSP algorithm");
float_is($hsp->evalue, undef);
isa_ok($hsp->feature1, 'Bio::SeqFeature::Similarity');
isa_ok($hsp->feature2, 'Bio::SeqFeature::Similarity');
($meta) = $hsp->feature1->get_tag_values('meta');
is($meta, ':::::::::::::::::((((((((,,,<<<<<<<_______>>>>>>>,,,,,,,,<<<<<<<_______>>>>>>>,,)))).))))::::::::::::::');
($meta) = $hsp->feature2->get_tag_values('meta');
is($meta, ':::::::::::::::::((((((((,,,<<<<<<<_______>>>>>>>,,,,,,,,<<<<<<<_______>>>>>>>,,)))).))))::::::::::::::');

is($hsp->frame('query'), 0, "HSP frame");
is($hsp->gaps, 0, "HSP gaps");
is($hit->length, 0, "Hit length");
isa_ok($hsp->get_aln, 'Bio::Align::AlignI');
isa_ok($hsp->hit, 'Bio::SeqFeature::Similarity', "HSP hit");
is($hsp->hit_string,
   'CAUGAAAUCAAAACACGACCUCAUAUAAUCUUGGGAAUAUGGCCCAUAAGUUUCUACCCGGCAACCGUAAAUUGCCGGACUAUGcAGGGAAGUGAUCGAUAAA',
   "HSP hit_string");
is($hsp->homology_string,
   ' A+ A+A+ AAAA A   :CUC:UAUAAU: :GGGAAUAUGGCCC: :AGUUUCUACC:GGCAACCGUAAAUUGCC:GACUA:G AG: AA + ++  +++++',
   "HSP homology_string");
is($hsp->hsp_group, undef, "HSP hsp_group");
is($hsp->hsp_length, 103, "HSP hsp_length");
is($hsp->length, 103, "HSP length");
is($hsp->links, undef, "HSP links");
is($hsp->n, '', "HSP n");
float_is($hsp->pvalue, undef, "HSP pvalue");
isa_ok($hsp->query, 'Bio::SeqFeature::Similarity', "HSP query");
is($hsp->query_string,
   'aAaaauaaAaaaaaaaauaCuCgUAUAaucucgggAAUAUGGcccgagaGUuUCUACCaGgcaaCCGUAAAuugcCuGACUAcG.aGuaAauauuaaauauuu',
   "HSP query_string");
is($hsp->range, 102, "HSP range");
is($hsp->rank, 1, "HSP rank");
float_is($hsp->significance, undef);
is($hsp->end, 102, "HSP end");
float_is($hsp->expect, undef, "HSP expect");
$hsp->verbose(2);
# These Bio::Search::HSP::HSPI methods are currently unimplemented in
# Bio::Search::HSP::ModelHSP; they may be integrated over time but will require
# some reconfiguring for Model-based searches

eval {$hsp->seq_inds};
like($@, qr'seq_inds not implemented for Model-based searches','HSP seq_inds not implemented');
eval {$hsp->matches};
like($@, qr'matches not implemented for Model-based searches','HSP matches not implemented');
eval {$hsp->frac_conserved};
like($@, qr'frac_conserved not implemented for Model-based searches','HSP frac_conserved not implemented');
eval {$hsp->frac_identical};
like($@, qr'frac_identical not implemented for Model-based searches','HSP frac_identical not implemented');
eval {$hsp->num_conserved};
like($@, qr'num_conserved not implemented for Model-based searches','HSP num_conserved not implemented');
eval {$hsp->num_identical};
like($@, qr'num_identical not implemented for Model-based searches','HSP num_identical not implemented');
eval {$hsp->percent_identity};
like($@, qr'percent_identity not implemented for Model-based searches','HSP percent_identity not implemented');
eval {$hsp->cigar_string};
like($@, qr'cigar_string not implemented for Model-based searches','HSP cigar_string not implemented');
eval {$hsp->generate_cigar_string};
like($@, qr'generate_cigar_string not implemented for Model-based searches','HSP cigar_string not implemented');

isa_ok($hsp->seq, 'Bio::LocatableSeq');
is($hsp->seq_str,
   'aAaaauaaAaaaaaaaauaCuCgUAUAaucucgggAAUAUGGcccgagaGUuUCUACCaGgcaaCCGUAAAuugcCuGACUAcG.aGuaAauauuaaauauuu',
   "HSP seq_str");
is($hsp->start, 1, "HSP start");
is($hsp->custom_score, undef, "HSP custom_score");
is($hsp->meta,
   ':::::::::::::::::((((((((,,,<<<<<<<_______>>>>>>>,,,,,,,,<<<<<<<_______>>>>>>>,,)))).))))::::::::::::::',
   "HSP meta");
is($hsp->strand('hit'), 1, "HSP strand");

$hsp = $hit->next_hsp;
isa_ok($hsp, 'Bio::Search::HSP::HSPI');
is($hsp->algorithm, 'CMSEARCH', "HSP algorithm");
float_is($hsp->evalue, undef);
isa_ok($hsp->feature1, 'Bio::SeqFeature::Similarity');
isa_ok($hsp->feature2, 'Bio::SeqFeature::Similarity');
is($hsp->frame('query'), 0, "HSP frame");
is($hsp->gaps, 0, "HSP gaps");
# infernal can return alignment data
isa_ok($hsp->get_aln, 'Bio::Align::AlignI');
isa_ok($hsp->hit, 'Bio::SeqFeature::Similarity', "HSP hit");
is($hsp->hit_string,
   'AGAAAUCAAAUAAGAUGAAUUCGUAUAAUCGCGGGAAUAUGGCUCGCAAGUCUCUACCAAGCUACCGUAAAUGGCUUGACUACGUAAACAUUUCUUUCGUUU',
   "HSP hit_string");
is($hsp->homology_string,
   'A AAAU AAA+AA A+   : CGUAUAAU::CG:GAAUAUGGC:CG::AGU UCUACCA:GC ACCGUAAAU GC:UGACUACG :   AU+U +++  UUU',
   "HSP homology_string");
is($hsp->hsp_group, undef, "HSP hsp_group");
is($hsp->hsp_length, 103, "HSP hsp_length");
is($hsp->length, 103, "HSP length");
is($hsp->links, undef, "HSP links");
is($hsp->n, '', "HSP n");
float_is($hsp->pvalue, undef, "HSP pvalue");
isa_ok($hsp->query, 'Bio::SeqFeature::Similarity', "HSP query");
is($hsp->query_string,
   'aAaaauaaAaaaaaaaauaCuCgUAUAaucucgggAAUAUGGcccgagaGUuUCUACCaGgcaaCCGUAAAuugcCuGACUAcGaGuaAauauuaaauauuu',
   "HSP query_string");
is($hsp->range, 102, "HSP range");
is($hsp->rank, 2, "HSP rank");
float_is($hsp->significance, undef);
is($hsp->end, 102, "HSP end");
float_is($hsp->expect, undef, "HSP expect");
#is($hsp->matches, 2, "HSP matches");
isa_ok($hsp->seq, 'Bio::LocatableSeq');
# this should probably default to the hit string
is($hsp->seq_str,
   'aAaaauaaAaaaaaaaauaCuCgUAUAaucucgggAAUAUGGcccgagaGUuUCUACCaGgcaaCCGUAAAuugcCuGACUAcGaGuaAauauuaaauauuu',
   "HSP seq_str");
is($hsp->start, 1, "HSP start");
is($hsp->custom_score, undef, "HSP custom_score");
is($hsp->meta,
   ':::::::::::::::::((((((((,,,<<<<<<<_______>>>>>>>,,,,,,,,<<<<<<<_______>>>>>>>,,))))))))::::::::::::::',
   "HSP meta");
is($hsp->strand('hit'), 1, "HSP strand");

# one more hit...

$hit = $result->next_hit;
isa_ok($hit, 'Bio::Search::Hit::HitI');
is($hit->accession, 'X83878.1', "Hit accession");
is($hit->ncbi_gi, '633168', "Hit GI");
is($hit->algorithm, 'CMSEARCH', "Hit algorithm");
is($hit->bits, 79.36, "Hit bits");
is($hit->description, '', "Hit description"); # no hit descs yet
is($hit->length, 0, "Hit length");
is($hit->locus, '', "Hit locus");
is($hit->n, 1, "Hit n");
is($hit->name, 'gi|633168|emb|X83878.1|', "Hit name");
is($hit->num_hsps, 1, "Hit num_hsps"); 
is($hit->overlap, 0, "Hit overlap");
is($hit->query_length, 102, "Hit query_length");
is($hit->rank, 2, "Hit rank");
is($hit->raw_score, 79.36, "Hit raw_score");
is($hit->score, 79.36, "Hit score");
float_is($hit->significance, undef);

# one more HSP...

$hsp = $hit->next_hsp;
isa_ok($hsp, 'Bio::Search::HSP::HSPI');
is($hsp->algorithm, 'CMSEARCH', "HSP algorithm");
float_is($hsp->evalue, undef);
isa_ok($hsp->feature1, 'Bio::SeqFeature::Similarity');
isa_ok($hsp->feature2, 'Bio::SeqFeature::Similarity');
is($hsp->frame('query'), 0, "HSP frame");
is($hsp->gaps, 2, "HSP gaps");
isa_ok($hsp->get_aln, 'Bio::Align::AlignI');
isa_ok($hsp->hit, 'Bio::SeqFeature::Similarity', "HSP hit");
is($hsp->hit_string,
   'UUACAAUAUAAUAGGAACACUCAUAUAAUCGCGUGGAUAUGGCACGCAAGUUUCUACCGGGCA-CCGUAAA-UGUCCGACUAUGGGUGAGCAAUGGAACCGC',
   "HSP hit_string");
is($hsp->homology_string,
   '+ A A++A AA A  AA:AC+C:UAUAAU::CG:G AUAUGGC:CG::AGUUUCUACC:G CA CCGUAAA UG C:GACUA:G+GU:A  A+U  A+    ',
   "HSP homology_string");
is($hsp->hsp_group, undef, "HSP hsp_group");
is($hsp->hsp_length, 103, "HSP hsp_length");
is($hsp->length, 103, "HSP length");
is($hsp->links, undef, "HSP links");
is($hsp->n, '', "HSP n");
isa_ok($hsp->query, 'Bio::SeqFeature::Similarity', "HSP query");
is($hsp->query_string,
   'aAaaauaaAaaaaaaaauaCuCgUAUAaucucgggAAUAUGGcccgagaGUuUCUACCaGgcaaCCGUAAAuugcCuGACUAcGaGuaAauauuaaauauuu',
   "HSP query_string");
is($hsp->range, 102, "HSP range");
is($hsp->rank, 1, "HSP rank");
float_is($hsp->significance, undef);
is($hsp->end, 102, "HSP end");
float_is($hsp->expect, undef, "HSP expect");
isa_ok($hsp->seq, 'Bio::LocatableSeq');
is($hsp->seq_str,
   'aAaaauaaAaaaaaaaauaCuCgUAUAaucucgggAAUAUGGcccgagaGUuUCUACCaGgcaaCCGUAAAuugcCuGACUAcGaGuaAauauuaaauauuu',
   "HSP seq_str");
is($hsp->start, 1, "HSP start");
is($hsp->custom_score, undef, "HSP custom_score");
is($hsp->meta,
   ':::::::::::::::::((((((((,,,<<<<<<<_______>>>>>>>,,,,,,,,<<<<<<<_______>>>>>>>,,))))))))::::::::::::::',
   "HSP meta");
is($hsp->strand('hit'), 1, "HSP strand");

my $symbols = {
            '5-prime'        => '(',
            '3-prime'        => ')',
            'single-strand'  => ':',
            'unknown'        => '?',
            'gap'            => '-'
             # may add more for quartets, triplets
              };

$searchio = Bio::SearchIO->new( -format => 'infernal',
                                -file   => test_input_file('test.infernal'),
                                # version is reset to the correct one by parser
                                -version => 0.7, 
                                -model => 'Purine',
                                -query_acc => 'RF00167',
                                -query_desc => 'Purine riboswitch',
                                -database => 'b_sub.fas',
                                -hsp_minscore => 40,
                                -convert_meta => 1,
                                -symbols => $symbols,
                               );

$result = $searchio->next_result;
$hit = $result->next_hit;
$hsp = $hit->next_hsp;
is($hsp->meta,
   ':::::::::::::::::((((((((:::(((((((:::::::)))))))::::::::(((((((:::::::)))))))::))))-))))::::::::::::::',
   "HSP meta gap bug");
$hsp = $hit->next_hsp;
is($hsp->meta,
   ':::::::::::::::::((((((((:::(((((((:::::::)))))))::::::::(((((((:::::::)))))))::))))))))::::::::::::::',
   "HSP meta");
$hit = $result->next_hit;
$hsp = $hit->next_hsp;
is($hsp->meta,
   ':::::::::::::::::((((((((:::(((((((:::::::)))))))::::::::(((((((:::::::)))))))::))))))))::::::::::::::',
   "HSP meta");
($meta) = $hsp->feature1->get_tag_values('meta');
is($meta, ':::::::::::::::::((((((((:::(((((((:::::::)))))))::::::::(((((((:::::::)))))))::))))))))::::::::::::::');
($meta) = $hsp->feature2->get_tag_values('meta');
is($meta, ':::::::::::::::::((((((((:::(((((((:::::::)))))))::::::::(((((((:::::::)))))))::))))))))::::::::::::::');

## Infernal 0.81 parsing ##

$searchio = Bio::SearchIO->new( -format => 'infernal',
                                -file   => test_input_file('purine_v081.infernal'),
                                # version is reset to the correct one by parser
                                -query_acc => 'RF00167',
                                -query_desc => 'Purine riboswitch',
                                -database => 'b_sub.fas',
                                -convert_meta => 0,
                               );

$result = $searchio->next_result;

isa_ok($result, 'Bio::Search::Result::ResultI');
$algorithm = $result->algorithm;
is($result->algorithm, 'CMSEARCH', "Result $algorithm");
is($result->algorithm_reference, undef, "Result $algorithm reference");
is($result->algorithm_version, 0.81, "Result $algorithm version");
is($result->available_parameters, 0, "Result parameters");
is($result->available_statistics, 0, "Result statistics");
is($result->database_entries, '', "Result entries");
is($result->database_letters, '', "Result letters");
is($result->database_name, 'b_sub.fas', "Result database_name");
is($result->num_hits, 3, "Result num_hits");
is($result->program_reference, undef, "Result program_reference");
is($result->query_accession, 'RF00167', "Result query_accession");
is($result->query_description, 'Purine riboswitch', "Result query_description");
is($result->query_length, 102, "Result query_length");
is($result->query_name, 'Purine', "Result query_name");

$hit = $result->next_hit;
$hit->verbose(2);
isa_ok($hit, 'Bio::Search::Hit::HitI');
is($hit->ncbi_gi, '633168', "Hit GI");
is($hit->accession, 'X83878.1', "Hit accession");
is($hit->algorithm, 'CMSEARCH', "Hit algorithm");
is($hit->bits, 79.36, "Hit bits");
is($hit->description, '', "Hit description"); # no hit descs yet
is($hit->locus, '', "Hit locus");
is($hit->n, 2, "Hit n");
is($hit->name, 'gi|633168|emb|X83878.1|', "Hit name");
is($hit->num_hsps, 2, "Hit num_hsps");

# p() works but there are no evalues yet for Infernal output, so catch and check...
eval {$hit->p};
like($@, qr'P-value not defined. Using expect\(\) instead',
     "No p values");

is($hit->length, 0, "Hit length");
is($hit->overlap, 0, "Hit overlap");
is($hit->query_length, 102, "Hit query_length");
is($hit->rank, 1, "Hit rank");
is($hit->raw_score, 79.36, "Hit raw_score");
is($hit->score, 79.36, "Hit score");
float_is($hit->significance, 1.945e-07);

$hsp = $hit->next_hsp;
isa_ok($hsp, 'Bio::Search::HSP::HSPI');
is($hsp->algorithm, 'CMSEARCH', "HSP algorithm");
float_is($hsp->evalue, 1.945e-07);
isa_ok($hsp->feature1, 'Bio::SeqFeature::Similarity');
isa_ok($hsp->feature2, 'Bio::SeqFeature::Similarity');
($meta) = $hsp->feature1->get_tag_values('meta');
is($meta, ':::::::::::::::::((((((((,,,<<<<<<<_______>>>>>>>,,,,,,,,<<<<<<<_______>>>>>>>,,))))))))::::::::::::::');
($meta) = $hsp->feature2->get_tag_values('meta');
is($meta, ':::::::::::::::::((((((((,,,<<<<<<<_______>>>>>>>,,,,,,,,<<<<<<<_______>>>>>>>,,))))))))::::::::::::::');

is($hsp->frame('query'), 0, "HSP frame");
is($hsp->gaps, 2, "HSP gaps");
is($hit->length, 0, "Hit length");
isa_ok($hsp->get_aln, 'Bio::Align::AlignI');
isa_ok($hsp->hit, 'Bio::SeqFeature::Similarity', "HSP hit");
is($hsp->hit_string,
   'UUACAAUAUAAUAGGAACACUCAUAUAAUCGCGUGGAUAUGGCACGCAAGUUUCUACCGGGCA-CCGUAAA-UGUCCGACUAUGGGUGAGCAAUGGAACCGC',
   "HSP hit_string");
is($hsp->homology_string,
   '+ A A++A AA A  AA:AC+C:UAUAAU::CG:G AUAUGGC:CG::AGUUUCUACC:G CA CCGUAAA UG C:GACUA:G+GU:A  A+U  A+    ',
   "HSP homology_string");
is($hsp->hsp_group, undef, "HSP hsp_group");
is($hsp->hsp_length,102, "HSP hsp_length");
is($hsp->length, 102, "HSP length");
is($hsp->links, undef, "HSP links");
is($hsp->n, '', "HSP n");
float_is($hsp->pvalue, 1.945e-07, "HSP pvalue");
isa_ok($hsp->query, 'Bio::SeqFeature::Similarity', "HSP query");
is($hsp->query_string,
   'aAaaauaaAaaaaaaaauaCuCgUAUAaucucgggAAUAUGGcccgagaGUuUCUACCaGgcaaCCGUAAAuugcCuGACUAcGaGuaAauauuaaauauuu',
   "HSP query_string");
is($hsp->range, 102, "HSP range");
is($hsp->rank, 1, "HSP rank");
float_is($hsp->significance, 1.945e-07);
is($hsp->end, 102, "HSP end");
float_is($hsp->expect, 1.945e-07, "HSP expect");

isa_ok($hsp->seq, 'Bio::LocatableSeq');
is($hsp->seq_str,
   'aAaaauaaAaaaaaaaauaCuCgUAUAaucucgggAAUAUGGcccgagaGUuUCUACCaGgcaaCCGUAAAuugcCuGACUAcGaGuaAauauuaaauauuu',
   "HSP seq_str");
is($hsp->start, 1, "HSP start");
is($hsp->custom_score, undef, "HSP custom_score");
is($hsp->meta,
   ':::::::::::::::::((((((((,,,<<<<<<<_______>>>>>>>,,,,,,,,<<<<<<<_______>>>>>>>,,))))))))::::::::::::::',
   "HSP meta");
is($hsp->strand('hit'), 1, "HSP strand");

$hsp = $hit->next_hsp;
isa_ok($hsp, 'Bio::Search::HSP::HSPI');
is($hsp->algorithm, 'CMSEARCH', "HSP algorithm");
float_is($hsp->evalue, 6.802);
isa_ok($hsp->feature1, 'Bio::SeqFeature::Similarity');
isa_ok($hsp->feature2, 'Bio::SeqFeature::Similarity');
is($hsp->frame('query'), 0, "HSP frame");
is($hsp->gaps, 3, "HSP gaps");
# infernal can return alignment data
isa_ok($hsp->get_aln, 'Bio::Align::AlignI');
isa_ok($hsp->hit, 'Bio::SeqFeature::Similarity', "HSP hit");
is($hsp->hit_string,
   'CGUGCGGUUCCAUUGCUCACCCAUA-GUCGGACAU-UUACGG-UGCCCGGUAGAAACUUGCGUGCCAUAUCCACGCGAUUaUAUGAGUGUUCCUAUUAUAUUG',
   "HSP hit_string");
is($hsp->homology_string,
   '  +    +   A    +:AC C:UA  +::: ::   UA GG :: :::GU    AC: G::::CC UA  ::::C :   UA:G GU: +  U+++AUAUU ',
   "HSP homology_string");
is($hsp->hsp_group, undef, "HSP hsp_group");
is($hsp->hsp_length, 102, "HSP hsp_length");
is($hsp->length, 102, "HSP length");
is($hsp->links, undef, "HSP links");
is($hsp->n, '', "HSP n");
float_is($hsp->pvalue, 0.9989, "HSP pvalue");
isa_ok($hsp->query, 'Bio::SeqFeature::Similarity', "HSP query");
is($hsp->query_string,
   'aAaaauaaAaaaaaaaauaCuCgUAUAaucucgggAAUAUGGcccgagaGUuUCUACCaGgcaaCCGUAAAuugcCuGAC.UAcGaGuaAauauuaaauauuu',
   "HSP query_string");
is($hsp->range, 102, "HSP range");
is($hsp->rank, 2, "HSP rank");
float_is($hsp->significance, 6.802);
is($hsp->end, 102, "HSP end");
float_is($hsp->expect, 6.802, "HSP expect");
#is($hsp->matches, 2, "HSP matches");
isa_ok($hsp->seq, 'Bio::LocatableSeq');
# this should probably default to the hit string
is($hsp->seq_str,
   'aAaaauaaAaaaaaaaauaCuCgUAUAaucucgggAAUAUGGcccgagaGUuUCUACCaGgcaaCCGUAAAuugcCuGAC.UAcGaGuaAauauuaaauauuu',
   "HSP seq_str");
is($hsp->start, 1, "HSP start");
is($hsp->custom_score, undef, "HSP custom_score");
is($hsp->meta,
   ':::::::::::::::::((((((((,,,<<<<<<<_______>>>>>>>,,,,,,,,<<<<<<<_______>>>>>>>,,.))))))))::::::::::::::',
   "HSP meta");
is($hsp->strand('hit'), -1, "HSP strand");

# one more hit...

$hit = $result->next_hit;
isa_ok($hit, 'Bio::Search::Hit::HitI');
is($hit->accession, 'U51115.1', "Hit accession");
is($hit->ncbi_gi, '2239287', "Hit GI");
is($hit->algorithm, 'CMSEARCH', "Hit algorithm");
is($hit->bits, 81.29, "Hit bits");
is($hit->description, '', "Hit description"); # no hit descs yet
is($hit->length, 0, "Hit length");
is($hit->locus, 'BSU51115', "Hit locus");
is($hit->n, 11, "Hit n");
is($hit->name, 'gi|2239287|gb|U51115.1|BSU51115', "Hit name");
is($hit->num_hsps, 11, "Hit num_hsps"); 
is($hit->overlap, 0, "Hit overlap");
is($hit->query_length, 102, "Hit query_length");
is($hit->rank, 2, "Hit rank");
is($hit->raw_score, 81.29, "Hit raw_score");
is($hit->score, 81.29, "Hit score");
float_is($hit->significance, 1.259e-07);

# one more HSP...

$hsp = $hit->next_hsp;
isa_ok($hsp, 'Bio::Search::HSP::HSPI');
is($hsp->algorithm, 'CMSEARCH', "HSP algorithm");
float_is($hsp->evalue, 1.259e-07);
isa_ok($hsp->feature1, 'Bio::SeqFeature::Similarity');
isa_ok($hsp->feature2, 'Bio::SeqFeature::Similarity');
is($hsp->frame('query'), 0, "HSP frame");
is($hsp->gaps, 0, "HSP gaps");
isa_ok($hsp->get_aln, 'Bio::Align::AlignI');
isa_ok($hsp->hit, 'Bio::SeqFeature::Similarity', "HSP hit");
is($hsp->hit_string,
   'AGAAAUCAAAUAAGAUGAAUUCGUAUAAUCGCGGGAAUAUGGCUCGCAAGUCUCUACCAAGCUACCGUAAAUGGCUUGACUACGUAAACAUUUCUUUCGUUU',
   "HSP hit_string");
is($hsp->homology_string,
   'A AAAU AAA+AA A+   : CGUAUAAU::CG:GAAUAUGGC:CG::AGU UCUACCA:GC ACCGUAAAU GC:UGACUACG :   AU+U +++  UUU',
   "HSP homology_string");
is($hsp->hsp_group, undef, "HSP hsp_group");
is($hsp->hsp_length, 102, "HSP hsp_length");
is($hsp->length, 102, "HSP length");
is($hsp->links, undef, "HSP links");
is($hsp->n, '', "HSP n");
isa_ok($hsp->query, 'Bio::SeqFeature::Similarity', "HSP query");
is($hsp->query_string,
   'aAaaauaaAaaaaaaaauaCuCgUAUAaucucgggAAUAUGGcccgagaGUuUCUACCaGgcaaCCGUAAAuugcCuGACUAcGaGuaAauauuaaauauuu',
   "HSP query_string");
is($hsp->range, 102, "HSP range");
is($hsp->rank, 1, "HSP rank");
float_is($hsp->significance, 1.259e-07);
is($hsp->end, 102, "HSP end");
float_is($hsp->expect, 1.259e-07, "HSP expect");
isa_ok($hsp->seq, 'Bio::LocatableSeq');
is($hsp->seq_str,
   'aAaaauaaAaaaaaaaauaCuCgUAUAaucucgggAAUAUGGcccgagaGUuUCUACCaGgcaaCCGUAAAuugcCuGACUAcGaGuaAauauuaaauauuu',
   "HSP seq_str");
is($hsp->start, 1, "HSP start");
is($hsp->custom_score, undef, "HSP custom_score");
is($hsp->meta,
   ':::::::::::::::::((((((((,,,<<<<<<<_______>>>>>>>,,,,,,,,<<<<<<<_______>>>>>>>,,))))))))::::::::::::::',
   "HSP meta");
is($hsp->strand('hit'), 1, "HSP strand");

