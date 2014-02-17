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


=pod 

=head1 NAME

  Bio::EnsEMBL::Compara::PipeConfig::Example::VegaProteinTrees_conf

=head1 SYNOPSIS

    #1. update ensembl-hive, ensembl and ensembl-compara CVS repositories before each new release

    #2. you may need to update 'schema_version' in meta table to the current release number in ensembl-hive/sql/tables.sql

    #3. make sure that all default_options are set correctly

    #4. Run init_pipeline.pl script:
        init_pipeline.pl Bio::EnsEMBL::Compara::PipeConfig::Example::VegaProteinTrees_conf -password <your_password> -mlss_id <your_current_PT_mlss_id>

    #5. Sync and loop the beekeeper.pl as shown in init_pipeline.pl's output


=head1 DESCRIPTION  

  The PipeConfig example file for Vega group's version of ProteinTrees pipeline

=head1 CONTACT

  Please contact Compara or Vega with questions/suggestions

=cut

package Bio::EnsEMBL::Compara::PipeConfig::Example::VegaProteinTrees_conf;

use strict;
use warnings;
use base ('Bio::EnsEMBL::Compara::PipeConfig::Example::EnsemblProteinTrees_conf');

use Storable qw(dclone);

sub resource_classes {
  my ($self) = @_;
  return {
    %{$self->SUPER::resource_classes},
    'urgent_hcluster'   => {'LSF' => '-C0 -M1000 -R"select[mem>1000] rusage[mem=1000]" -q yesterday' },
    '4Gb_job'          => { 'LSF' => '-C0 -M4000  -R"select[mem>4000]  rusage[mem=4000]"' },
  };
}


# each run you will need to edit and uncomment: version, mlss_id, (release) and maybe work_dir
sub default_options {
  my ($self) = @_;

  return {
    %{$self->SUPER::default_options},
    # inherit the generic ones

    # parameters that are likely to change from execution to another:
    'mlss_id'               => '100032',   # equivalent to mlss_id for PROTEIN_TREES in the db (commented out to make it obligatory to specify)
#    'release'               => '73',

    'pipeline_name'         => 'vega_genetree_20130211_71_step3', #edit this each time

    'rel_suffix'            => 'vega',
    'work_dir'              => '/lustre/scratch109/ensembl/'.$ENV{'USER'}.'/compara_generation/'.$self->o('pipeline_name'),
    'outgroups'             => { },   # affects 'hcluster_dump_input_per_genome'
    'taxlevels'             => [ 'Theria' ],
    'filter_high_coverage'  => 1,   # affects 'group_genomes_under_taxa'

    # connection parameters to various databases:
    # the production database itself (will be created)
    'host'   => 'vegabuild',
    'port'   => 5304,
    'user'   => 'ottadmin',

    # the master database for synchronization of various ids
    'master_db' => 'mysql://ottro@vegabuild:5304/vega_compara_master',

    # switch off the reuse:
    'prev_core_sources_locs'    => [ ],
    'prev_release'              => 0,   # 0 is the default and it means "take current release number and subtract 1"
    'reuse_from_prev_rel_db'    => 0,
    'do_stable_id_mapping'      => 0,

    # we're not interested in treefam
    'do_treefam_xref'           => 0,

    # hive_capacity values for some analyses:
    'store_sequences_capacity'  => 50,
    'blastp_capacity'           => 450,
    'mcoffee_capacity'          => 100,
    'njtree_phyml_capacity'     => 70,
    'ortho_tree_capacity'       => 50,
    'build_hmm_capacity'        => 50,
    'other_paralogs_capacity'   => 50,
    'homology_dNdS_capacity'    => 100,

  };
}

#
# Rather than maintain our own analysis pipeline just want to alter the existing one
#

sub pipeline_analyses {
  my ($self) = @_;

  #not needed for Vega
  my %analyses_to_ignore = map { $_ => 1 } qw(overall_qc);# treefam_xref_idmap);

  my $analyses = $self->SUPER::pipeline_analyses;
  for (my $i = @$analyses; $i >= 0; --$i) {
    my $analysis = $analyses->[$i];
    my $name = $analysis->{'-logic_name'};
    next unless $name;
    if ($analyses_to_ignore{$name}) {
      splice @$analyses, $i, 1;
    }

    if ($name eq 'run_qc_tests') {
      if (grep {$_ eq 'overall_qc'} @{$analyses->[$i]{'-flow_into'}{'1->A'}}) {
         print "Vega fix - removed flow control rule from run_qc_tests to overall_qc\n";
         delete $analyses->[$i]{'-flow_into'}{'1->A'};
       }
    }

    #include non-reference slices
    if ($name eq 'load_fresh_members') {
      $_->{'-parameters'}{'include_nonreference'} = 1;
      $_->{'-parameters'}{'include_reference'} = 1;
    }
  }
  return $analyses;
}

1;

