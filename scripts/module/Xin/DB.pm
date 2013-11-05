# some doc here
#
#
#

=head1 NAME

Xin::DB

=cut

# Let the code begin...


package Xin::DB;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();

use strict;
use DBI;


=head2 connectNRG

 Title   : connectNRG
 Usage   : my $dnh = connectNRG
 Returns : db handle

=cut

sub connectNRG {
		my $dsn  = 'dbi:mysql:variation:nrg.inf.ed.ac.uk:3306';
		my $user = 'xin';
		my $pass = '12091209';
		my $dbh  = DBI->connect( $dsn, $user, $pass ,{ RaiseError => 1, AutoCommit => 1 }) or die $DBI::errstr;
		return $dbh;
	}


sub selctAllFromTable{
	my ($dbh,$tableName)=@_;
	my $sth = $dbh->prepare('select * from'."`$tableName`");
	my  @result = @{ $dbh->selectall_arrayref($sth, { Slice => {} }) };
	return @result;
}

sub printTable{
	my ($dbh,$tableName)=@_;
	my $sth = $dbh->prepare('select * from'."`$tableName`");
	my  @result = @{ $dbh->selectall_arrayref($sth, { Slice => {} }) };
	foreach my $row_hashref (@result){
		print  "$_->".$row_hashref->{$_}."\t" for (keys %{$row_hashref});
		print "\n";
	}
	
}

 
1;