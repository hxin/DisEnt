# some doc here
#
#
#

=head1 NAME

Xin::DO

=cut

# Let the code begin...

package Xin::OMIM;

use Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw();


use strict;
use Data::Dumper;

sub description2id{
	my ($dbh,$term)=@_;
	my $sth = $dbh->prepare("SELECT distinct disorder_mim_acc,locus_mim_acc FROM xin2.OMIM_disease2gene where description=?;");
	$sth->execute($term);
	my @row = $sth->fetchrow_array;
	return $row[0]? $row[0]:$row[1]; 
}

1;
