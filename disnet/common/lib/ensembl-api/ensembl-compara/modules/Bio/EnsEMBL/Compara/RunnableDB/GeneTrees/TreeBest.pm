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

Bio::EnsEMBL::Compara::RunnableDB::GeneTrees::TreeBest

=head1 DESCRIPTION

This Runnable offers some methods to run Treebest.

Notes:
- Apart from the multiple alignments, all the data are exchanged as
Perl strings.
- The parameter treebest_exe must be set.
- An alignment filtering method can be defined via the parameter filt_cmdline

=head1 AUTHORSHIP

Ensembl Team. Individual contributions can be found in the CVS log.

=head1 MAINTAINER

$Author: mm14 $

=head VERSION

$Revision: 1.8 $

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with an underscore (_)

=cut

package Bio::EnsEMBL::Compara::RunnableDB::GeneTrees::TreeBest;

use strict;

use base ('Bio::EnsEMBL::Compara::RunnableDB::RunCommand');

# First of all, we need a tree of node_ids, since our foreign keys are based on that

sub load_species_tree_from_db {
    my ($self) = @_;
    my $mlss_id = $self->param_required('mlss_id');
    my $species_tree = $self->compara_dba->get_SpeciesTreeAdaptor->fetch_by_method_link_species_set_id_label($mlss_id, 'default');
    $self->param('species_tree_string', $species_tree->root->newick_format('ryo', '%{o}%{-E"*"}'))
}


#
# Methods that will build a tree on an alignment
##################################################


=head2 run_treebest_best

    - IN: $input_aln: filename: the multiple alignment
    - OUT: string: the "best" tree computed on the alignment
    - PARAM: intermediate_prefix: how to prefix the files with the intermediate trees
    - PARAM: extra_args: extra arguments to give to treebest

=cut

sub run_treebest_best {
    my ($self, $input_aln) = @_;

    my $species_tree_file = $self->get_species_tree_file();
    my $max_diff_lk;

    while (1) {

        # Main arguments
        my $args = sprintf('best -f %s', $species_tree_file);
        
        # Optional arguments
        $args .= sprintf(' -p %s', $self->param('intermediate_prefix')) if $self->param('intermediate_prefix');
        $args .= sprintf(' %s', $self->param('extra_args')) if $self->param('extra_args');
        $args .= sprintf(' -Z %f', $max_diff_lk) if $max_diff_lk;

        my $cmd = $self->_get_alignment_filtering_cmd($args, $input_aln);
        my $run_cmd = $self->run_command($cmd);
        return $run_cmd->out unless ($run_cmd->exit_code);

        my $full_cmd = $run_cmd->cmd;
        $self->throw("'$full_cmd' resulted in a segfault") if ($run_cmd->exit_code == 11);

        print STDERR "$full_cmd\n";
        my $logfile = $run_cmd->err;
        $logfile =~ s/^Large distance.*$//mg;
        $logfile =~ s/\n\n*/\n/g;
        if (($logfile =~ /NNI/) || ($logfile =~ /Optimize_Br_Len_Serie/) || ($logfile =~ /Optimisation failed/) || ($logfile =~ /Brent failed/))  {
            # Increase the tolerance max_diff_lk in the computation
            $max_diff_lk = 1e-5 unless $max_diff_lk;
            $max_diff_lk *= 10;
            $self->warning("Lowering max_diff_lk to $max_diff_lk");
        } else {
            $self->throw(sprintf("error running treebest [%s]: %d\n%s", $run_cmd->cmd, $run_cmd->exit_code, $logfile));
        }
    }

}


=head2 run_treebest_nj

    -IN: $input_aln: filename: the multiple alignment
    -OUT: string: the tree built on that alignment

=cut

sub run_treebest_nj {
    my ($self, $input_aln) = @_;

    my $args = sprintf('nj -s %s ', $self->get_species_tree_file());

    return $self->_run_and_return_output($self->_get_alignment_filtering_cmd($args, $input_aln));
}


=head2 run_treebest_phyml

    -IN: $input_aln: filename: the multiple alignment
    -OUT: string: the tree built on that alignment

=cut

sub run_treebest_phyml {
    my ($self, $input_aln) = @_;

    my $args = sprintf('phyml -Snf %s', $self->get_species_tree_file());

    return $self->_run_and_return_output($self->_get_alignment_filtering_cmd($args, $input_aln));
}


=head2 run_treebest_branchlength_nj

    -IN: $input_aln: filename: the multiple alignment
    -IN: $input_tree: string: the tree
    -OUT: string: the same tree with branch lengths

=cut

sub run_treebest_branchlength_nj {
    my ($self, $input_aln, $input_tree) = @_;

    my $args = sprintf(
        'nj -I -c %s -s %s',
        $self->_write_temp_tree_file('input_tree', $input_tree),
        $self->get_species_tree_file());

    return $self->_run_and_return_output($self->_get_alignment_filtering_cmd($args, $input_aln));
}


#
# Alignment-free methods
#########################

=head2 run_treebest_mmerge

    -IN: $input_forest: arrayref of strings: the trees to merge
    -OUT: string: the merged tree

=cut

sub run_treebest_mmerge {
    my ($self, $input_forest) = @_;

    my $args = sprintf(
        'mmerge -s %s %s',
        $self->get_species_tree_file(),
        $self->_write_temp_tree_file('input_forest', join("\n", @$input_forest)),
    );

    return $self->_run_and_return_output($self->_get_treebest_cmd($args));
}


=head2 run_treebest_sdi_genepair

    - IN: $gene1: string: name of the first gene
    - IN: $gene2: string: name of the second gene
    - OUT: string: reconciled tree with the two genes

=cut

sub run_treebest_sdi_genepair {
    my ($self, $gene1, $gene2) = @_;

    return $self->run_treebest_sdi(sprintf('(%s,%s);', $gene1, $gene2), 0);
}


=head2 run_treebest_sdi

    - IN: $unreconciled_tree: string: the unreconciled tree
    - OUT: string: the reconciled tree

=cut

sub run_treebest_sdi {
    my ($self, $unreconciled_tree, $root_tree) = @_;

    my $args = sprintf(
        'sdi -%s %s %s',
        $root_tree ? 'rs' : 's',
        $self->get_species_tree_file,
        $self->_write_temp_tree_file('unrooted.nhx', $unreconciled_tree),
    );

    return $self->_run_and_return_output($self->_get_treebest_cmd($args));
}


#
# Common methods to call treebest
##################################


=head2 _get_alignment_filtering_cmd

    Returns the command line needed to run treebest with a filtered alignment

=cut

sub _get_alignment_filtering_cmd {
    my ($self, $args, $input_aln) = @_;

    my $cmd = $self->_get_treebest_cmd($args).' ';

    # External alignment filtering ?
    if (defined $self->param('filt_cmdline')) {
        my $tmp_align = $self->worker_temp_directory.'prog-filtalign.fa';
        $cmd .= $tmp_align;
        $cmd = sprintf($self->param('filt_cmdline'), $input_aln, $tmp_align).' ; '.$cmd;
    } else {
        $cmd .= $input_aln
    }

    return sprintf('cd %s; %s', $self->worker_temp_directory, $cmd);
}


=head2 _get_treebest_cmd

    Returns the command line needed to run treebest with the given arguments

=cut

sub _get_treebest_cmd {
    my ($self, $args) = @_;

    my $treebest_exe = $self->param_required('treebest_exe');
    die "Cannot execute '$treebest_exe'" unless (-x $treebest_exe);

    return sprintf('%s %s', $treebest_exe, $args);
}


=head2 _run_and_return_output

    Runs the command and checks for failure.
    Returns the output of treebest if success.

=cut

sub _run_and_return_output {
    my ($self, $cmd) = @_;

    my $cmd_out = $self->run_command($cmd);
    return $cmd_out->out unless $cmd_out->exit_code;

    $self->throw(sprintf("error running treebest [%s]: %d\n%s", $cmd_out->cmd, $cmd_out->exit_code, $cmd_out->err));
}


=head2 _write_temp_tree_file

    Creates a temporary file in the worker temp directory, with the given content

=cut

sub _write_temp_tree_file {
    my ($self, $tree_name, $tree_content) = @_;

    my $filename = $self->worker_temp_directory . $tree_name;
    open FILE,">$filename" or die $!;
    print FILE $tree_content;
    close FILE;

    return $filename;
}


1;
