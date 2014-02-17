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

=head1 NAME - Bio::EnsEMBL::Compara::PeptideAlignFeature

=head1 SYNOPSIS

      # Get an $homology object somehow

      # For Homology PeptideAlignFeatures, you normally get 2 pafs,
      # one for each member used alternatively as query and database
      # (hit) in the blast run

      foreach my $paf (@{$pafs}) {
        print $paf->query_member->stable_id," ",$self->hit_member->stable_id," ",$paf->evalue,"\n";
      }

      # Other stuff in the object:
      # $paf->qstart
      # $paf->qend
      # $paf->hstart
      # $paf->hend
      # $paf->score
      # $paf->alignment_length
      # $paf->identical_matches
      # $paf->perc_ident
      # $paf->positive_matches
      # $paf->perc_pos
      # $paf->hit_rank
      # $paf->cigar_line

=head1 DESCRIPTION

=head1 CONTACT

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut

my $_paf_build_homology_idx = time(); #global index counter

package Bio::EnsEMBL::Compara::PeptideAlignFeature;

use strict;
use warnings;

use Bio::EnsEMBL::Compara::Homology;
use Bio::EnsEMBL::Utils::Exception;

use Bio::EnsEMBL::Compara::Utils::Cigars;

#se overload '<=>' => "sort_by_score_evalue_and_pid";   # named method

sub new {
  my ($class) = @_;
  my $self = {};

  bless $self,$class;

  $self->query_member(new Bio::EnsEMBL::Compara::Member);
  $self->hit_member(new Bio::EnsEMBL::Compara::Member);
  return $self;
}


sub create_homology
{
  my $self = shift;

  # create an Homology object
  my $homology = new Bio::EnsEMBL::Compara::Homology;

  my $stable_id;
  if($self->query_member->taxon_id < $self->hit_member->taxon_id) {
    $stable_id = $self->query_member->taxon_id() . "_" . $self->hit_member->taxon_id . "_";
  } else {
    $stable_id = $self->hit_member->taxon_id . "_" . $self->query_member->taxon_id . "_";
  }
  $stable_id .= sprintf ("%011.0d",$_paf_build_homology_idx++);
  $homology->stable_id($stable_id);

  my $cigar_line = $self->cigar_line;
  $cigar_line =~ s/I/M/g;
  $cigar_line = Bio::EnsEMBL::Compara::Utils::Cigars::collapse_cigar(Bio::EnsEMBL::Compara::Utils::Cigars::expand_cigar($cigar_line));
  $self->query_member->cigar_line($cigar_line);

  $cigar_line = $self->cigar_line;
  $cigar_line =~ s/D/M/g;
  $cigar_line =~ s/I/D/g;
  $cigar_line = Bio::EnsEMBL::Compara::Utils::Cigars::collapse_cigar(Bio::EnsEMBL::Compara::Utils::Cigars::expand_cigar($cigar_line));
  $self->hit_member->cigar_line($cigar_line);

  $homology->add_Member($self->query_member);
  $homology->add_Member($self->hit_member);
  $homology->update_alignment_stats;

  return $homology;
}




##########################
#
# getter/setter methods
#
##########################

sub query_member {
  my ($self,$arg) = @_;

  if (defined($arg)) {
    throw("arg must be a [Bio::EnsEMBL::Compara::Member] not a [$arg]")
        unless($arg->isa('Bio::EnsEMBL::Compara::Member'));
    $self->{'_query_member'} = $arg;
  }
  return $self->{'_query_member'};
}

sub query_member_id {
  my $self = shift;
  $self->{'_query_member_id'} = shift if (@_);
  if ($self->{'_query_member_id'}) {
    return $self->{'_query_member_id'};
  } elsif ($self->{'_query_member'} and $self->{'_query_member'}->dbID) {
    return $self->{'_query_member'}->dbID;
  }
  return undef;
}

sub query_genome_db_id {
  my $self = shift;
  $self->{'_query_genome_db_id'} = shift if (@_);
  if ($self->{'_query_genome_db_id'}) {
    return $self->{'_query_genome_db_id'};
  } elsif ($self->{'_query_member'} and $self->{'_query_member'}->genome_db
      and $self->{'_query_member'}->genome_db->dbID) {
    return $self->{'_query_member'}->genome_db->dbID;
  }
  return undef;
}

sub hit_member {
  my ($self,$arg) = @_;

  if (defined($arg)) {
    throw("arg must be a [Bio::EnsEMBL::Compara::Member] not a [$arg]")
        unless($arg->isa('Bio::EnsEMBL::Compara::Member'));
    $self->{'_hit_member'} = $arg;
  }
  return $self->{'_hit_member'};
}

sub hit_member_id {
  my $self = shift;
  $self->{'_hit_member_id'} = shift if (@_);
  if ($self->{'_hit_member_id'}) {
    return $self->{'_hit_member_id'};
  } elsif ($self->{'_hit_member'} and $self->{'_hit_member'}->dbID) {
    return $self->{'_hit_member'}->dbID;
  }
  return undef;
}

sub hit_genome_db_id {
  my $self = shift;
  $self->{'_hit_genome_db_id'} = shift if (@_);
  if ($self->{'_hit_genome_db_id'}) {
    return $self->{'_hit_genome_db_id'};
  } elsif ($self->{'_hit_member'} and $self->{'_hit_member'}->genome_db
      and $self->{'_hit_member'}->genome_db->dbID) {
    return $self->{'_hit_member'}->genome_db->dbID;
  }
  return undef;
}

sub  qstart {
  my ($self,$arg) = @_;

  if (defined($arg)) {
    $self->{_qstart} = $arg;
  }
  return $self->{_qstart};
}

sub  hstart {
  my ($self,$arg) = @_;

  if (defined($arg)) {
    $self->{_hstart} = $arg;
  }
  return $self->{_hstart};
}

sub  qend {
  my ($self,$arg) = @_;

  if (defined($arg)) {
    $self->{_qend} = $arg;
  }
  return $self->{_qend};
}

sub  qlength {
  my ($self,$arg) = @_;

  if (defined($arg)) {
    $self->{_qlength} = $arg;
  }
  return $self->{_qlength};
}

sub  hend {
  my ($self,$arg) = @_;

  if (defined($arg)) {
    $self->{_hend} = $arg;
  }
  return $self->{_hend};
}

sub  hlength{
  my ($self,$arg) = @_;

  if (defined($arg)) {
    $self->{_hlength} = $arg;
  }
  return $self->{_hlength};
}

sub score{
  my ($self,$arg) = @_;

  if (defined($arg)) {
    $self->{_score} = $arg;
  }
  return $self->{_score};
}

sub evalue {
  my ($self,$arg) = @_;

  if (defined($arg)) {
    $self->{_evalue} = $arg;
  }
  return $self->{_evalue};
}

sub perc_ident {
  my ($self,$arg) = @_;

  if (defined($arg)) {
    $self->{_perc_ident} = $arg;
  }
  return $self->{_perc_ident};
}

sub perc_pos {
  my ($self,$arg) = @_;

  if (defined($arg)) {
    $self->{_perc_pos} = $arg;
  }
  return $self->{_perc_pos};
}

sub identical_matches {
  my ($self,$arg) = @_;

  if (defined($arg)) {
    $self->{_identical_matches} = $arg;
    if(defined($self->alignment_length)) {
      $self->perc_ident(int($arg*100/$self->alignment_length));
    }
  }
  return $self->{_identical_matches};
}

sub positive_matches {
  my ($self,$arg) = @_;

  if (defined($arg)) {
    $self->{_positive_matches} = $arg;
    if(defined($self->alignment_length)) {
      $self->perc_pos(int($arg*100/$self->alignment_length));
    }
  }
  return $self->{_positive_matches};
}

sub alignment_length {
  my ($self,$arg) = @_;

  if (defined($arg)) {
    $self->{_alignment_length} = $arg;
  }
  return $self->{_alignment_length};
}

sub cigar_line {
  my ($self,$arg) = @_;

  if (defined($arg)) {
    $self->{_cigar_line} = $arg;
  }
  return $self->{_cigar_line};
}

sub hit_rank {
  my ($self,$arg) = @_;

  if (defined($arg)) {
    $self->{_hit_rank} = $arg;
  }
  return $self->{_hit_rank};
}

sub dbID {
  my ( $self, $dbID ) = @_;
  $self->{'_dbID'} = $dbID if defined $dbID;
  return $self->{'_dbID'};
}

sub rhit_dbID {
  my ( $self, $dbID ) = @_;
  $self->{'_rhit_dbID'} = $dbID if defined $dbID;
  return $self->{'_rhit_dbID'};
}

sub display_short {
  my $self = shift;
  print($self->get_description(), "\n");
}

sub get_description {
  my($self) = @_;

  unless(defined($self)) {
    print("qy_stable_id\t\t\thit_stable_id\t\t\tscore\talen\t\%ident\t\%positive\thit_rank\n");
    return;
  }

  my $qm = $self->query_member;
  my $hm = $self->hit_member;
  my $dbID = $self->dbID;  $dbID = '' unless($dbID);

  my $header = "PAF(".$dbID.")";
  $header .= "(".$self->rhit_dbID.")" if($self->rhit_dbID);
  while(length($header)<17) { $header .= ' '; }

  my $qmem = sprintf("%s(%d,%d)(%s:%d)",
        $qm->stable_id, $self->qstart, $self->qend, $qm->chr_name, $qm->dnafrag_start);
  my $hmem = sprintf("%s(%d,%d)(%s:%d)",
        $hm->stable_id, $self->hstart, $self->hend, $hm->chr_name, $hm->dnafrag_start);
  while(length($qmem)<50) { $qmem .= ' '; }
  while(length($hmem)<50) { $hmem .= ' '; }


  my $desc_string = sprintf("%s%s%s%7.3f%7d%7d%7d%7d",
        $header, $qmem, $hmem,
        $self->score,
        $self->alignment_length,
        $self->perc_ident,
        $self->perc_pos,
        $self->hit_rank);

  return $desc_string;
}


=head2 hash_key
  Args       : none
  Example    : $somehash->{$paf->hash_key} = $someValue;
  Description: used for keeping track of known/stored gene/gene relationships
  Returntype : string $key
  Exceptions : none
  Caller     : general
=cut

sub hash_key
{
  my $self = shift;
  my $key = '1';

  return $key unless($self->query_member);
  return $key unless($self->hit_member);
  my $gene1 = $self->query_member->gene_member;
  my $gene2 = $self->hit_member->gene_member;
  $gene1 = $self->query_member unless($gene1);
  $gene2 = $self->hit_member unless($gene2);
  if($gene1->genome_db_id > $gene2->genome_db_id) {
    my $temp = $gene1;
    $gene1 = $gene2;
    $gene2 = $temp;
  }
  $key = $gene1->stable_id . '_' . $gene2->stable_id;
  return $key;
}

1;
