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
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::ApiVersion;

use Bio::EnsEMBL::DataFile;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new();
my $db = $multi->get_DBAdaptor( 'core' );

$multi->hide('core', 'data_file');

my $dfa = $db->get_DataFileAdaptor();
isa_ok($dfa, 'Bio::EnsEMBL::DBSQL::DataFileAdaptor', 'Checking DataFileAdaptor instance');

my $csa = $db->get_CoordSystemAdaptor();
my $aa = $db->get_AnalysisAdaptor();

my $base = '/tmp';
my $expected_base = $base.'/homo_sapiens/NCBI33';
my $cs = $csa->fetch_by_dbID(1);
my $a = $aa->fetch_by_dbID(1);

my %base_args = (
  -COORD_SYSTEM => $cs,
  -ANALYSIS => $a,
  -NAME => 'wibble',
  -VERSION_LOCK => 0,
  -ABSOLUTE => 0,
  -URL => undef,
  -FILE_TYPE => 'BAM',
  -ADAPTOR => $dfa
);

{
  my $df = new_ok('Bio::EnsEMBL::DataFile' => [
    %base_args
  ], 'data file');
  is($df->path($base), $expected_base.'/core/wibble.bam', 'Checking non-absolute path');
  is_deeply($df->get_all_paths($base), [ $expected_base.'/core/wibble.bam', $expected_base.'/core/wibble.bam.bai' ], 'Checking all non-abs paths');
}

{
  my $df = new_ok('Bio::EnsEMBL::DataFile' => [
    %base_args,
    -VERSION_LOCK => 1,
  ], 'data file');
  
  is($df->path($base), $expected_base.'/'.software_version().'/core/wibble.bam', 'Checking non-absolute version locked path');
}

{
  my $url = 'http://www.google.co.uk/wibble.bam';
  my $df = new_ok('Bio::EnsEMBL::DataFile' => [
    %base_args,
    -ABSOLUTE => 1,
    -URL => $url
  ], 'data file');
  
  is($df->path(), $url, 'Checking absolute path');
}

{
  my $supercontig_cs = $csa->fetch_by_dbID(2);
  my $df = new_ok('Bio::EnsEMBL::DataFile' => [
    %base_args,
    -COORD_SYSTEM => $supercontig_cs
  ], 'data file');
  is($df->path($base), $expected_base.'/core/wibble.bam', 'Checking non-absolute unversioned cs path');
}

{
  my %exts = (BAM => ['bam', 'bam.bai'], BIGWIG => ['bw'], VCF => ['vcf.gz', 'vcf.gz.tbi']);
  while( my ($type, $ext) = each %exts ) {
    is_deeply($dfa->DataFile_to_extensions(new_ok('Bio::EnsEMBL::DataFile'=>[%base_args, -FILE_TYPE => $type])), $ext, 'Checking '.$type.' extension');
  }
}

{
  my %local_args = %base_args;
  delete $local_args{-ADAPTOR};
  my $df = new_ok('Bio::EnsEMBL::DataFile' => [ %local_args ], 'data file');
  $dfa->store($df);
  cmp_ok($df->dbID(), '>=', 1, 'Checking it was assigned an ID higher than 1');
  is_deeply($dfa->fetch_by_dbID($df->dbID()), $df, 'Checking retrieved data is the same as what we currently hold');
  
  $df->absolute(1);
  $dfa->update($df);
  is_deeply($dfa->fetch_by_dbID($df->dbID()), $df, 'Checking retrieved data is the same as what we currently hold');
  
  is_deeply($dfa->fetch_all_by_Analysis($a), [$df], 'Checking retrieved data is the same as what we currently hold');
  is_deeply($dfa->fetch_all_by_CoordSystem($cs), [$df], 'Checking retrieved data is the same as what we currently hold');
  is_deeply($dfa->fetch_by_name_and_type('wibble', 'BAM'), $df, 'Checking retrieved data is the same as what we currently hold');    
}

$multi->restore();

done_testing();