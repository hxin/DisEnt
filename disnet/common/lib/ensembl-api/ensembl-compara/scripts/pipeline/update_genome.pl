#!/usr/local/ensembl/bin/perl -w
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

my $description = q{
###########################################################################
##
## PROGRAM update_genome.pl
##
## AUTHORS
##    Javier Herrero (jherrero@ebi.ac.uk)
##
## DESCRIPTION
##    This script takes the new core DB and a compara DB in production fase
##    and updates it in several steps:
##
##      - It updates the genome_db table
##      - It updates all the dnafrags for the given genome_db
##      - It updates all the collections for the given genome_db
##
###########################################################################

};

=head1 NAME

update_genome.pl

=head1 AUTHORS

 Javier Herrero (jherrero@ebi.ac.uk)


=head1 DESCRIPTION

This script takes the new core DB and a compara DB in production fase and updates it in several steps:

 - It updates the genome_db table
 - It updates all the dnafrags for the given genome_db

=head1 SYNOPSIS

perl update_genome.pl --help

perl update_genome.pl
    [--reg_conf registry_configuration_file]
    --compara compara_db_name_or_alias
    --species new_species_db_name_or_alias
    [--species_name "Species name"]
        Set up the species name. This is needed when the core database
        misses this information
    [--taxon_id 1234]
        Set up the NCBI taxon ID. This is needed when the core database
        misses this information
    [--[no]force]
        This scripts fails if the genome_db table of the compara DB
        already matches the new species DB. This options allows you
        to overcome this. USE ONLY IF YOU REALLY KNOW WHAT YOU ARE
        DOING!
    [--offset 1000]
        This allows you to offset identifiers assigned to Genome DBs by a given
        amount. If not specified we assume we will use the autoincrement key
        offered by the Genome DB table. If given then IDs will start
        from that number (and we will assign according to the current number
        of Genome DBs exceeding the offset). First ID will be equal to the
        offset+1
    [--collection "collection name"]
        Adds the new / updated genome_db_id to the collection. This option
        can be used multiple times

=head1 OPTIONS

=head2 GETTING HELP

=over

=item B<[--help]>

  Prints help message and exits.

=back

=head2 GENERAL CONFIGURATION

=over

=item B<[--reg_conf registry_configuration_file]>

The Bio::EnsEMBL::Registry configuration file. If none given,
the one set in ENSEMBL_REGISTRY will be used if defined, if not
~/.ensembl_init will be used.

=back

=head2 DATABASES

=over

=item B<--compara compara_db_name_or_alias>

The compara database to update. You can use either the original name or any of the
aliases given in the registry_configuration_file

=item B<--species new_species_db_name_or_alias>

The core database of the species to update. You can use either the original name or
any of the aliases given in the registry_configuration_file

=back

=head2 OPTIONS

=over

=item B<[--species_name "Species name"]>

Set up the species name. This is needed when the core database
misses this information

=item B<[--taxon_id 1234]>

Set up the NCBI taxon ID. This is needed when the core database
misses this information

=item B<[--[no]force]>

This scripts fails if the genome_db table of the compara DB
already matches the new species DB. This options allows you
to overcome this. USE ONLY IF YOU REALLY KNOW WHAT YOU ARE
DOING!

=item B<[--offset 1000]>

This allows you to offset identifiers assigned to Genome DBs by a given
amount. If not specified we assume we will use the autoincrement key
offered by the Genome DB table. If given then IDs will start
from that number (and we will assign according to the current number
of Genome DBs exceeding the offset). First ID will be equal to the
offset+1

=item B<[--collection "Collection name"]>

Adds the new / updated genome_db_id to the collection. This option
can be used multiple times

=back

=head1 INTERNAL METHODS

=cut

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::Exception qw(throw warning verbose);
use Getopt::Long;

my $usage = qq{
perl update_genome.pl

  Getting help:
    [--help]

  General configuration:
    [--reg_conf registry_configuration_file]
        the Bio::EnsEMBL::Registry configuration file. If none given,
        the one set in ENSEMBL_REGISTRY will be used if defined, if not
        ~/.ensembl_init will be used.
  Databases:
    --compara compara_db_name_or_alias
    --species new_species_db_name_or_alias

  Options:
    [--species_name "Species name"]
        Set up the species name. This is needed when the core database
        misses this information
    [--taxon_id 1234]
        Set up the NCBI taxon ID. This is needed when the core database
        misses this information
    [--[no]force]
        This scripts fails if the genome_db table of the compara DB
        already matches the new species DB. This options allows you
        to overcome this. USE ONLY IF YOU REALLY KNOW WHAT YOU ARE
        DOING!
    [--offset 1000]
        This allows you to offset identifiers assigned to Genome DBs by a given
        amount. If not specified we assume we will use the autoincrement key
        offered by the Genome DB table. If given then IDs will start
        from that number (and we will assign according to the current number
        of Genome DBs exceeding the offset). First ID will be equal to the
        offset+1
    [--collection "Collection name"]
        Adds the new / updated genome_db_id to the collection. This option
        can be used multiple times
};

my $help;

my $reg_conf;
my $compara;
my $species = "";
my $species_name;
my $taxon_id;
my $force = 0;
my $offset = 0;
my @collection = ();

GetOptions(
    "help" => \$help,
    "reg_conf=s" => \$reg_conf,
    "compara=s" => \$compara,
    "species=s" => \$species,
    "species_name=s" => \$species_name,
    "taxon_id=i" => \$taxon_id,
    "force!" => \$force,
    'offset=i' => \$offset,
    "collection=s@" => \@collection,
  );

$| = 0;

# Print Help and exit if help is requested
if ($help or !$species or !$compara) {
  print $description, $usage;
  exit(0);
}

my $species_no_underscores = $species;
$species_no_underscores =~ s/\_/\ /;

##
## Configure the Bio::EnsEMBL::Registry
## Uses $reg_conf if supplied. Uses ENV{ENSMEBL_REGISTRY} instead if defined. Uses
## ~/.ensembl_init if all the previous fail.
##
Bio::EnsEMBL::Registry->load_all($reg_conf);

my $species_db = Bio::EnsEMBL::Registry->get_DBAdaptor($species, "core");
if(! $species_db) {
    $species_db = Bio::EnsEMBL::Registry->get_DBAdaptor($species_no_underscores, "core");
}
throw ("Cannot connect to database [${species_no_underscores} or ${species}]") if (!$species_db);

my $compara_db = Bio::EnsEMBL::Registry->get_DBAdaptor($compara, "compara");
throw ("Cannot connect to database [$compara]") if (!$compara_db);

my $genome_db = update_genome_db($species_db, $compara_db, $force);
print "Bio::EnsEMBL::Compara::GenomeDB->dbID: ", $genome_db->dbID, "\n\n";

update_collections($compara_db, $genome_db, \@collection);

# delete_genomic_align_data($compara_db, $genome_db);

# delete_syntenic_data($compara_db, $genome_db);

update_dnafrags($compara_db, $genome_db, $species_db);

print_method_link_species_sets_to_update($compara_db, $genome_db);

exit(0);


=head2 update_genome_db

  Arg[1]      : Bio::EnsEMBL::DBSQL::DBAdaptor $species_dba
  Arg[2]      : Bio::EnsEMBL::Compara::DBSQL::DBAdaptor $compara_dba
  Arg[3]      : bool $force
  Description : This method takes all the information needed from the
                species database in order to update the genome_db table
                of the compara database
  Returns     : The new Bio::EnsEMBL::Compara::GenomeDB object
  Exceptions  : throw if the genome_db table is up-to-date unless the
                --force option has been activated

=cut

sub update_genome_db {
  my ($species_dba, $compara_dba, $force) = @_;

  my $slice_adaptor = $species_dba->get_adaptor("Slice");
  my $genome_db_adaptor = $compara_dba->get_GenomeDBAdaptor();
  my $meta_container = $species_dba->get_MetaContainer;

  my $species_production_name;
  if (defined($species_name)) {
    $species_production_name = $species_name;
  } else {
    $species_production_name = $meta_container->get_production_name();
    if (!$species_production_name) {
      throw "Cannot get the species name from the database. Use the --species_name option";
    }
  }
  my ($highest_cs) = @{$slice_adaptor->db->get_CoordSystemAdaptor->fetch_all()};
  my $primary_species_assembly = $highest_cs->version();
  my $genome_db = eval {$genome_db_adaptor->fetch_by_name_assembly(
          $species_production_name,
          $primary_species_assembly
      )};

  if ($genome_db and $genome_db->dbID) {
    if (not $force) {
      throw "GenomeDB with this name [$species_production_name] and assembly".
        " [$primary_species_assembly] is already in the compara DB [$compara]\n".
        "You can use the --force option IF YOU REALLY KNOW WHAT YOU ARE DOING!!";
    }
  } elsif ($force) {
    print "GenomeDB with this name [$species_production_name] and assembly".
        " [$primary_species_assembly] is not in the compara DB [$compara]\n".
        "You don't need the --force option!!";
    print "Press [Enter] to continue or Ctrl+C to cancel...";
    <STDIN>;
  }

	my $genebuild = $meta_container->get_genebuild();
	if (! $genebuild) {
			warning "Cannot find genebuild.version in meta table for $species_production_name";
			$genebuild = '';
	}

  print "New assembly and genebuild: ", join(" -- ", $primary_species_assembly, $genebuild),"\n\n";

  ## New genebuild!
  if ($genome_db) {

    $genome_db->genebuild( $genebuild );
    $genome_db_adaptor->update($genome_db);

  }
  ## New genome or new assembly!!
  else {

    if (!defined($taxon_id)) {
      $taxon_id = $meta_container->get_taxonomy_id();
    }
    if (!defined($taxon_id)) {
      throw "Cannot find species.taxonomy_id in meta table for $species_production_name.\n".
          "   You can use the --taxon_id option";
    }
    print "New genome in compara. Taxon #$taxon_id; Name: $species_production_name; Assembly $primary_species_assembly\n\n";

    $genome_db       = Bio::EnsEMBL::Compara::GenomeDB->new();
    $genome_db->taxon_id( $taxon_id );
    $genome_db->name( $species_production_name );
    $genome_db->assembly( $primary_species_assembly );
    $genome_db->genebuild( $genebuild );

    #New ID search if $offset is true

    if($offset) {
    	my $sth = $compara_dba->dbc->prepare('select max(genome_db_id) from genome_db where genome_db_id > ?');
    	$sth->execute($offset);
    	my ($max_id) = $sth->fetchrow_array();
    	$sth->finish();
    	if(!$max_id) {
    		$max_id = $offset;
    	}
      $genome_db->dbID($max_id + 1);
    }

    $genome_db_adaptor->store($genome_db);
  }
  return $genome_db;
}

=head2 update_collections

  Arg[1]      : Bio::EnsEMBL::Compara::DBSQL::DBAdaptor $compara_dba
  Arg[2]      : Bio::EnsEMBL::Compara::GenomeDB $genome_db
  Arg[3]      : Array reference of strings (the collections to add the species to)
  Description : This method updates all the collection species sets to
                include the new genome_db
  Returns     : -none-
  Exceptions  : throw if any SQL statment fails

=cut

sub update_collections {
  my ($compara_dba, $genome_db, $all_collections) = @_;

  # Gets all the collections with that genome_db
  my $sql = 'SELECT species_set_id FROM species_set_tag JOIN species_set USING (species_set_id) JOIN genome_db USING (genome_db_id) WHERE tag = "name" AND value LIKE "collection-%" AND name = ?';
  my $ss_ids = $compara_dba->dbc->db_handle->selectall_arrayref($sql, undef, $genome_db->name);

  my $ssa = $compara_dba->get_SpeciesSetAdaptor;
  my $sss = $ssa->fetch_all_by_dbID_list([map {$_->[0]} @$ss_ids]);

  foreach my $collection (@$all_collections) {
    my $all_ss = $ssa->fetch_all_by_tag_value("name", "collection-$collection");
    if (scalar(@$all_ss) == 0) {
      warn "cannot find the collection '$collection'";
    } elsif (scalar(@$all_ss) > 1) {
      warn "There are multiple collections '$collection'";
    } else {
      push @$sss, $all_ss->[0];
    }
  }

  foreach my $ss (@$sss) {
      my $ini_genome_dbs = $ss->genome_dbs;
      my $new_genome_dbs = [grep {$_->name ne $genome_db->name} @$ini_genome_dbs];
      push @$new_genome_dbs, $genome_db;
      my $species_set = Bio::EnsEMBL::Compara::SpeciesSet->new( -genome_dbs => $new_genome_dbs );
      $ssa->store($species_set);
      my $sql = 'UPDATE species_set_tag SET species_set_id = ? WHERE species_set_id = ? AND tag = "name"';
      my $sth = $compara_dba->dbc->prepare($sql);
      $sth->execute($species_set->dbID, $ss->dbID);
      $sth->finish();
  }
}

=head2 delete_genomic_align_data

  Arg[1]      : Bio::EnsEMBL::Compara::DBSQL::DBAdaptor $compara_dba
  Arg[2]      : Bio::EnsEMBL::Compara::GenomeDB $genome_db
  Description : This method deletes from the genomic_align and 
                genomic_align_block tables
                all the rows that refer to the species identified
                by the $genome_db_id
  Returns     : -none-
  Exceptions  : throw if any SQL statment fails

=cut

sub delete_genomic_align_data {
  my ($compara_dba, $genome_db) = @_;

  print "Getting the list of genomic_align_block_id to remove... ";
  my $rows = $compara_dba->dbc->do(qq{
      CREATE TABLE list AS
          SELECT genomic_align_block_id
          FROM genomic_align_block, method_link_species_set
          WHERE genomic_align_block.method_link_species_set_id = method_link_species_set.method_link_species_set_id
          AND genome_db_id = $genome_db->{dbID}
    });
  throw $compara_dba->dbc->errstr if (!$rows);
  print "$rows elements found.\n";

  print "Deleting corresponding genomic_align and genomic_align_block rows...";
  $rows = $compara_dba->dbc->do(qq{
      DELETE
        genomic_align, genomic_align_block
      FROM
        list
        LEFT JOIN genomic_align_block USING (genomic_align_block_id)
        LEFT JOIN genomic_align USING (genomic_align_block_id)
      WHERE
        list.genomic_align_block_id = genomic_align.genomic_align_block_id
    });
  throw $compara_dba->dbc->errstr if (!$rows);
  print " ok!\n";

  print "Droping the list of genomic_align_block_ids...";
  $rows = $compara_dba->dbc->do(qq{DROP TABLE list});
  throw $compara_dba->dbc->errstr if (!$rows);
  print " ok!\n\n";
}

=head2 delete_syntenic_data

  Arg[1]      : Bio::EnsEMBL::Compara::DBSQL::DBAdaptor $compara_dba
  Arg[2]      : Bio::EnsEMBL::Compara::GenomeDB $genome_db
  Description : This method deletes from the dnafrag_region
                and synteny_region tables all the rows that refer
                to the species identified by the $genome_db_id
  Returns     : -none-
  Exceptions  : throw if any SQL statment fails

=cut

sub delete_syntenic_data {
  my ($compara_dba, $genome_db) = @_;

  print "Deleting dnafrag_region and synteny_region rows...";
  my $rows = $compara_dba->dbc->do(qq{
      DELETE
        dnafrag_region, synteny_region
      FROM
        dnafrag_region
        LEFT JOIN synteny_region USING (synteny_region_id)
        LEFT JOIN method_link_species_set USING (method_link_species_set_id)
      WHERE genome_db_id = $genome_db->{dbID}
    });
  throw $compara_dba->dbc->errstr if (!$rows);
  print " ok!\n\n";
}

=head2 update_dnafrags

  Arg[1]      : Bio::EnsEMBL::Compara::DBSQL::DBAdaptor $compara_dba
  Arg[2]      : Bio::EnsEMBL::Compara::GenomeDB $genome_db
  Arg[3]      : Bio::EnsEMBL::DBSQL::DBAdaptor $species_dba
  Description : This method fetches all the dnafrag in the compara DB
                corresponding to the $genome_db. It also gets the list
                of top_level seq_regions from the species core DB and
                updates the list of dnafrags in the compara DB.
  Returns     : -none-
  Exceptions  :

=cut

sub update_dnafrags {
  my ($compara_dba, $genome_db, $species_dba) = @_;

  my $dnafrag_adaptor = $compara_dba->get_adaptor("DnaFrag");
  my $old_dnafrags = $dnafrag_adaptor->fetch_all_by_GenomeDB_region($genome_db);
  my $old_dnafrags_by_id;
  foreach my $old_dnafrag (@$old_dnafrags) {
    $old_dnafrags_by_id->{$old_dnafrag->dbID} = $old_dnafrag;
  }

  my $sql1 = qq{
      SELECT
        cs.name,
        sr.name,
        sr.length
      FROM
        coord_system cs,
        seq_region sr,
        seq_region_attrib sra,
        attrib_type at
      WHERE
        sra.attrib_type_id = at.attrib_type_id
        AND at.code = 'toplevel'
        AND sr.seq_region_id = sra.seq_region_id
        AND sr.coord_system_id = cs.coord_system_id
        AND cs.name != "lrg"
        AND cs.species_id =?
    };
  my $sth1 = $species_dba->dbc->prepare($sql1);
  $sth1->execute($species_dba->species_id());
  my $current_verbose = verbose();
  verbose('EXCEPTION');
  while (my ($coordinate_system_name, $name, $length) = $sth1->fetchrow_array) {

    #Find out if region is_reference or not
    my $slice = $species_dba->get_SliceAdaptor->fetch_by_region($coordinate_system_name,$name);
    my $is_reference = $slice->is_reference;

    my $new_dnafrag = new Bio::EnsEMBL::Compara::DnaFrag(
            -genome_db => $genome_db,
            -coord_system_name => $coordinate_system_name,
            -name => $name,
            -length => $length,
            -is_reference => $is_reference
        );
    my $dnafrag_id = $dnafrag_adaptor->update($new_dnafrag);
    delete($old_dnafrags_by_id->{$dnafrag_id});
    throw() if ($old_dnafrags_by_id->{$dnafrag_id});
  }
  verbose($current_verbose);
  print "Deleting ", scalar(keys %$old_dnafrags_by_id), " former DnaFrags...";
  foreach my $deprecated_dnafrag_id (keys %$old_dnafrags_by_id) {
    $compara_dba->dbc->do("DELETE FROM dnafrag WHERE dnafrag_id = ".$deprecated_dnafrag_id) ;
  }
  print "  ok!\n\n";
}

=head2 print_method_link_species_sets_to_update

  Arg[1]      : Bio::EnsEMBL::Compara::DBSQL::DBAdaptor $compara_dba
  Arg[2]      : Bio::EnsEMBL::Compara::GenomeDB $genome_db
  Description : This method prints all the genomic MethodLinkSpeciesSet
                that need to be updated (those which correspond to the
                $genome_db).
                NB: Only method_link with a dbID <200 are taken into
                account (they should be the genomic ones)
  Returns     : -none-
  Exceptions  :

=cut

sub print_method_link_species_sets_to_update {
  my ($compara_dba, $genome_db) = @_;

  my $method_link_species_set_adaptor = $compara_dba->get_adaptor("MethodLinkSpeciesSet");
  my $genome_db_adaptor = $compara_dba->get_adaptor("GenomeDB");

  my $method_link_species_sets;
  foreach my $this_genome_db (@{$genome_db_adaptor->fetch_all()}) {
    next if ($this_genome_db->name ne $genome_db->name);
    foreach my $this_method_link_species_set (@{$method_link_species_set_adaptor->fetch_all_by_GenomeDB($this_genome_db)}) {
      $method_link_species_sets->{$this_method_link_species_set->method->dbID}->
          {join("-", sort map {$_->name} @{$this_method_link_species_set->species_set_obj->genome_dbs})} = $this_method_link_species_set;
    }
  }

  print "List of Bio::EnsEMBL::Compara::MethodLinkSpeciesSet to update:\n";
  foreach my $this_method_link_id (sort {$a <=> $b} keys %$method_link_species_sets) {
    last if ($this_method_link_id > 200); # Avoid non-genomic method_link_species_set
    foreach my $this_method_link_species_set (values %{$method_link_species_sets->{$this_method_link_id}}) {
      printf "%8d: ", $this_method_link_species_set->dbID,;
      print $this_method_link_species_set->method->type, " (",
          join(",", map {$_->name} @{$this_method_link_species_set->species_set_obj->genome_dbs}), ")\n";
    }
  }

}

=head2 create_new_method_link_species_sets

  Arg[1]      : Bio::EnsEMBL::Compara::DBSQL::DBAdaptor $compara_dba
  Arg[2]      : Bio::EnsEMBL::Compara::GenomeDB $genome_db
  Description : This method creates all the genomic MethodLinkSpeciesSet
                that are needed for the new assembly.
                NB: Only method_link with a dbID <200 are taken into
                account (they should be the genomic ones)
  Returns     : -none-
  Exceptions  :

=cut

sub create_new_method_link_species_sets {
  my ($compara_dba, $genome_db) = @_;

  my $method_link_species_set_adaptor = $compara_dba->get_adaptor("MethodLinkSpeciesSet");
  my $genome_db_adaptor = $compara_dba->get_adaptor("GenomeDB");

  my $method_link_species_sets;
  my $all_genome_dbs = $genome_db_adaptor->fetch_all();
  foreach my $this_genome_db (@$all_genome_dbs) {
    next if ($this_genome_db->name ne $genome_db->name);
    foreach my $this_method_link_species_set (@{$method_link_species_set_adaptor->fetch_all_by_GenomeDB($this_genome_db)}) {
      $method_link_species_sets->{$this_method_link_species_set->method->dbID}->
          {join("-", sort map {$_->name} @{$this_method_link_species_set->species_set_obj->genome_dbs})} = $this_method_link_species_set;
    }
  }

  print "List of Bio::EnsEMBL::Compara::MethodLinkSpeciesSet to update:\n";
  foreach my $this_method_link_id (sort {$a <=> $b} keys %$method_link_species_sets) {
    last if ($this_method_link_id > 200); # Avoid non-genomic method_link_species_set
    foreach my $this_method_link_species_set (values %{$method_link_species_sets->{$this_method_link_id}}) {
      printf "%8d: ", $this_method_link_species_set->dbID,;
      print $this_method_link_species_set->method->type, " (",
          join(",", map {$_->name} @{$this_method_link_species_set->species_set_obj->genome_dbs}), ")\n";
    }
  }

}
