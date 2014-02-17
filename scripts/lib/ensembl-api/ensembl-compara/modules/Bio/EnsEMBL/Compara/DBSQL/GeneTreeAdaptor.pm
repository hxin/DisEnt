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

Bio::EnsEMBL::Compara::DBSQL::GeneTreeAdaptor

=head1 DESCRIPTION

Adaptor for a GeneTree object (individual nodes will be internally retrieved
with the GeneTreeNodeAdaptor).

=head1 INHERITANCE TREE

  Bio::EnsEMBL::Compara::DBSQL::GeneTreeAdaptor
  +- Bio::EnsEMBL::Compara::DBSQL::BaseAdaptor
  `- Bio::EnsEMBL::Compara::DBSQL::TagAdaptor


=head1 AUTHORSHIP

Ensembl Team. Individual contributions can be found in the CVS log.

=head1 MAINTAINER

$Author: mm14 $

=head VERSION

$Revision: 1.59 $

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with an underscore (_)

=cut

package Bio::EnsEMBL::Compara::DBSQL::GeneTreeAdaptor;

use strict;
use warnings;

use Data::Dumper;
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
use Bio::EnsEMBL::Utils::Scalar qw(:assert);

use Bio::EnsEMBL::Compara::GeneTree;
use DBI qw(:sql_types);

use base ('Bio::EnsEMBL::Compara::DBSQL::BaseAdaptor', 'Bio::EnsEMBL::Compara::DBSQL::TagAdaptor');


#
# FETCH methods
###########################

=head2 fetch_all

  Arg [-TREE_TYPE] (opt)
             : string: the type of trees that have to be fetched
               Currently one of 'clusterset', 'supertree', 'tree'
  Arg [-MEMBER_TYPE] (opt)
             : string: the type of the members that are part of the tree
               Currently 'protein' or 'ncrna'
  Arg [-METHOD_LINK_SPECIES_SET] (opt)
             : MethodLinkSpeciesSet or int: either the object or its dbID
               NB: It currently gives the same partition of the data as member_type
  Arg [-CLUSTERSET_ID] (opt)
             : string: the name of the clusterset (use "default" to get the default
               trees). Currently, there is a clusterset for the default trees, one for
               each phylogenetic model used in the protein tree pipeline, and one for
               the multiple alignment of super-trees.
  Example    : $all_trees = $genetree_adaptor->fetch_all();
  Description: Fetches from the database all the gene trees
  Returntype : arrayref of Bio::EnsEMBL::Compara::GeneTree
  Exceptions : none
  Caller     : general

=cut

sub fetch_all {
    my ($self, @args) = @_;
    my ($clusterset_id, $mlss, $tree_type, $member_type)
        = rearrange([qw(CLUSTERSET_ID METHOD_LINK_SPECIES_SET TREE_TYPE MEMBER_TYPE)], @args);
    my @constraint = ();

    if (defined $tree_type) {
        push @constraint, '(gtr.tree_type = ?)';
        $self->bind_param_generic_fetch($tree_type, SQL_VARCHAR);
    }

    if (defined $member_type) {
        push @constraint, '(gtr.member_type = ?)';
        $self->bind_param_generic_fetch($member_type, SQL_VARCHAR);
    }

    my $mlss_id = (ref($mlss) ? $mlss->dbID : $mlss);
    if (defined $mlss_id) {
        push @constraint, '(gtr.method_link_species_set_id = ?)';
        $self->bind_param_generic_fetch($mlss_id, SQL_INTEGER);
    }

    if (defined $clusterset_id) {
        push @constraint, '(gtr.clusterset_id = ?)';
        $self->bind_param_generic_fetch($clusterset_id, SQL_VARCHAR);
    }

    return $self->generic_fetch(join(' AND ', @constraint));
}


=head2 fetch_by_stable_id

  Arg[1]     : string $tree_stable_id
  Example    : $tree = $genetree_adaptor->fetch_by_stable_id("ENSGT00590000083078");
  Description: Fetches from the database the gene tree for that stable ID
  Returntype : Bio::EnsEMBL::Compara::GeneTree
  Exceptions : returns undef if $stable_id is not found.
  Caller     : general

=cut

sub fetch_by_stable_id {
    my ($self, $stable_id) = @_;

    $self->bind_param_generic_fetch($stable_id, SQL_VARCHAR);
    return $self->generic_fetch_one('gtr.stable_id = ?');
}


=head2 fetch_by_root_id

  Arg[1]     : int $tree_root_id
  Example    : $tree = $genetree_adaptor->fetch_by_root_id(3);
  Description: Fetches from the database the gene tree for that root ID
               This is equivalent to fetch_by_dbID
  Returntype : Bio::EnsEMBL::Compara::GeneTree
  Exceptions : returns undef if $root_id is not found.
  Caller     : general

=cut

sub fetch_by_root_id {
    my ($self, $root_id) = @_;

    $self->bind_param_generic_fetch($root_id, SQL_INTEGER);
    return $self->generic_fetch_one('gtr.root_id = ?');
}


=head2 fetch_by_dbID

  Arg[1]     : int $tree_root_id
  Example    : $tree = $genetree_adaptor->fetch_by_dbID(3);
  Description: Fetches from the database the gene tree for that root ID
               This is equivalent to fetch_by_root_id
  Returntype : Bio::EnsEMBL::Compara::GeneTree
  Exceptions : returns undef if $root_id is not found.
  Caller     : general

=cut

sub fetch_by_dbID {
    my ($self, $root_id) = @_;

    $self->bind_param_generic_fetch($root_id, SQL_INTEGER);
    return $self->generic_fetch_one('gtr.root_id = ?');
}


=head2 fetch_by_node_id

  Arg[1]     : int $tree_node_id
  Example    : $tree = $genetree_adaptor->fetch_by_node_id(3);
  Description: Fetches from the database the gene tree that contains
               this node
  Returntype : Bio::EnsEMBL::Compara::GeneTree
  Exceptions : returns undef if $node_id is not found.
  Caller     : general

=cut

sub fetch_by_node_id {
    my ($self, $node_id) = @_;

    $self->bind_param_generic_fetch($node_id, SQL_INTEGER);
    my $join = [[['gene_tree_node', 'gtn'], 'gtn.root_id = gtr.root_id']];
    return $self->generic_fetch_one('gtn.node_id = ?', $join);
}


=head2 fetch_all_by_Member

  Arg[1]     : Member or member_id
  Arg [-METHOD_LINK_SPECIES_SET] (opt)
             : MethodLinkSpeciesSet or int: either the object or its dbID
  Arg [-CLUSTERSET_ID] (opt)
             : string: the name of the clusterset (default is "default")
  Example    : $all_trees = $genetree_adaptor->fetch_all_by_Member($member);
  Description: Fetches from the database all the gene trees that contains this member
               If the member is not an ENSEMBLGENE, it has to be canoncal, otherwise,
                 the function would return undef
  Returntype : arrayref of Bio::EnsEMBL::Compara::GeneTree
  Exceptions : none
  Caller     : general

=cut

sub fetch_all_by_Member {
    my ($self, $member, @args) = @_;
    my ($clusterset_id, $mlss) = rearrange([qw(CLUSTERSET_ID METHOD_LINK_SPECIES_SET)], @args);

    # Discard the UNIPROT members
    return [] if (ref($member) and not ($member->source_name =~ 'ENSEMBL'));

    my $join = [[['gene_tree_node', 'gtn'], 'gtn.root_id = gtr.root_id'], [['member', 'm'], 'gtn.member_id = m.member_id']];
    my $constraint = '((m.member_id = ?) OR (m.gene_member_id = ?))';
    
    my $member_id = (ref($member) ? $member->dbID : $member);
    $self->bind_param_generic_fetch($member_id, SQL_INTEGER);
    $self->bind_param_generic_fetch($member_id, SQL_INTEGER);
    
    my $mlss_id = (ref($mlss) ? $mlss->dbID : $mlss);
    if (defined $mlss_id) {
        $constraint .= ' AND (gtr.method_link_species_set_id = ?)';
        $self->bind_param_generic_fetch($mlss_id, SQL_INTEGER);
    }
    if (defined $clusterset_id) {
        $constraint .= ' AND (gtr.clusterset_id = ?)';
        $self->bind_param_generic_fetch($clusterset_id, SQL_VARCHAR);
    }

    return $self->generic_fetch($constraint, $join);
}


=head2 fetch_default_for_Member

  Arg[1]     : Member or member_id
  Example    : $trees = $genetree_adaptor->fetch_default_for_Member($member);
  Description: Fetches from the database the default gene tree that contains this member
               If the member is not an ENSEMBLGENE, it has to be canoncal, otherwise,
                 the function would return undef
  Returntype : Bio::EnsEMBL::Compara::GeneTree
  Exceptions : none
  Caller     : general

=cut

sub fetch_default_for_Member {
    my ($self, $member) = @_;

    # Discard the UNIPROT members
    return undef if (ref($member) and not ($member->source_name =~ 'ENSEMBL'));
    # Returns if $member is not defined or 0
    return undef unless $member;

    my $join = [[['gene_tree_node', 'gtn'], 'gtn.root_id = gtr.root_id'], [['member', 'm'], 'gtn.member_id = m.member_id']];
    my $constraint = '((m.member_id = ?) OR (m.gene_member_id = ?)) AND (gtr.clusterset_id = "default")';
    
    my $member_id = (ref($member) ? $member->dbID : $member);
    $self->bind_param_generic_fetch($member_id, SQL_INTEGER);
    $self->bind_param_generic_fetch($member_id, SQL_INTEGER);
    
    return $self->generic_fetch_one($constraint, $join);
}


=head2 fetch_parent_tree

  Arg[1]     : GeneTree $tree or its root_id
  Example    : $parent = $genetree_adaptor->fetch_parent_tree($tree);
  Description: Fetches from the database the parent (tree) of the argument tree
  Returntype : Bio::EnsEMBL::Compara::GeneTree
  Exceptions : returns undef if called on a 'clusterset' tree
  Caller     : general

=cut

sub fetch_parent_tree {
    my ($self, $tree) = @_;

    my $tree_id = (ref($tree) ? $tree->root_id : $tree);

    my $join = [[['gene_tree_node', 'gtn1'], 'gtn1.root_id = gtr.root_id'], [['gene_tree_node', 'gtn2'], 'gtn1.node_id = gtn2.parent_id']];
    my $constraint = "(gtn2.root_id = gtn2.node_id) AND (gtn2.root_id = ?)";
    
    $self->bind_param_generic_fetch($tree_id, SQL_INTEGER);
    return $self->generic_fetch_one($constraint, $join);
}


=head2 fetch_subtrees

  Arg[1]     : GeneTree $tree or its root_id
  Example    : $subtrees = $genetree_adaptor->fetch_subtrees($tree);
  Description: Fetches from the database the trees that are children of the argument tree
  Returntype : arrayref of Bio::EnsEMBL::Compara::GeneTree
  Exceptions : the array is empty if called on a 'tree' tree
  Caller     : general

=cut

sub fetch_subtrees {
    my ($self, $tree) = @_;

    my $tree_id = (ref($tree) ? $tree->root_id : $tree);

    my $join = [[['gene_tree_node', 'gtn2'], 'gtn2.node_id = gtr.root_id', ['gtn2.parent_id']], [['gene_tree_node', 'gtn1'], 'gtn1.node_id = gtn2.parent_id']];
    my $constraint = "(gtn1.root_id = ?) AND (gtn2.root_id != gtn1.root_id)";

    $self->bind_param_generic_fetch($tree_id, SQL_INTEGER);
    return $self->generic_fetch($constraint, $join);
}


=head2 fetch_all_linked_trees

  Arg[1]     : GeneTree $tree or its root_id
  Example    : $othertrees = $genetree_adaptor->fetch_all_linked_trees($tree);
  Description: Fetches from the database all trees that are associated to the argument tree.
                The other trees generally contain the same members, but are either build
                with a different phylogenetic model, or have a different multiple alignment.
  Returntype : arrayref of Bio::EnsEMBL::Compara::GeneTree
  Caller     : general

=cut

sub fetch_all_linked_trees {
    my ($self, $tree) = @_;

    # Currently, all linked trees are accessible in 1 hop
    if ($tree->ref_root_id) {
        # Trees that share the same reference
        $self->bind_param_generic_fetch($tree->ref_root_id, SQL_INTEGER);
    } else {
        # The given tree is the reference
        $self->bind_param_generic_fetch($tree->root_id, SQL_INTEGER);
    }
    return $self->generic_fetch('ref_root_id = ?');
}


#
# STORE/DELETE methods
###########################

sub store {
    my ($self, $tree) = @_;

    # Firstly, store the nodes
    my $has_root_id = (exists $tree->{'_root_id'} ? 1 : 0);
    my $root_id = $self->db->get_GeneTreeNodeAdaptor->store_nodes_rec($tree->root);
    $tree->{'_root_id'} = $root_id;

    # Secondly, the tree itself
    my $sth;
    # Make sure that the variables are in the same order
    if ($has_root_id) {
        $sth = $self->prepare('UPDATE gene_tree_root SET tree_type=?, member_type=?, clusterset_id=?, gene_align_id=?, method_link_species_set_id=?, stable_id=?, version=?, ref_root_id=? WHERE root_id=?'),
    } else {
        $sth = $self->prepare('INSERT INTO gene_tree_root (tree_type, member_type, clusterset_id, gene_align_id, method_link_species_set_id, stable_id, version, ref_root_id, root_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)');
    }
    $sth->execute($tree->tree_type, $tree->member_type, $tree->clusterset_id, $tree->gene_align_id, $tree->method_link_species_set_id, $tree->stable_id, $tree->version, $tree->ref_root_id, $root_id);
    
    $tree->adaptor($self);

    return $root_id;
}

sub delete_tree {
    my ($self, $tree) = @_;

    assert_ref($tree, 'Bio::EnsEMBL::Compara::GeneTree');

    # Remove all the nodes but the root
    my $gene_tree_node_Adaptor = $tree->root->adaptor;
    for my $node (@{$tree->get_all_nodes}) {
        next if ($node->node_id() == $tree->root->node_id());
        $gene_tree_node_Adaptor->delete_node($node);
    }

    # Only for "default" trees
    unless ($tree->ref_root_id) {

        # Linked trees must be removed as well as they refer to the default tree
        foreach my $other_tree (@{$self->fetch_all_linked_trees($tree)}) {
            $other_tree->preload();
            $self->delete_tree($other_tree);
            $other_tree->release_tree();
        }
    }

    # Finally remove the root node
    $gene_tree_node_Adaptor->delete_node($tree->root);

    # Only for "default" trees
    unless ($tree->ref_root_id) {
        # The alignment
        $gene_tree_node_Adaptor->db->get_GeneAlignAdaptor->delete($tree->gene_align_id);

        # The HMM profile
        my $root_id = $tree->root->node_id;
        $self->dbc->do("DELETE FROM hmm_profile WHERE model_id = '$root_id'");
    }

}


#
# Virtual methods from TagAdaptor
###################################

sub _tag_capabilities {
    return ('gene_tree_root_tag', undef, 'root_id', 'root_id');
}


#
# Virtual methods from BaseAdaptor
####################################

sub _tables {

    return (['gene_tree_root', 'gtr'])
}

sub _columns {

    return qw (
        gtr.root_id
        gtr.tree_type
        gtr.member_type
        gtr.clusterset_id
        gtr.gene_align_id
        gtr.method_link_species_set_id
        gtr.stable_id
        gtr.version
        gtr.ref_root_id
    );
}

sub _objs_from_sth {
  my ($self, $sth) = @_;
  my @tree_list = ();

  while(my $rowhash = $sth->fetchrow_hashref) {
    #my $tree = new Bio::EnsEMBL::Compara::GeneTree(-adaptor => $self, %$rowhash);
    my $tree = Bio::EnsEMBL::Compara::GeneTree->new_fast({
        _adaptor                    => $self,                   # field name NOT in sync with Bio::EnsEMBL::Storable
        _root_id                    => $rowhash->{root_id},     # field name NOT in sync with Bio::EnsEMBL::Storable
        _tree_type                  => $rowhash->{tree_type},
        _member_type                => $rowhash->{member_type},
        _clusterset_id              => $rowhash->{clusterset_id},
        _gene_align_id              => $rowhash->{gene_align_id},
        _method_link_species_set_id => $rowhash->{method_link_species_set_id},
        _stable_id                  => $rowhash->{stable_id},
        _version                    => $rowhash->{version},
        _ref_root_id                => $rowhash->{ref_root_id},
        _parent_id                  => $rowhash->{parent_id},
    });
    push @tree_list, $tree;
  }

  return \@tree_list;
}


1;
