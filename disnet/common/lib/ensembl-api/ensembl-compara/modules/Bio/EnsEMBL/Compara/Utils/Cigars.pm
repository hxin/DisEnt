=head1 LICENSE

Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut


=head1 CONTACT

Please email comments or questions to the public Ensembl
developers list at <dev@ensembl.org>.

Questions may also be sent to the Ensembl help desk at
<helpdesk@ensembl.org>.

=head1 AUTHORSHIP

Ensembl Team. Individual contributions can be found in the CVS log.

=head1 DESCRIPTION

This modules contains common methods used when dealing with CIGAR lines.
CIGAR stands for "Compact Idiosyncratic Gapped Alignment Report" and is
a format to store alignment strings in a compact way.

The CIGAR line defines the sequence of matches/mismatches and deletions
(or gaps). For example, this cigar line 2MD3M2D2M will mean that the
alignment contains 2 matches/mismatches, 1 deletion (number 1 is omitted
in order to save some space), 3 matches/mismatches, 2 deletions and 2
matches/mismatches.

For example, given the following
 - original sequence: AACGCTT
 - cigar line: 2MD3M2D2M

The aligned sequence will be:
 M M D M M M D D M M
 A A - C G C - - T T

=head1 SYNOPSIS

 my $orig_seq = 'AACGCTT';
 my $cigar_line = '2MD3M2D2M';
 my $expanded_cigar = 'MMDMMMDDMM';
 my $aligned_seq = 'AA-CGC--TT';

 (compose_sequence_with_cigar($orig_seq, $cigar_line) ne $aligned_seq) or die;
 (cigar_from_alignment_string($aligned_seq) ne $cigar_line) or die;
 (expand_cigar($cigar_line) ne $expanded_cigar) or die;
 (collapse_cigar($expanded_cigar) ne $cigar_line) or die;

=head1 METHODS

=cut

package Bio::EnsEMBL::Compara::Utils::Cigars;

use strict;
use warnings;
no warnings ('substr');

use Bio::EnsEMBL::Utils::Exception;

use Data::Dumper;


=head2 compose_sequence_with_cigar

  Arg [1]    : String $sequence
  Arg [2]    : String $cigar_line
  Arg [3]    : Integer $expansion_factor (default: 1)
  Example    : my $alignment_string = compose_sequence_with_cigar($aligned_member->other_sequence('cds'), $aligned_member->cigar_line, 3)
  Description: Converts the given sequence into an alignment string
               by composing it with the cigar_line. $expansion_factor
               can be set to accomodate CDS sequences
  Returntype : string

=cut

sub compose_sequence_with_cigar {
    my $sequence = shift;
    my $cigar_line = shift;
    my $expansion_factor = shift || 1;

    my $alignment_string = "";
    my $seq_start = 0;

    while ($cigar_line =~ /(\d*)([A-Z])/g) {

        my $length = ($1 || 1) * $expansion_factor;
        my $char = $2;

        if ($char eq 'D') {

            $alignment_string .= "-" x $length;

        } elsif ($char eq 'M' or $char eq 'I') {

            my $substring = substr($sequence, $seq_start, $length);
            if ($substring =~ /\ /) {
                my $num_boundaries = $substring =~ s/(\ )/$1/g;
                $length += $num_boundaries;
                $substring = substr($sequence,$seq_start,$length);
            }
            if (length($substring) < $length) {
                $substring .= ('N' x ($length - length($substring)));
            }
            $alignment_string .= $substring if ($char eq 'M');
            $seq_start += $length;

        }
    }
    return $alignment_string;
}


=head2 cigar_from_alignment_string

  Arg [1]    : String $alignment_string
  Example    : my $cigar_line = cigar_from_alignment_string($alignment_string)
  Description: Converts the given aligned sequence into a cigar line.
               The gaps indicated by '-' in the alignment string are
               transformed in 'D'. The matches (non '-' character) are
               transformed in 'M'.
  Returntype : string

=cut

sub cigar_from_alignment_string {
    my $alignment_string = shift;
    $alignment_string =~ s/\*/X/g;

    my $cigar_line = '';
    while($alignment_string=~/(?:\b|^)(.)(.*?)(?:\b|$)/g) {
        $cigar_line .= ($2 ? length($2)+1 : '').(($1 eq '-') ? 'D' : 'M');
    }

    return $cigar_line;
}


=head2 expand_cigar

  Arg [1]    : String $cigar_line
  Example    : my $expanded_cigar = expand_cigar($cigar_line)
  Description: Expands each block of the cigar line (like '4D')
               into a string of the matching length (here: 'DDDD')
  Returntype : string

=cut

sub expand_cigar {
    my $cigar = shift;
    my $expanded_cigar = '';
    #$cigar =~ s/(\d*)([A-Z])/$2 x ($1||1)/ge; #Expand
    while ($cigar =~ /(\d*)([A-Z])/g) {
        $expanded_cigar .= $2 x ($1 || 1);
    }
    return $expanded_cigar;
}


=head2 collapse_cigar

  Arg [1]    : String $cigar_line
  Example    : my $collapsed_cigar = collapse_cigar($cigar_line)
  Description: Collapses each stretch of the cigar line (like 'DDDD')
               into a compact form (here: '4D')
  Returntype : string

=cut

sub collapse_cigar {
    my $cigar = shift;
    my $collapsed_cigar = '';
    while ($cigar =~ /(\w)(\1*)/g) {
        $collapsed_cigar .= $2 ? (length($2)+1).$1 : $1;
    }
    return $collapsed_cigar;
}


=head2 consensus_cigar_line

  Arg [1..n] : String $cigar_line
  Example    : my $consensus_cigar = consensus_cigar_line($cigar1, $cigar2, $cigar3);
  Description: Creates a consensus cigar line showing the conservation of
               each position. The final cigar line is based on the three
               characters D, m, and M:
                - M indicates that the conservation is > 2/3
                - m indicates that the conservation is between 1/3 and 2/3
                - D indicates that the conservation is < 1/3
  Returntype : string

=cut

sub consensus_cigar_line {

   my @expanded_cigars = map {expand_cigar($_)} @_;
   my $num_cigars = scalar(@expanded_cigars);

   my @chars = qw(M m D);
   my $n_chars = scalar(@chars);
   push @chars, $chars[$n_chars-1];

   # Itterate through each character of the expanded cigars.
   # If there is a 'D' at a given location in any cigar,
   # set the consensus to 'D', otherwise assume an 'M'.
   # TODO: Fix assumption that cigar strings are always the same length,
   # and start at the same point.

   my $cigar_len = length( $expanded_cigars[0] );
   my $cons_cigar;
   for( my $i=0; $i<$cigar_len; $i++ ){
       my $num_deletions = 0;
       foreach my $cigar (@expanded_cigars) {
           if ( substr($cigar,$i,1) eq 'D'){
               $num_deletions++;
           }
       }
       $cons_cigar .= $chars[int($num_deletions * $n_chars / $num_cigars)];
   }

   return collapse_cigar($cons_cigar);
}


=head2 cigar_from_two_alignment_strings

  Arg [1]    : String $alignment_string1
  Arg [2]    : String $alignment_string2
  Example    : my $cigar = cigar_from_two_alignment_strings($alignment_string1, $alignment_string2);
  Description: Creates a cigar_line that refers to both alignment strings.
               The character set is composed of D, M, and I.
                - D shows a deletion in the first sequence
                - I shows a deletion in the second sequence
                - M shows a match between the two sequences
               Double gaps are not allowed.
  Exceptions : Dies if the two alignment strings have a gap at the same
               position
  Returntype : string

=cut

sub cigar_from_two_alignment_strings {

    my $seq1 = shift;
    my $seq2 = shift;

    my @chunks1;
    my @chunks2;

    while($seq1=~/(?:\b|^)(.)(.*?)(?:\b|$)/g) {
        push @chunks1, [($1 eq '-'), ($2 ? length($2)+1 : 1)];
    }
    while($seq2=~/(?:\b|^)(.)(.*?)(?:\b|$)/g) {
        push @chunks2, [($1 eq '-'), ($2 ? length($2)+1 : 1)];
    }

    my $len1;
    my $gap1;
    my $len2;
    my $gap2;
    my $cigar_line;
    while (@chunks1 or @chunks2) {

        ($gap1, $len1) = @{shift @chunks1} unless $len1;
        ($gap2, $len2) = @{shift @chunks2} unless $len2;
        die "Double gaps are not allowed in '$seq1' / '$seq2'" if $gap1 and $gap2;

        my $minlen = $len1 <= $len2 ? $len1 : $len2;
        $cigar_line .= ($minlen > 1 ? $minlen : '').($gap1 ? 'D' : ($gap2 ? 'I' : 'M'));
        $len2 -= $minlen;
        $len1 -= $minlen;
    };
    die "lengths do not match: $len1 / $len2" if $len1 or $len2;
    return $cigar_line;
}


=head2 minimize_cigars

  Arg [1..n] : String $cigar_lines
  Example    : my @subcigars = minimize_cigars($member1->cigar_line, $member2->cigar_line);
  Description: Removes the columns that are composed of gaps only and
               builds shorter cigar lines.
  Returntype : array of strings

=cut

sub minimize_cigars {

    my @expanded_cigars = map {[split(//, expand_cigar($_))]} @_;
    my $num_cigars = scalar(@expanded_cigars);
    my $len = scalar(@{$expanded_cigars[0]});

    my @good_i;
    foreach my $i (0..($len-1)) {
        if (grep {$_->[$i] eq 'M'} @expanded_cigars) {
            push @good_i, $i;
        }
    }

    my @new_cigars;
    foreach my $exp_cig (@expanded_cigars) {
        push @new_cigars, collapse_cigar(join('', map {$exp_cig->[$_]} @good_i));
    }

    return @new_cigars;
}


=head2 identify_removed_columns

  Arg [1]    : Arrayref of the initial alignment strings
  Arg [2]    : Arrayref of the filtered alignment strings (in the same order)
  Example    : my $removed_columns = identify_removed_columns([$aln1, $aln2], [$fil1, $fil2]);
  Description: Compares each alignment string to its filtered version
               and compiles a list of kept / discarded columns.
               The return string is like "[0,0],[6,8]". Here, two regions
               are removed: from column 0 to 0, and from column 6 to 8.
               That string can be "eval"ed and given to Bio::SimpleAlign::remove_columns()
  Returntype : string

=cut

sub identify_removed_columns {

    my $initial_strings  = shift;
    my $filtered_strings = shift;

    #print STDERR Dumper($initial_strings, $filtered_strings);

    my $start_segment = undef;
    my @filt_segments = ();
    my $j = 0;
    my $next_filt_column = undef;

    my @seq_keys = keys %$initial_strings;
    my $ini_length = length($initial_strings->{$seq_keys[0]});
    my $filt_length = length($filtered_strings->{$seq_keys[0]});
    #print Dumper($ini_length, $filt_length, scalar(@seq_keys));

    foreach my $i (0..($ini_length-1)) {
        unless ($next_filt_column) {
            $next_filt_column = join('', map {substr($filtered_strings->{$_}, $j, 1)} @seq_keys);
        }
        my $next_ini_column = join('', map {substr($initial_strings->{$_}, $i, 1)} @seq_keys);
        #print STDERR "Comparing ini=$i:$next_ini_column to fil=$j:$next_filt_column\n";

        # Treebest also replaces segments with Ns
        my $filt_without_N = $next_filt_column;
        $filt_without_N =~ s/N/substr($next_ini_column, pos($filt_without_N), 1) ne '-' ? substr($next_ini_column, pos($filt_without_N), 1) : 'N'/eg;

        if (($next_ini_column eq $next_filt_column) or ($next_ini_column eq $filt_without_N)) {
            $j++;
            $next_filt_column = undef;
            if (defined $start_segment) {
                push @filt_segments, sprintf('[%d,%d]', $start_segment, $i-1);
                $start_segment = undef;
            }
        } else {
            if (not defined $start_segment) {
                $start_segment = $i;
            }
        }
    }
    die "Could not match alignments" if $j+1 < $filt_length;

    if (defined $start_segment) {
        push @filt_segments, sprintf('[%d,%d]', $start_segment, $ini_length-1);
    }

    return join(',', @filt_segments);
}

1;
