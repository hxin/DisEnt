# some doc here
#
#
#

=head1 NAME

Xin::utility

=cut

# Let the code begin...


package Xin::Utilities;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(getCurrentTime printDumper printHash);

use strict;
use DateTime;
use Data::Dumper;
use PadWalker;


sub getCurrentTime{
	return DateTime->now;
}

sub printDumper{
	print Dumper(@_);
}

sub printHash{
	my $hash_ref=shift @_;
	print $_." => ".$hash_ref->{$_}."\n" for(keys %{$hash_ref})
}

sub isExistInArray{
	my $str=shift @_;
	my @array=@{shift @_};
	
	my %temp = map { $_ => 1 } @array;
	if(exists($temp{$str})) { 
		return 1;	
	}else{
		return 0;
	}
}

sub getUnique{
	my @array=@{shift @_};
	my %hash;
	for my $item(@array){
		$hash{$item}=1;
	}
	my @unique=keys %hash;
	return @unique;
}


1;