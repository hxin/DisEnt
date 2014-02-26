# Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp qw/tempfile/;
use Bio::EnsEMBL::Utils::IO qw/:all/;
use IO::String;

my ($tmp_fh, $file) = tempfile();
close($tmp_fh);
unlink $file;


my $contents = <<'EOF';
>X
AAAAGGGTTCCC
TTGGCCAAAAAA
ATTC
EOF

my $expected_array = [qw/>X AAAAGGGTTCCC TTGGCCAAAAAA ATTC/];

{
  throws_ok { slurp($file) } qr/No such file/, 'File does not currently exist so die';
  
  work_with_file($file, 'w', sub {
    my ($fh) = @_;
    print $fh $contents;
    return;
  });
  
  my $written_contents = slurp($file);
  is($contents, $written_contents, 'Contents should be the same');
  
  my $written_contents_ref = slurp($file, 1);
  is('SCALAR', ref($written_contents_ref), 'Asked for a ref so expect one back');
  is($contents, $$written_contents_ref, 'Contents should be the same');
  
  work_with_file($file, 'r', sub {
    my ($fh) = @_;
    my $line = <$fh>;
    chomp($line);
    is($line, '>X', 'First line expected to be FASTA header'); 
  });
  
  my $chomp = 1;
  is_deeply(slurp_to_array($file, $chomp), $expected_array, 'Checking slurp to array with chomp');
  $chomp = 0;
  is_deeply(slurp_to_array($file, $chomp), [ map { $_."\n" } @{$expected_array}], 'Checking slurp to array with chomp');

  my $iterator_counter = 0;  
  iterate_file($file, sub {
    my ($line) = @_;
    chomp($line);
    is($line, $expected_array->[$iterator_counter++], sprintf('Checking line %d is ok', $iterator_counter+1));
    return;
  });
  
  unlink $file;
  
  dies_ok { slurp($file) } 'File no longer exists so die';

}

{
  my $content = 'ABCDE1198473' x 33012;
  my $src = IO::String->new($content);
  
  {
    my $trg = IO::String->new();
    move_data($src, $trg);
    is(${$trg->string_ref()}, $content, 'Checking copied data is as expected');
  }
  
  {
    $src->setpos(0);
    my $trg = IO::String->new();
    move_data($src, $trg, (8*1024*1024)); #8MB
    is(${$trg->string_ref()}, $content, 'Checking large buffer copied data is as expected');
  }
}

{
  gz_work_with_file($file, 'w', sub {
    my ($fh) = @_;
    print $fh $contents;
    return;
  });
  
  my $written_contents = gz_slurp($file);
  is($contents, $written_contents, 'Gzipped Contents should be the same');
  my $non_gz_written_contents = slurp($file);
  isnt($contents, $non_gz_written_contents, 'Reading normally should not return the same contents');
  
  my $chomp = 1;
  is_deeply(gz_slurp_to_array($file, $chomp), $expected_array, 'Checking slurp to array with chomp');
  $chomp = 0;
  is_deeply(gz_slurp_to_array($file, $chomp), [ map { $_."\n" } @{$expected_array}], 'Checking slurp to array with chomp');
  
  unlink $file;
  
  dies_ok { slurp($file) } 'File no longer exists so die';
}

done_testing();
