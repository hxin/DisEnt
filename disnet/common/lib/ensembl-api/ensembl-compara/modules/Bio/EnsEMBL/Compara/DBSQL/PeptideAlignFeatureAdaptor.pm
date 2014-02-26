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

=head1 NAME

  Bio::EnsEMBL::Compara::DBSQL::PeptideAlignFeatureAdaptor

=head1 SYNOPSIS

  $peptideAlignFeatureAdaptor = $db_adaptor->get_PeptideAlignFeatureAdaptor;
  $peptideAlignFeatureAdaptor = $peptideAlignFeatureObj->adaptor;

=head1 DESCRIPTION

  Module to encapsulate all db access for persistent class PeptideAlignFeature
  There should be just one per application and database connection.

=head1 CONTACT

  Contact Jessica Severin on implementation/design detail: jessica@ebi.ac.uk
  Contact Albert Vilella on implementation/design detail: avilella@ebi.ac.uk
  Contact Ewan Birney on EnsEMBL in general: birney@sanger.ac.uk

=cut

use strict;
use warnings;

package Bio::EnsEMBL::Compara::DBSQL::PeptideAlignFeatureAdaptor;


use Bio::EnsEMBL::Compara::PeptideAlignFeature;
use Bio::EnsEMBL::Utils::Exception;

use vars '@ISA';

use base ('Bio::EnsEMBL::Compara::DBSQL::BaseAdaptor');

#############################
#
# fetch methods
#
#############################


=head2 fetch_all_by_qmember_id

  Arg [1]    : int $member->dbID
               the database id for a peptide member
  Example    : $pafs = $adaptor->fetch_all_by_qmember_id($member->dbID);
  Description: Returns all PeptideAlignFeatures from all target species
               where the query peptide member is know.
  Returntype : array reference of Bio::EnsEMBL::Compara::PeptideAlignFeature objects
  Exceptions : thrown if $id is not defined
  Caller     : general

=cut

sub fetch_all_by_qmember_id{
  my $self = shift;
  my $member_id = shift;

  throw("member_id undefined") unless($member_id);

  my $member = $self->db->get_SeqMemberAdaptor->fetch_by_dbID($member_id);
  $self->{_curr_gdb_id} = $member->genome_db_id;

  my $constraint = "paf.qmember_id = $member_id";
  return $self->generic_fetch($constraint);
}


=head2 fetch_all_by_hmember_id

  Arg [1]    : int $member->dbID
               the database id for a peptide member
  Example    : $pafs = $adaptor->fetch_all_by_hmember_id($member->dbID);
  Description: Returns all PeptideAlignFeatures from all query species
               where the hit peptide member is know.
  Returntype : array reference of Bio::EnsEMBL::Compara::PeptideAlignFeature objects
  Exceptions : thrown if $id is not defined
  Caller     : general

=cut

sub fetch_all_by_hmember_id{
  my $self = shift;
  my $member_id = shift;

  throw("member_id undefined") unless($member_id);

  my @pafs;
  foreach my $genome_db_id ($self->_get_all_genome_db_ids) {
    push @pafs, @{$self->fetch_all_by_hmember_id_qgenome_db_id($member_id, $genome_db_id)};
  }
  return \@pafs;
}


=head2 fetch_all_by_qmember_id_hmember_id

  Arg [1]    : int $query_member->dbID
               the database id for a peptide member
  Arg [2]    : int $hit_member->dbID
               the database id for a peptide member
  Example    : $pafs = $adaptor->fetch_all_by_qmember_id_hmember_id($qmember_id, $hmember_id);
  Description: Returns all PeptideAlignFeatures for a given query member and
               hit member.  If pair did not align, array will be empty.
  Returntype : array reference of Bio::EnsEMBL::Compara::PeptideAlignFeature objects
  Exceptions : thrown if either member_id is not defined
  Caller     : general

=cut

sub fetch_all_by_qmember_id_hmember_id{
  my $self = shift;
  my $qmember_id = shift;
  my $hmember_id = shift;

  throw("must specify query member dbID") unless($qmember_id);
  throw("must specify hit member dbID") unless($hmember_id);

  my $qmember = $self->db->get_SeqMemberAdaptor->fetch_by_dbID($qmember_id);
  $self->{_curr_gdb_id} = $qmember->genome_db_id;

  my $constraint = "paf.qmember_id=$qmember_id AND paf.hmember_id=$hmember_id";
  return $self->generic_fetch($constraint);
}


=head2 fetch_all_by_qmember_id_hgenome_db_id

  Arg [1]    : int $query_member->dbID
               the database id for a peptide member
  Arg [2]    : int $hit_genome_db->dbID
               the database id for a genome_db
  Example    : $pafs = $adaptor->fetch_all_by_qmember_id_hgenome_db_id(
                    $member->dbID, $genome_db->dbID);
  Description: Returns all PeptideAlignFeatures for a given query member and
               target hit species specified via a genome_db_id
  Returntype : array reference of Bio::EnsEMBL::Compara::PeptideAlignFeature objects
  Exceptions : thrown if either member->dbID or genome_db->dbID is not defined
  Caller     : general

=cut

sub fetch_all_by_qmember_id_hgenome_db_id{
  my $self = shift;
  my $qmember_id = shift;
  my $hgenome_db_id = shift;

  throw("must specify query member dbID") unless($qmember_id);
  throw("must specify hit genome_db dbID") unless($hgenome_db_id);

  my $qmember = $self->db->get_SeqMemberAdaptor->fetch_by_dbID($qmember_id);
  $self->{_curr_gdb_id} = $qmember->genome_db_id;

  my $constraint = "paf.qmember_id=$qmember_id AND paf.hgenome_db_id=$hgenome_db_id";
  return $self->generic_fetch($constraint);
}


=head2 fetch_all_by_hmember_id_qgenome_db_id

  Arg [1]    : int $hit_member->dbID
               the database id for a peptide member
  Arg [2]    : int $query_genome_db->dbID
               the database id for a genome_db
  Example    : $pafs = $adaptor->fetch_all_by_hmember_id_qgenome_db_id(
                    $member->dbID, $genome_db->dbID);
  Description: Returns all PeptideAlignFeatures for a given hit member and
               query species specified via a genome_db_id
  Returntype : array reference of Bio::EnsEMBL::Compara::PeptideAlignFeature objects
  Exceptions : thrown if either member->dbID or genome_db->dbID is not defined
  Caller     : general

=cut

sub fetch_all_by_hmember_id_qgenome_db_id{
   my $self = shift;
   my $hmember_id = shift;
   my $qgenome_db_id = shift;

   throw("must specify hit member dbID") unless($hmember_id);
   throw("must specify query genome_db dbID") unless($qgenome_db_id);

   $self->{_curr_gdb_id} = $qgenome_db_id;
   # we don't need to add "paf.qgenome_db_id=$qgenome_db_id" because it is implicit from the table name
   my $constraint = "paf.hmember_id=$hmember_id";
}


sub fetch_all_by_hgenome_db_id{
  my $self = shift;
  my $hgenome_db_id = shift;

  throw("must specify hit genome_db dbID") unless($hgenome_db_id);

  my @pafs;
  foreach my $genome_db_id ($self->_get_all_genome_db_ids) {
    push @pafs, @{$self->fetch_all_by_qgenome_db_id_hgenome_db_id($genome_db_id, $hgenome_db_id)};
  }
  return \@pafs;
}


sub fetch_all_by_qgenome_db_id{
  my $self = shift;
  my $qgenome_db_id = shift;

  throw("must specify query genome_db dbID") unless($qgenome_db_id);

  $self->{_curr_gdb_id} = $qgenome_db_id;
  return $self->generic_fetch();
}


sub fetch_all_by_qgenome_db_id_hgenome_db_id{
  my $self = shift;
  my $qgenome_db_id = shift;
  my $hgenome_db_id = shift;

  throw("must specify query genome_db dbID") unless($qgenome_db_id);
  throw("must specify hit genome_db dbID") unless($hgenome_db_id);

  $self->{_curr_gdb_id} = $qgenome_db_id;

  my $constraint = "paf.hgenome_db_id = $hgenome_db_id";
  return $self->generic_fetch($constraint);
}


sub fetch_all_besthit_by_qgenome_db_id{
  my $self = shift;
  my $qgenome_db_id = shift;

  throw("must specify query genome_db dbID") unless($qgenome_db_id);

  $self->{_curr_gdb_id} = $qgenome_db_id;

  my $constraint = "paf.hit_rank=1";
  return $self->generic_fetch($constraint);
}


sub fetch_all_besthit_by_qgenome_db_id_hgenome_db_id{
  my $self = shift;
  my $qgenome_db_id = shift;
  my $hgenome_db_id = shift;

  throw("must specify query genome_db dbID") unless($qgenome_db_id);
  throw("must specify hit genome_db dbID") unless($hgenome_db_id);

  $self->{_curr_gdb_id} = $qgenome_db_id;

  my $constraint = "paf.hgenome_db_id = $hgenome_db_id AND paf.hit_rank=1";
  return $self->generic_fetch($constraint);
}


=head2 fetch_selfhit_by_qmember_id

  Arg [1]    : int $member->dbID
               the database id for a peptide member
  Example    : $paf = $adaptor->fetch_selfhit_by_qmember_id($member->dbID);
  Description: Returns the selfhit PeptideAlignFeature defined by the id $id.
  Returntype : Bio::EnsEMBL::Compara::PeptideAlignFeature
  Exceptions : thrown if $id is not defined
  Caller     : general

=cut


sub fetch_selfhit_by_qmember_id {
  my $self= shift;
  my $qmember_id = shift;

  throw("qmember_id undefined") unless($qmember_id);

  my $member = $self->db->get_SeqMemberAdaptor->fetch_by_dbID($qmember_id);

  $self->{_curr_gdb_id} = $member->genome_db_id;
  my $constraint = "qmember_id=$qmember_id AND qmember_id=hmember_id";
  return $self->generic_fetch_one($constraint);
}



#############################
#
# store methods
#
#############################

sub store {
  my ($self, @features)  = @_;

  my @pafList = ();

  foreach my $feature (@features) {
    if($feature->isa('Bio::EnsEMBL::BaseAlignFeature')) {
      #displayHSP_short($feature);
      my $pepFeature = $self->_create_PAF_from_BaseAlignFeature($feature);
      #$pepFeature->display_short();
      push @pafList, $pepFeature;
    }
    elsif($feature->isa('Bio::EnsEMBL::Compara::PeptideAlignFeature')) {
      push @pafList, $feature;
    }
  }

  @pafList = sort sort_by_score_evalue_and_pid @pafList;
  my $rank=1;
  my $prevPaf = undef;
  foreach my $paf (@pafList) {
    $rank++ if($prevPaf and !pafs_equal($prevPaf, $paf));
    $paf->hit_rank($rank);
    $prevPaf = $paf;
  }

  $self->_store_PAFS(@pafList);
}


sub _store_PAFS {
  my ($self, @out)  = @_;

  return unless(@out and scalar(@out));

  # Query genome db id should always be the same
  my $first_qgenome_db_id = $out[0]->query_genome_db_id;

  my $gdb = $self->db->get_GenomeDBAdaptor->fetch_by_dbID($first_qgenome_db_id);
  my $tbl_name = 'peptide_align_feature_'.$first_qgenome_db_id;

  my $query = "INSERT INTO $tbl_name(".
                "qmember_id,hmember_id,qgenome_db_id,hgenome_db_id," .
                "qstart,qend,hstart,hend,".
                "score,evalue,align_length," .
                "identical_matches,perc_ident,".
                "positive_matches,perc_pos,hit_rank,cigar_line) VALUES ";

  my $addComma=0;
  foreach my $paf (@out) {
    if($paf->isa('Bio::EnsEMBL::Compara::PeptideAlignFeature')) {

      # print STDERR "== ", $paf->query_member_id, " - ", $paf->hit_member_id, "\n";
      my $qgenome_db_id = $paf->query_genome_db_id;
      $qgenome_db_id = 0 unless($qgenome_db_id);
      my $hgenome_db_id = $paf->hit_genome_db_id;
      $hgenome_db_id = 0 unless($hgenome_db_id);
#      eval {$paf->query_member->source_name eq 'ENSEMBLPEP';};
			eval {$paf->query_member->source_name};
      if ($@) { throw("Not an ENSEMBLPEP\n"); }
      # Null_cigar option for leaner paf tables
      $paf->cigar_line('') if (defined $paf->{null_cigar});

      $query .= ", " if($addComma);
      $query .= "(".$paf->query_member_id.
                ",".$paf->hit_member_id.
                ",".$qgenome_db_id.
                ",".$hgenome_db_id.
                ",".$paf->qstart.
                ",".$paf->qend.
                ",".$paf->hstart.
                ",".$paf->hend.
                ",".$paf->score.
                ",".$paf->evalue.
                ",".$paf->alignment_length.
                ",".$paf->identical_matches.
                ",".$paf->perc_ident.
                ",".$paf->positive_matches.
                ",".$paf->perc_pos.
                ",".$paf->hit_rank.
                ",'".$paf->cigar_line."')";
      $addComma=1;
      # $paf->display_short();
    }
  }
  #print("$query\n");
  my $sth = $self->prepare($query);
  $sth->execute();
  $sth->finish();
}


sub _create_PAF_from_BaseAlignFeature {
  my($self, $feature) = @_;

  unless(defined($feature) and $feature->isa('Bio::EnsEMBL::BaseAlignFeature')) {
    throw("arg must be a [Bio::EnsEMBL::BaseAlignFeature] not a [$feature]");
  }

  my $paf = new Bio::EnsEMBL::Compara::PeptideAlignFeature;

  my $memberDBA = $self->db->get_SeqMemberAdaptor();

  if ($feature->seqname =~ /IDs\:(\d+)\:(\d+)/) {
    my $query_member = $memberDBA->fetch_by_dbID($2);
#    eval {$query_member->source_name eq 'ENSEMBLPEP'};
		eval {$query_member->source_name};
    if ($@) { throw("$1 is not an ENSEMBLPEP\n"); }
    $paf->query_genome_db_id($1);
    $paf->query_member_id($2);
  } elsif($feature->seqname =~ /member_id_(\d+)/) {
    #printf("qseq: member_id = %d\n", $1);
    my $query_member = $memberDBA->fetch_by_dbID($1);
#    eval {$query_member->source_name eq 'ENSEMBLPEP'};
		eval {$query_member->source_name};
    if ($@) { throw("$1 is not an ENSEMBLPEP\n"); }
    $paf->query_member($query_member);
  } else {
    my ($source_name, @stable_id_array) = split(/:/, $feature->seqname);
    my $stable_id = join(':', @stable_id_array);
    #printf("qseq: %s %s\n", $source_name, $stable_id);
    $paf->query_member($memberDBA->fetch_by_source_stable_id($source_name, $stable_id));
  }

  if ($feature->hseqname =~ /IDs\:(\d+)\:(\d+)/) {
    $paf->hit_genome_db_id($1);
    $paf->hit_member_id($2);
  } elsif ($feature->hseqname =~ /member_id_(\d+)/) {
    #printf("hseq: member_id = %d\n", $1);
    $paf->hit_member($memberDBA->fetch_by_dbID($1));
  } else {
    my ($source_name, @stable_id_array) = split(/:/, $feature->hseqname);
    my $stable_id = join(':', @stable_id_array);
    #printf("hseq: %s %s\n", $source_name, $stable_id);
    my $hit_member = $memberDBA->fetch_by_source_stable_id($source_name, $stable_id);
    if (defined($hit_member)) {
      $paf->hit_member($hit_member);
    } else {
      throw "couldnt find $stable_id\n";
    }
  }

  $paf->qstart($feature->start);
  $paf->hstart($feature->hstart);
  $paf->qend($feature->end);
  $paf->hend($feature->hend);
  #$paf->qlength($qlength);
  #$paf->hlength($hlength);
  $paf->score($feature->score);
  $paf->evalue($feature->p_value);

  $paf->cigar_line($feature->cigar_string);
  $paf->{null_cigar} = 1 if (defined $feature->{null_cigar});

  $paf->alignment_length($feature->alignment_length);
  $paf->identical_matches($feature->identical_matches);
  $paf->positive_matches($feature->positive_matches);

  $paf->perc_ident(int($feature->identical_matches*100/$feature->alignment_length));
  $paf->perc_pos(int($feature->positive_matches*100/$feature->alignment_length));
  return $paf;
}


sub sort_by_score_evalue_and_pid {
  $b->score <=> $a->score ||
    $a->evalue <=> $b->evalue ||
      $b->perc_ident <=> $a->perc_ident ||
        $b->perc_pos <=> $a->perc_pos;
}


sub pafs_equal {
  my ($paf1, $paf2) = @_;
  return 0 unless($paf1 and $paf2);
  return 1 if(($paf1->score == $paf2->score) and
              ($paf1->evalue == $paf2->evalue) and
              ($paf1->perc_ident == $paf2->perc_ident) and
              ($paf1->perc_pos == $paf2->perc_pos));
  return 0;
}


sub displayHSP {
  my($paf) = @_;

  my $percent_ident = int($paf->identical_matches*100/$paf->alignment_length);
  my $pos = int($paf->positive_matches*100/$paf->alignment_length);

  print("=> $paf\n");
  print("pep_align_feature :\n" .
    " seqname           : " . $paf->seqname . "\n" .
    " start             : " . $paf->start . "\n" .
    " end               : " . $paf->end . "\n" .
    " hseqname          : " . $paf->hseqname . "\n" .
    " hstart            : " . $paf->hstart . "\n" .
    " hend              : " . $paf->hend . "\n" .
    " score             : " . $paf->score . "\n" .
    " p_value           : " . $paf->p_value . "\n" .
    " alignment_length  : " . $paf->alignment_length . "\n" .
    " identical_matches : " . $paf->identical_matches . "\n" .
    " perc_ident        : " . $percent_ident . "\n" .
    " positive_matches  : " . $paf->positive_matches . "\n" .
    " perc_pos          : " . $pos . "\n" .
    " cigar_line        : " . $paf->cigar_string . "\n");
}

sub displayHSP_short {
  my($paf) = @_;

  unless(defined($paf)) {
    print("qy_stable_id\t\t\thit_stable_id\t\t\tscore\talen\t\%ident\t\%positive\n");
    return;
  }
  
  my $perc_ident = int($paf->identical_matches*100/$paf->alignment_length);
  my $perc_pos = int($paf->positive_matches*100/$paf->alignment_length);

  print("HSP ".$paf->seqname."(".$paf->start.",".$paf->end.")".
        "\t" . $paf->hseqname. "(".$paf->hstart.",".$paf->hend.")".
        "\t" . $paf->score .
        "\t" . $paf->alignment_length .
        "\t" . $perc_ident . 
        "\t" . $perc_pos . "\n");
}



############################
#
# INTERNAL METHODS
# (pseudo subclass methods)
#
############################

#internal method used in multiple calls above to build objects from table data

sub _tables {
  my $self = shift;

  return (['peptide_align_feature_'.$self->{_curr_gdb_id}, 'paf'] );
}

sub _columns {
  my $self = shift;

  return qw (paf.peptide_align_feature_id
             paf.qmember_id
             paf.hmember_id
             paf.qstart
             paf.qend
             paf.hstart
             paf.hend
             paf.score
             paf.evalue
             paf.align_length
             paf.identical_matches
             paf.perc_ident
             paf.positive_matches
             paf.perc_pos
             paf.hit_rank
             paf.cigar_line
            );
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my %column;
  $sth->bind_columns( \( @column{ @{$sth->{NAME_lc} } } ));

  my @pafs = ();

  while ($sth->fetch()) {
    my $paf;

    $paf = Bio::EnsEMBL::Compara::PeptideAlignFeature->new();

    $paf->dbID($column{'peptide_align_feature_id'});
    $paf->qstart($column{'qstart'});
    $paf->qend($column{'qend'});
    $paf->hstart($column{'hstart'});
    $paf->hend($column{'hend'});
    $paf->score($column{'score'});
    $paf->evalue($column{'evalue'});
    $paf->alignment_length($column{'align_length'});
    $paf->identical_matches($column{'identical_matches'});
    $paf->perc_ident($column{'perc_ident'});
    $paf->positive_matches($column{'positive_matches'});
    $paf->perc_pos($column{'perc_pos'});
    $paf->hit_rank($column{'hit_rank'});
    $paf->cigar_line($column{'cigar_line'});
    $paf->rhit_dbID($column{'pafid2'});

    my $memberDBA = $self->db->get_SeqMemberAdaptor;
    if($column{'qmember_id'} and $memberDBA) {
      $paf->query_member($memberDBA->fetch_by_dbID($column{'qmember_id'}));
    }
    if($column{'hmember_id'} and $memberDBA) {
      $paf->hit_member($memberDBA->fetch_by_dbID($column{'hmember_id'}));
    }
  
    #$paf->display_short();
    
    push @pafs, $paf;

  }
  $sth->finish;

  return \@pafs;
}


sub _get_all_genome_db_ids {
    my $self = shift;

    return $self->db->get_GenomeDBAdaptor->_id_cache->cache_keys;
}

###############################################################################
#
# General access methods that could be moved
# into a superclass
#
###############################################################################


#sub fetch_by_dbID_qgenome_db_id {


=head2 fetch_by_dbID

  Arg [1]    : int $id
               the unique database identifier for the feature to be obtained
  Example    : $paf = $adaptor->fetch_by_dbID(1234);
  Description: Returns the PeptideAlignFeature created from the database defined by the
               the id $id.
  Returntype : Bio::EnsEMBL::Compara::PeptideAlignFeature
  Exceptions : thrown if $id is not defined
  Caller     : general

=cut

sub fetch_by_dbID{
  my ($self,$id) = @_;

  unless(defined $id) {
    throw("fetch_by_dbID must have an id");
  }

  $self->{_curr_gdb_id} = int($id/100000000);

  my $constraint = "peptide_align_feature_id=$id";
  return $self->generic_fetch_one($constraint);
}


=head2 fetch_all_by_dbID_list

  Arg [1]    : array ref $id_list_ref
               the unique database identifier for the feature to be obtained
  Example    : $pafs = $adaptor->fetch_by_dbID( [paf1_id, $paf2_id, $paf3_id] );
  Description: Returns the PeptideAlignFeature created from the database defined by the
               the id $id.
  Returntype : array reference of Bio::EnsEMBL::Compara::PeptideAlignFeature objects
  Exceptions : thrown if $id is not defined
  Caller     : general

=cut

sub fetch_all_by_dbID_list {
  my $self = shift;
  my $id_list_ref = shift;

  return [map {$self->fetch_by_dbID($_)} @$id_list_ref];
}


=head2 fetch_BRH_by_member_genomedb

  Arg [1]    : member_id of query peptide member
  Arg [2]    : genome_db_id of hit species
  Example    : $paf = $adaptor->fetch_BRH_by_member_genomedb(31957, 3);
  Description: Returns the PeptideAlignFeature created from the database
               This is the old algorithm for pulling BRHs (compara release 20-23)
  Returntype : array reference of Bio::EnsEMBL::Compara::PeptideAlignFeature objects
  Exceptions : none
  Caller     : general

=cut


sub fetch_BRH_by_member_genomedb
{
  # using trick of specifying table twice so can join to self
  my $self             = shift;
  my $qmember_id       = shift;
  my $hit_genome_db_id = shift;

  #print(STDERR "fetch_all_RH_by_member_genomedb qmember_id=$qmember_id, genome_db_id=$hit_genome_db_id\n");
  return unless($qmember_id and $hit_genome_db_id);

  my $member = $self->db->get_SeqMemberAdaptor->fetch_by_dbID($qmember_id);

  $self->{_curr_gdb_id} = $member->genome_db_id;

   my $extrajoin = [
                     [ ['peptide_align_feature_'.$hit_genome_db_id, 'paf2'],
                       'paf.qmember_id=paf2.hmember_id AND paf.hmember_id=paf2.qmember_id',
                       ['paf2.peptide_align_feature_id AS pafid2']]
                   ];

   my $constraint = "paf.hit_rank=1 AND paf2.hit_rank=1 AND paf.qmember_id=$qmember_id AND paf.hgenome_db_id=$hit_genome_db_id";

  return $self->generic_fetch_one($constraint, $extrajoin);
}


=head2 fetch_all_RH_by_member_genomedb

  Overview   : This an experimental method and not currently used in production
  Arg [1]    : member_id of query peptide member
  Arg [2]    : genome_db_id of hit species
  Example    : $feat = $adaptor->fetch_by_dbID($musBlastAnal, $ratBlastAnal);
  Description: Returns all the PeptideAlignFeatures that reciprocal hit the qmember_id
               onto the hit_genome_db_id
  Returntype : array of Bio::EnsEMBL::Compara::PeptideAlignFeature objects by reference
  Exceptions : thrown if $id is not defined
  Caller     : general

=cut

sub fetch_all_RH_by_member_genomedb
{
  # using trick of specifying table twice so can join to self
  my $self             = shift;
  my $qmember_id       = shift;
  my $hit_genome_db_id = shift;

  #print(STDERR "fetch_all_RH_by_member_genomedb qmember_id=$qmember_id, genome_db_id=$hit_genome_db_id\n");
  return unless($qmember_id and $hit_genome_db_id);

  my $member = $self->db->get_SeqMemberAdaptor->fetch_by_dbID($qmember_id);

  $self->{_curr_gdb_id} = $member->genome_db_id;

   my $extrajoin = [
                     [ ['peptide_align_feature_'.$hit_genome_db_id, 'paf2'],
                       'paf.qmember_id=paf2.hmember_id AND paf.hmember_id=paf2.qmember_id',
                       ['paf2.peptide_align_feature_id AS pafid2']]
                   ];

   my $constraint = "paf.qmember_id=$qmember_id AND paf.hgenome_db_id=$hit_genome_db_id";
   my $final_clause = "ORDER BY paf.hit_rank";

  return $self->generic_fetch($constraint, $extrajoin, $final_clause);

}


=head2 fetch_all_RH_by_member

  Overview   : This an experimental method and not currently used in production
  Arg [1]    : member_id of query peptide member
  Example    : $feat = $adaptor->fetch_by_dbID($musBlastAnal, $ratBlastAnal);
  Description: Returns all the PeptideAlignFeatures that reciprocal hit all genomes
  Returntype : array of Bio::EnsEMBL::Compara::PeptideAlignFeature objects by reference
  Exceptions : thrown if $id is not defined
  Caller     : general

=cut

sub fetch_all_RH_by_member
{
  # using trick of specifying table twice so can join to self
  my $self             = shift;
  my $qmember_id       = shift;

  my @pafs;
  foreach my $genome_db_id ($self->_get_all_genome_db_ids) {
    push @pafs, @{$self->fetch_all_RH_by_member_genomedb($qmember_id, $genome_db_id)};
  }
  return \@pafs;
}


1;
