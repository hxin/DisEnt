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

=cut

=head1 NAME

Bio::EnsEMBL::DBSQL::SOTermAdaptor

=head1 DESCRIPTION

A specialization of Bio::EnsEMBL::DBSQL::OntologyTermAdaptor,
specifically for Sequence ontology (SO) terms.  See the
documentation of Bio::EnsEMBL::DBSQL::OntologyTermAdaptor for
further information.

=head1 METHODS

=cut

package Bio::EnsEMBL::DBSQL::SOTermAdaptor;

use strict;
use warnings;

use base qw( Bio::EnsEMBL::DBSQL::OntologyTermAdaptor );

=head2 new

  Arg [1]       : Bio::EnsEMBL::DBSQL::DBAdaptor
                  Argument required for parent class
                  Bio::EnsEMBL::DBSQL::BaseAdaptor.

  Description   : Creates an ontology term adaptor for SO terms.

  Example       :

    my $go_adaptor = Bio::EnsEMBL::DBSQL::SOTermAdaptor->new( $dba );

  Return type   : Bio::EnsEMBL::DBSQL::SOTermAdaptor

=cut

sub new {
  my ( $proto, $dba ) = @_;

  my $this = $proto->SUPER::new( $dba, 'SO' );

  return $this;
}

1;