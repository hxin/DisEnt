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

Bio::EnsEMBL::Compara::DBSQL::GeneTreeNodeAdaptor

=head1 DESCRIPTION

Adaptor to retrieve nodes of gene trees

=head1 INHERITANCE TREE

  Bio::EnsEMBL::Compara::DBSQL::GeneTreeNodeAdaptor
  +- Bio::EnsEMBL::Compara::DBSQL::NestedSetAdaptor
  `- Bio::EnsEMBL::Compara::DBSQL::TagAdaptor

=head1 AUTHORSHIP

Ensembl Team. Individual contributions can be found in the CVS log.

=head1 MAINTAINER

$Author: mm14 $

=head VERSION

$Revision: 1.44 $

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with an underscore (_)

=cut

package Bio::EnsEMBL::Compara::DBSQL::GeneTreeNodeAdaptor;

use strict;
use warnings;

use Bio::EnsEMBL::Utils::Exception qw(throw warning deprecate);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);
use Bio::EnsEMBL::Utils::Scalar qw(:assert);

use Bio::EnsEMBL::Compara::GeneTree;
use Bio::EnsEMBL::Compara::GeneTreeNode;
use Bio::EnsEMBL::Compara::GeneTreeMember;
use Bio::EnsEMBL::Compara::DBSQL::SeqMemberAdaptor;

use DBI qw(:sql_types);

use base ('Bio::EnsEMBL::Compara::DBSQL::NestedSetAdaptor', 'Bio::EnsEMBL::Compara::DBSQL::TagAdaptor');

###########################
# FETCH methods
###########################


=head2 fetch_all_AlignedMember_by_Member

  Arg[1]     : Member or member_id
  Arg [-METHOD_LINK_SPECIES_SET] (opt)
             : MethodLinkSpeciesSet or int: either the object or its dbID
  Arg [-CLUSTERSET_ID] (opt)
             : int: the root_id of the clusterset node
               NB: The definition of this argument is unstable and might change
                   in the future
  Example    : $all_members = $genetree_adaptor->fetch_all_AlignedMember_by_Member($member);
  Description: Transforms the member into an AlignedMember. If the member is
               not an ENSEMBLGENE, it has to be canoncal, otherwise, the
               function would return an empty array
  Returntype : arrayref of Bio::EnsEMBL::Compara::AlignedMember
  Exceptions : none
  Caller     : general

=cut

sub fetch_all_AlignedMember_by_Member {
    my ($self, $member, @args) = @_;
    my ($clusterset_id, $mlss) = rearrange([qw(CLUSTERSET_ID METHOD_LINK_SPECIES_SET)], @args);

    # Discard the UNIPROT members
    return [] if (ref($member) and not ($member->source_name =~ 'ENSEMBL'));

    my $member_id = (ref($member) ? $member->dbID : $member);
    my $constraint = '((m.member_id = ?) OR (m.gene_member_id = ?))';
    $self->bind_param_generic_fetch($member_id, SQL_INTEGER);
    $self->bind_param_generic_fetch($member_id, SQL_INTEGER);

    my $mlss_id = (ref($mlss) ? $mlss->dbID : $mlss);
    if (defined $mlss_id) {
        $constraint .= ' AND (tr.method_link_species_set_id = ?)';
        $self->bind_param_generic_fetch($mlss_id, SQL_INTEGER);
    }

    if (defined $clusterset_id) {
        $constraint .= ' AND (tr.clusterset_id = ?)';
        $self->bind_param_generic_fetch($clusterset_id, SQL_VARCHAR);
    }

    if (defined $self->_default_member_type) {
        $constraint .= ' AND (tr.member_type = ?)';
        $self->bind_param_generic_fetch($self->_default_member_type, SQL_VARCHAR);
    }

    my $join = [[['gene_tree_root', 'tr'], 't.root_id = tr.root_id']];
    return $self->generic_fetch($constraint, $join);
}


=head2 fetch_default_AlignedMember_for_Member

  Arg[1]     : Member or member_id
  Example    : $align_member = $genetreenode_adaptor->fetch_adefault_AlignedMember_for_Member($member);
  Description: Transforms the member into an AlignedMember. If the member is
               not an ENSEMBLGENE, it has to be canoncal, otherwise, the
               function would return undef
  Returntype : Bio::EnsEMBL::Compara::AlignedMember
  Exceptions : none
  Caller     : general

=cut

sub fetch_default_AlignedMember_for_Member {
    my ($self, $member) = @_;

    # Discard the UNIPROT members
    return undef if (ref($member) and not ($member->source_name =~ 'ENSEMBL'));

    my $member_id = (ref($member) ? $member->dbID : $member);
    my $constraint = '((m.member_id = ?) OR (m.gene_member_id = ?))';
    $self->bind_param_generic_fetch($member_id, SQL_INTEGER);
    $self->bind_param_generic_fetch($member_id, SQL_INTEGER);


    $constraint .= ' AND (tr.clusterset_id = "default")';

    my $join = [[['gene_tree_root', 'tr'], 't.root_id = tr.root_id']];
    return $self->generic_fetch_one($constraint, $join);
}


=head2 fetch_all_AlignedMember_by_root_id

  Arg[1]     : int: root_id: ID of the root node of the tree
  Example    : $all_members = $genetree_adaptor->fetch_all_AlignedMember_by_root_id($root_id);
  Description: Gets all the AlignedMembers of the given tree. This is equivalent to fetching
               the Member leaves of a tree, directly, without using the left/right_index
  Returntype : arrayref of Bio::EnsEMBL::Compara::AlignedMember
  Exceptions : none
  Caller     : general

=cut

sub fetch_all_AlignedMember_by_root_id {
  my ($self, $root_id) = @_;

  my $constraint = '(t.member_id IS NOT NULL) AND (t.root_id = ?)';
  $self->bind_param_generic_fetch($root_id, SQL_INTEGER);
  return $self->generic_fetch($constraint);

}




###########################
# STORE methods
###########################

sub store_nodes_rec {
    my ($self, $node) = @_;

    my $children = $node->children;
    # Firstly, store the node
    $self->store_node($node);

    # Secondly, recursively do all the children
    foreach my $child_node (@$children) {
        # Store the GeneTreeNode or the new GeneTree if different
        if ((not defined $child_node->tree) or ($child_node->root eq $node->root)) {
            $self->store_nodes_rec($child_node);
        } else {
            $self->db->get_GeneTreeAdaptor->store($child_node->tree);
        }
    }

    return $node->node_id;

}

sub store_node {
    my ($self, $node) = @_;

    assert_ref($node, 'Bio::EnsEMBL::Compara::GeneTreeNode');

    if (not($node->adaptor and $node->adaptor->isa('Bio::EnsEMBL::Compara::DBSQL::GeneTreeNodeAdaptor') and $node->adaptor eq $self)) {
        my $sth = $self->prepare("INSERT INTO gene_tree_node VALUES ()");
        $sth->execute();
        $node->node_id( $sth->{'mysql_insertid'} );
    }

    my $parent_id = undef;
    $parent_id = $node->parent->node_id if($node->parent);

    my $root_id = $node->root->node_id;
    #print "inserting parent_id=$parent_id, root_id=$root_id\n";
    my $member_id = undef;
    $member_id = $node->member_id if $node->isa('Bio::EnsEMBL::Compara::GeneTreeMember');

    my $sth = $self->prepare("UPDATE gene_tree_node SET parent_id=?, root_id=?, left_index=?, right_index=?, distance_to_parent=?, member_id=?  WHERE node_id=?");
    #print "UPDATE gene_tree_node  (", $parent_id, ",", $root_id, ",", $node->left_index, ",", $node->right_index, ",", $node->distance_to_parent, ") for ", $node->node_id, "\n";
    $sth->execute($parent_id, $root_id, $node->left_index, $node->right_index, $node->distance_to_parent, $member_id, $node->node_id);
    $sth->finish;

    $node->adaptor($self);

    return $node->node_id;
}


sub merge_nodes {
  my ($self, $node1, $node2) = @_;

  assert_ref($node1, 'Bio::EnsEMBL::Compara::GeneTreeNode');
  assert_ref($node2, 'Bio::EnsEMBL::Compara::GeneTreeNode');

  # printf("MERGE children from parent %d => %d\n", $node2->node_id, $node1->node_id);

  my $sth = $self->prepare("UPDATE gene_tree_node SET parent_id=? WHERE parent_id=?");
  $sth->execute($node1->node_id, $node2->node_id);
  $sth->finish;

  $sth = $self->prepare("DELETE from gene_tree_node WHERE node_id=?");
  $sth->execute($node2->node_id);
  $sth->finish;
}

sub delete_flattened_leaf {
  my $self = shift;
  my $node = shift;

  my $node_id = $node->node_id;
  $self->dbc->do("DELETE from gene_tree_node_tag    WHERE node_id = $node_id");
  $self->dbc->do("DELETE from gene_tree_node_attr   WHERE node_id = $node_id");
  $self->dbc->do("DELETE from gene_tree_node   WHERE node_id = $node_id");
}

sub delete_node {
  my $self = shift;
  my $node = shift;

  my $node_id = $node->node_id;
  $self->dbc->do("UPDATE gene_tree_node dn, gene_tree_node n SET ".
            "n.parent_id = dn.parent_id WHERE n.parent_id=dn.node_id AND dn.node_id=$node_id");
  $self->dbc->do("DELETE from gene_tree_node_tag    WHERE node_id = $node_id");
  $self->dbc->do("DELETE from gene_tree_node_attr   WHERE node_id = $node_id");
  $self->dbc->do("UPDATE gene_tree_node SET root_id = NULL WHERE node_id = $node_id");
  $self->dbc->do("DELETE homology_member from homology_member JOIN homology using(homology_id) WHERE gene_tree_node_id = $node_id");
  $self->dbc->do("DELETE from homology WHERE gene_tree_node_id = $node_id");

  # The node is actually a root. We have to clear the entry in gene_tree_root
  if ($node_id == $node->tree->root->node_id) {
    $self->dbc->do("DELETE FROM gene_tree_root_tag WHERE root_id = $node_id");
    $self->dbc->do("DELETE FROM gene_tree_root WHERE root_id = $node_id");
  }

  $self->dbc->do("DELETE from gene_tree_node   WHERE node_id = $node_id");
}

sub delete_nodes_not_in_tree
{
  my $self = shift;
  my $tree = shift;

  assert_ref($tree, 'Bio::EnsEMBL::Compara::GeneTreeNode');
  #print("delete_nodes_not_present under ", $tree->node_id, "\n");
  my $dbtree = $self->fetch_node_by_node_id($tree->node_id);
  my @all_db_nodes = $dbtree->get_all_subnodes;
  foreach my $dbnode (@all_db_nodes) {
    next if($tree->find_node_by_node_id($dbnode->node_id));
    #print "Deleting unused node ", $dbnode->node_id, "\n";
    $self->delete_node($dbnode);
  }
  $dbtree->release_tree;
}


###################################
#
# tagging
#
###################################

sub _tag_capabilities {
    return ('gene_tree_node_tag', 'gene_tree_node_attr', 'node_id', 'node_id');
}


##################################
#
# subclass override methods
#
##################################

sub _columns {
  return ('t.node_id',
          't.parent_id',
          't.root_id',
          't.left_index',
          't.right_index',
          't.distance_to_parent',

          'gam.cigar_line',

          Bio::EnsEMBL::Compara::DBSQL::SeqMemberAdaptor->_columns()
          );
}

sub _tables {
  return (['gene_tree_node', 't'], ['gene_tree_root', 'tr'], ['gene_align_member', 'gam'], ['member', 'm']);
}

sub _default_where_clause {
    return 't.root_id = tr.root_id';
}

sub _left_join {
    return (
        ['gene_align_member', 'gam.member_id = t.member_id AND gam.gene_align_id = tr.gene_align_id'],
        ['member', 't.member_id = m.member_id'],
    );
}


sub create_instance_from_rowhash {
  my $self = shift;
  my $rowhash = shift;

  my $node;
  if($rowhash->{'member_id'}) {
    $node = new Bio::EnsEMBL::Compara::GeneTreeMember;
  } else {
    $node = new Bio::EnsEMBL::Compara::GeneTreeNode;
  }

  $self->init_instance_from_rowhash($node, $rowhash);

    if ((defined $self->{'_ref_tree'}) and ($self->{'_ref_tree'}->root_id eq $rowhash->{root_id})) {
        # GeneTree was passed via _ref_tree
        #print STDERR "REUSING GeneTree for $node :", $self->{'_ref_tree'};
        $node->tree($self->{'_ref_tree'});
    } 

  return $node;
}


sub init_instance_from_rowhash {
    my $self = shift;
    my $node = shift;
    my $rowhash = shift;

    # SUPER is NestedSetAdaptor
    $self->SUPER::init_instance_from_rowhash($node, $rowhash);
    if ($node->isa('Bio::EnsEMBL::Compara::GeneTreeMember')) {
        # here is a gene leaf
        Bio::EnsEMBL::Compara::DBSQL::SeqMemberAdaptor->init_instance_from_rowhash($node, $rowhash);

        $node->cigar_line($rowhash->{'cigar_line'});
    } else {
        # here is an internal node
    }
    # print("  create node : ", $node, " : "); $node->print_node;
    $node->adaptor($self);

    return $node;
}



sub _default_member_type {
    return undef;
}



###############################################################################
#
# Dynamic redefinition of functions to reuse the link to the GeneTree object
#
###############################################################################

{
    no strict 'refs';
    foreach my $func_name (qw(
                                 fetch_all_children_for_node fetch_parent_for_node fetch_all_leaves_indexed
                                 fetch_subtree_under_node fetch_root_by_node
                                 fetch_first_shared_ancestor_indexed
                            )) {
        my $full_name = "Bio::EnsEMBL::Compara::DBSQL::GeneTreeNodeAdaptor::$func_name";
        my $super_name = "SUPER::$func_name";
        *$full_name = sub {
            my $self = shift;
            $self->{'_ref_tree'} = $_[0]->{'_tree'};
            my $ret = $self->$super_name(@_);
            delete $self->{'_ref_tree'};
            return $ret;
        };
        #print "REDEFINE $func_name\n";
    }
}


1;
