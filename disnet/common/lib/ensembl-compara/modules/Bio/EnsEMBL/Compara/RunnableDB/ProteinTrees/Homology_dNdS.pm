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

# POD documentation - main docs before the code

=pod 

=head1 NAME

Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::Homology_dNdS

=cut

=head1 SYNOPSIS

my $db      = Bio::EnsEMBL::Compara::DBAdaptor->new($locator);
my $repmask = Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::Homology_dNdS->new ( 
                                                    -db      => $db,
                                                    -input_id   => $input_id
                                                    -analysis   => $analysis );
$repmask->fetch_input(); #reads from DB
$repmask->run();
$repmask->write_output(); #writes to DB

=cut

=head1 CONTACT

Describe contact details here

=cut

=head1 APPENDIX

The rest of the documentation details each of the object methods. 
Internal methods are usually preceded with a _

=cut

package Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::Homology_dNdS;

use strict;
use Statistics::Descriptive;

use Bio::Tools::Run::Phylo::PAML::Codeml;

use base ('Bio::EnsEMBL::Compara::RunnableDB::BaseRunnable');


sub fetch_input {
    my $self = shift @_;

    my $mlss_id = $self->param_required('mlss_id');

    if(my $codeml_parameters_file = $self->param('codeml_parameters_file')) {
        if(-r $codeml_parameters_file) {
            $self->param('codeml_parameters', do($codeml_parameters_file) );
        } else {
            die "Cannot open '$codeml_parameters_file' file for reading";
        }
    }
    my $codeml_parameters = $self->param('codeml_parameters')
        or die "Either 'codeml_parameters' or 'codeml_parameters_file' has to be correctly defined";  # let it break immediately if no codeml_parameters

    my $min_homology_id = $self->param('min_homology_id');
    my $max_homology_id = $self->param('max_homology_id');

    my $homology_adaptor  = $self->compara_dba->get_HomologyAdaptor;
    my $constraint = sprintf('method_link_species_set_id = %d AND homology_id BETWEEN %d AND %d AND description != "gene_split"', $mlss_id, $min_homology_id, $max_homology_id);
    my $homologies = $homology_adaptor->generic_fetch($constraint);

    $self->param('homologies', $homologies);
}


sub run {
    my $self = shift @_;

    my $homologies        = $self->param('homologies');
    my $codeml_parameters = $self->param_required('codeml_parameters');

    my @updated_homologies = ();

    foreach my $homology (@$homologies) {

        next if ($homology->s or $homology->n);

        # Compute ds
        eval { $self->calc_genetic_distance($homology, $codeml_parameters); };
        $self->warning($@) if $@;
        push @updated_homologies, $homology if $homology->s or $homology->n;

        # To save memory
        $homology->clear;
    }
    $self->param('updated_homologies', \@updated_homologies);
    $self->param('homologies', []);
}


sub write_output {
    my $self = shift @_;

    my $homologies        = $self->param('updated_homologies');

    my $homology_adaptor  = $self->compara_dba->get_HomologyAdaptor;

    foreach my $homology (@$homologies) {
        $homology_adaptor->update_genetic_distance($homology);
    }
}


##########################################
#
# internal methods
#
##########################################

sub calc_genetic_distance {
  my ($self, $homology, $codeml_parameters) = @_;

  #print("use codeml to get genetic distance of homology\n");
  $homology->print_homology if ($self->debug);
  
  my $aln = $homology->get_SimpleAlign(-seq_type => 'cds');

  $self->compara_dba->dbc->disconnect_when_inactive(1);
  
  my $codeml = new Bio::Tools::Run::Phylo::PAML::Codeml();

  my $possible_exe = $self->param('codeml_exe');
  if($possible_exe) {
    print("Using executable at ${possible_exe}\n") if $self->debug;
    $codeml->executable($possible_exe);
  }

  #$codeml->save_tempfiles(1);
  while(my ($key, $value) = each %$codeml_parameters) {
     $codeml->set_parameter($key, $value);
  }
  $codeml->alignment($aln);
  if (0 != $aln->{_special_codeml_icode}) {
    $codeml->set_parameter("icode",$aln->{_special_codeml_icode})
  }
  my ($rc,$parser) = $codeml->run();
  if($rc == 0) {
    print_simple_align($aln, 80);
    print("codeml error : ", $codeml->error_string, "\n");
    if($aln->can('remove_gaps')) {
			my $collapsed_aln = $aln->remove_gaps();
			$collapsed_aln->gap_char('N'); # Ns are not used either, so default to gaps
    	if (0 == $collapsed_aln->remove_gaps()->length()) {
    		warn("Codeml : The pairwise alignment is all gapped or Ns");
      	return $homology;
    	}
    }
    warn("There was an error running codeml");
    return $homology;
  }
  my $result;
  eval{ $result = $parser->next_result };
  unless( $result ){
    #If there is an error check if it was something which is produced
    #by strange alignments (where identity/similarity is very very low)
    my $error = $@;
    if( $error ){ 
      warn( "${error}\n" );
      warn( "Parser failed" );
      if($error->isa('Bio::Root::NotImplemented')) {
        warn("Caught a NotImplemented error. Ignoring as this can be generated from bad alignments \n");
      }
      else {
        die;
      }
    }
    return $homology;
  }
  my $MLmatrix = $result->get_MLmatrix();

  if($MLmatrix->[0]->[1]->{'dS'} eq 'nan') {
      # Can happen for spectacularly bad matches, behave as per
      # Bio::Root::NotImplemented case above.
      warn "dS is NaN. Ignoring as this can be generated from bad alignments";
      return $homology;
  } 

  #print "n = ", $MLmatrix->[0]->[1]->{'N'},"\n";
  #print "s = ", $MLmatrix->[0]->[1]->{'S'},"\n";
  #print "t = ", $MLmatrix->[0]->[1]->{'t'},"\n";
  #print "lnL = ", $MLmatrix->[0]->[1]->{'lnL'},"\n";
  #print "Ka = ", $MLmatrix->[0]->[1]->{'dN'},"\n";
  #print "Ks = ", $MLmatrix->[0]->[1]->{'dS'},"\n";
  #print "Ka/Ks = ", $MLmatrix->[0]->[1]->{'omega'},"\n";

  $homology->n($MLmatrix->[0]->[1]->{'N'});
  $homology->s($MLmatrix->[0]->[1]->{'S'});
  $homology->dn($MLmatrix->[0]->[1]->{'dN'});
  $homology->ds($MLmatrix->[0]->[1]->{'dS'});
  $homology->lnl($MLmatrix->[0]->[1]->{'lnL'});

  # We check that the sequences differ to avoid the dS=0.000N0 codeml
  # problem - there is one case in the DB with dS=0.00110 that is
  # clearly a 0 because dS*S is way lower than 1
  if ( (1 > ((($homology->{_ds})*$homology->{_s})+0.1)) || (1 > ((($homology->{_dn})*$homology->{_n})+0.1)) ) {
    # Bioperl version
    eval {require Bio::Align::DNAStatistics;};
    unless ($@) {
      my $stats = new Bio::Align::DNAStatistics;
      if($stats->can('calc_KaKs_pair')) {
        my ($seq1id,$seq2id) = map { $_->display_id } $aln->each_seq;
        my $results = $stats->calc_KaKs_pair($aln, $seq1id, $seq2id);
        my $counting_method_dn = $results->[0]{D_n};
        my $counting_method_ds = $results->[0]{D_s};

        # We want to be strict in the counting of dS, because sometimes
        # the counting method gives half a (dS*S) where codeml doesn't. So
        # we only change to dS=0 when strictly 0 in the counting method
        if (0 == abs($counting_method_ds) && (1 > ((($homology->{_ds})*$homology->{_s})+0.1))) {
          $homology->ds(0);       # dS strictly 0
        }
        # Also for dN, although this happens very very rarely (seen once so far)
        if (0 == abs($counting_method_dn) && (1 > ((($homology->{_dn})*$homology->{_n})+0.1))) {
          $homology->dn(0);       # dN strictly 0
        }
      }
    }
  }

  $self->compara_dba->dbc->disconnect_when_inactive(0);

  return $homology;
}

sub print_simple_align
{
  my $alignment = shift;
  my $aaPerLine = shift;
  $aaPerLine=40 unless($aaPerLine and $aaPerLine > 0);

  my ($seq1, $seq2)  = $alignment->each_seq;
  my $seqStr1 = "|".$seq1->seq().'|';
  my $seqStr2 = "|".$seq2->seq().'|';

  my $enddiff = length($seqStr1) - length($seqStr2);
  while($enddiff>0) { $seqStr2 .= " "; $enddiff--; }
  while($enddiff<0) { $seqStr1 .= " "; $enddiff++; }

  my $label1 = sprintf("%40s : ", $seq1->id);
  my $label2 = sprintf("%40s : ", "");
  my $label3 = sprintf("%40s : ", $seq2->id);

  my $line2 = "";
  for(my $x=0; $x<length($seqStr1); $x++) {
    if(substr($seqStr1,$x,1) eq substr($seqStr2, $x,1)) { $line2.='|'; } else { $line2.=' '; }
  }

  my $offset=0;
  my $numLines = (length($seqStr1) / $aaPerLine);
  while($numLines>0) {
    printf("$label1 %s\n", substr($seqStr1,$offset,$aaPerLine));
    printf("$label2 %s\n", substr($line2,$offset,$aaPerLine));
    printf("$label3 %s\n", substr($seqStr2,$offset,$aaPerLine));
    print("\n\n");
    $offset+=$aaPerLine;
    $numLines--;
  }
}

1;

