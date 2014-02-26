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

=head1 NAME

Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::NJTREE_PHYML

=head1 DESCRIPTION

This Analysis/RunnableDB is designed to take ProteinTree as input
This must already have a multiple alignment run on it. It uses that alignment
as input into the NJTREE PHYML program which then generates a phylogenetic tree

input_id/parameters format eg: "{'gene_tree_id'=>1234}"
    gene_tree_id : use 'id' to fetch a cluster from the ProteinTree

=head1 AUTHORSHIP

Ensembl Team. Individual contributions can be found in the CVS log.

=head1 MAINTAINER

$Author: mm14 $

=head VERSION

$Revision: 1.90 $

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with an underscore (_)

=cut

package Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::NJTREE_PHYML;

use strict;

use Bio::EnsEMBL::Compara::AlignedMemberSet;
use Bio::EnsEMBL::Compara::Utils::Cigars;

use Time::HiRes qw(time gettimeofday tv_interval);
use Data::Dumper;
use File::Glob;

use base ('Bio::EnsEMBL::Compara::RunnableDB::GeneTrees::TreeBest', 'Bio::EnsEMBL::Compara::RunnableDB::GeneTrees::StoreTree');


sub param_defaults {
    return {
            'cdna'              => 1,   # always use cdna for njtree_phyml
		'check_split_genes' => 1,
            'store_tree_support'    => 1,
            'intermediate_prefix'   => 'interm',
    };
}


sub fetch_input {
    my $self = shift @_;

    $self->param('tree_adaptor', $self->compara_dba->get_GeneTreeAdaptor);

    my $protein_tree_id     = $self->param_required('gene_tree_id');
    my $protein_tree        = $self->param('tree_adaptor')->fetch_by_dbID( $protein_tree_id )
                                        or die "Could not fetch protein_tree with gene_tree_id='$protein_tree_id'";
    $protein_tree->preload();
    $protein_tree->print_tree(10) if($self->debug);

    $self->param('protein_tree', $protein_tree);

}


sub run {
    my $self = shift;
    $self->cleanup_worker_temp_directory;
    $self->run_njtree_phyml;
}


sub write_output {
    my $self = shift;

    my @ref_support = qw(phyml_nt nj_ds phyml_aa nj_dn nj_mm);
    $self->store_genetree($self->param('protein_tree'), \@ref_support);

    my @dataflow = ();
    if ($self->param('store_intermediate_trees')) {
        foreach my $filename (glob(sprintf('%s/%s.*.nhx', $self->worker_temp_directory, $self->param('intermediate_prefix')) )) {
            $filename =~ /\.([^\.]*)\.nhx$/;
            my $clusterset_id = $1;
            next if $clusterset_id eq 'mmerge';
            next if $clusterset_id eq 'phyml';
            print STDERR "Found file $filename for clusterset $clusterset_id\n";
            my $newtree = $self->store_alternative_tree($self->_slurp($filename), $clusterset_id, $self->param('protein_tree'));
            push @dataflow, $newtree->root_id;
        }
    }

    if ($self->param('store_filtered_align')) {
        my $filename = sprintf('%s/filtalign.fa', $self->worker_temp_directory);
        $self->store_filtered_align($filename) if (-e $filename);
    }

    if (defined $self->param('output_dir')) {
        system(sprintf('cd %s; zip -r -9 %s/%d.zip', $self->worker_temp_directory, $self->param('output_dir'), $self->param('gene_tree_id')));
    }

    # Only dataflows at the end, if everything went fine
    foreach my $root_id (@dataflow) {
        $self->dataflow_output_id({'gene_tree_id' => $root_id}, 2);
    }
}

sub post_cleanup {
  my $self = shift;

  if(my $protein_tree = $self->param('protein_tree')) {
    printf("NJTREE_PHYML::post_cleanup  releasing tree\n") if($self->debug);
    $protein_tree->release_tree;
    $self->param('protein_tree', undef);
  }

  $self->SUPER::post_cleanup if $self->can("SUPER::post_cleanup");
}


##########################################
#
# internal methods
#
##########################################


sub run_njtree_phyml {
    my $self = shift;

    my $protein_tree = $self->param('protein_tree');
    my $newick;

    my $starttime = time()*1000;
    

    if (scalar(@{$protein_tree->get_all_Members}) == 2) {

        warn "Number of elements: 2 leaves, N/A split genes\n";
        $self->prepareTemporaryMemberNames($protein_tree);
        my @goodgenes = map {$_->{_tmp_name}} @{$protein_tree->get_all_Members};
        $newick = $self->run_treebest_sdi_genepair(@goodgenes);
    
    } else {

        my $input_aln = $self->dumpTreeMultipleAlignmentToWorkdir($protein_tree);
        $self->param('input_aln', $input_aln);
        
        warn sprintf("Number of elements: %d leaves, %d split genes\n", scalar(@{$protein_tree->get_all_Members}), scalar(keys %{$self->param('split_genes')}));

        my $genes_for_treebest = scalar(@{$protein_tree->get_all_Members}) - scalar(keys %{$self->param('split_genes')});
        $self->throw("Cannot build a tree with $genes_for_treebest genes (exclud. split genes)") if $genes_for_treebest < 2;

        if ($genes_for_treebest == 2) {

            my @goodgenes = grep {not exists $self->param('split_genes')->{$_}} (map {$_->{_tmp_name}} @{$protein_tree->get_all_Members});
            $newick = $self->run_treebest_sdi_genepair(@goodgenes);

        } else {

            $newick = $self->run_treebest_best($input_aln);
        }
    }

    #parse the tree into the datastucture:
    unless ($self->parse_newick_into_tree( $newick, $self->param('protein_tree') )) {
        $self->input_job->transient_error(0);
        $self->throw('The filtered alignment is empty. Cannot build a tree');
    }

    $protein_tree->store_tag('NJTREE_PHYML_runtime_msec', time()*1000-$starttime);
}


sub store_filtered_align {
    my ($self, $filename) = @_;
    print STDERR "Found filtered alignment: $filename\n";

    # Loads the filtered alignment strings
    my %hash_filtered_strings = ();
    {
        my $alignio = Bio::AlignIO->new(-file => $filename, -format => 'fasta');
        my $aln = $alignio->next_aln;
        
        unless ($aln) {
            $self->warning("Cannot store the filtered alignment for this tree\n");
            return;
        }

        foreach my $seq ($aln->each_seq) {
            $hash_filtered_strings{$seq->display_id()} = $seq->seq();
        }
    }

    my %hash_initial_strings = ();
    {
        my $alignio = Bio::AlignIO->new(-file => $self->param('input_aln'), -format => 'fasta');
        my $aln = $alignio->next_aln or die "The input alignment was lost in the process";

        foreach my $seq ($aln->each_seq) {
            $hash_initial_strings{$seq->display_id()} = $seq->seq();
        }
    }

    my $removed_columns = Bio::EnsEMBL::Compara::Utils::Cigars::identify_removed_columns(\%hash_initial_strings, \%hash_filtered_strings);
    $self->param('protein_tree')->store_tag('removed_columns', $removed_columns);
}


1;
