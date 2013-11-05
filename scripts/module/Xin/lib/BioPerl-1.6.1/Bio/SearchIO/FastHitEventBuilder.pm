# $Id: FastHitEventBuilder.pm 16123 2009-09-17 12:57:27Z cjfields $
#
# BioPerl module for Bio::SearchIO::FastHitEventBuilder
#
# Please direct questions and support issues to <bioperl-l@bioperl.org> 
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::SearchIO::FastHitEventBuilder - Event Handler for SearchIO events.

=head1 SYNOPSIS

  # Do not use this object directly, this object is part of the SearchIO
  # event based parsing system.

  # to use the FastHitEventBuilder do this

  use Bio::SearchIO::FastHitEventBuilder;

  my $searchio = Bio::SearchIO->new(-format => $format, -file => $file);

  $searchio->attach_EventHandler(Bio::SearchIO::FastHitEventBuilder->new());

  while( my $r = $searchio->next_result ) {
   while( my $h = $r->next_hit ) {
    # note that Hits will NOT have HSPs
   }
  }

=head1 DESCRIPTION

This object handles Search Events generated by the SearchIO classes
and build appropriate Bio::Search::* objects from them.  This object
is intended for lightweight parsers which only want Hits and not deal
with the overhead of HSPs.  It is a lot faster than the standard
parser event handler but of course you are getting less information
and less objects out.


=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Support 

Please direct usage questions or support issues to the mailing list:

I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and 
reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem 
with code and data examples if at all possible.

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via the
web:

  http://bugzilla.open-bio.org/

=head1 AUTHOR - Jason Stajich

Email jason-at-bioperl.org

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::SearchIO::FastHitEventBuilder;
use vars qw(%KNOWNEVENTS);
use strict;

use Bio::Search::HSP::HSPFactory;
use Bio::Search::Hit::HitFactory;
use Bio::Search::Result::ResultFactory;

use base qw(Bio::Root::Root Bio::SearchIO::EventHandlerI);

=head2 new

 Title   : new
 Usage   : my $obj = Bio::SearchIO::FastHitEventBuilder->new();
 Function: Builds a new Bio::SearchIO::FastHitEventBuilder object 
 Returns : Bio::SearchIO::FastHitEventBuilder
 Args    : -hit_factory    => Bio::Factory::ObjectFactoryI
           -result_factory => Bio::Factory::ObjectFactoryI

See L<Bio::Factory::ObjectFactoryI> for more information

=cut

sub new { 
    my ($class,@args) = @_;
    my $self = $class->SUPER::new(@args);
    my ($hitF,$resultF) = $self->_rearrange([qw(HIT_FACTORY
						      RESULT_FACTORY)],@args);
    $self->register_factory('hit', $hitF ||
                            Bio::Factory::ObjectFactory->new(
                                      -type      => 'Bio::Search::Hit::GenericHit',
                                      -interface => 'Bio::Search::Hit::HitI'));

    $self->register_factory('result', $resultF ||
                            Bio::Factory::ObjectFactory->new(
                                      -type      => 'Bio::Search::Result::GenericResult',
                                      -interface => 'Bio::Search::Result::ResultI'));

    return $self;
}

# new comes from the superclass

=head2 will_handle

 Title   : will_handle
 Usage   : if( $handler->will_handle($event_type) ) { ... }
 Function: Tests if this event builder knows how to process a specific event
 Returns : boolean
 Args    : event type name


=cut

sub will_handle{
   my ($self,$type) = @_;
   # these are the events we recognize
   return ( $type eq 'hit' || $type eq 'result' );
}

=head2 SAX methods

=cut

=head2 start_result

 Title   : start_result
 Usage   : $handler->start_result($resulttype)
 Function: Begins a result event cycle
 Returns : none 
 Args    : Type of Report

=cut

sub start_result {
   my ($self,$type) = @_;
   $self->{'_resulttype'} = $type;
   $self->{'_hits'} = [];
   return;
}

=head2 end_result

 Title   : end_result
 Usage   : my @results = $parser->end_result
 Function: Finishes a result handler cycle Returns : A Bio::Search::Result::ResultI
 Args    : none

=cut

sub end_result {
    my ($self,$type,$data) = @_;    
    if( defined $data->{'runid'} &&
	$data->{'runid'} !~ /^\s+$/ ) {	
	
	if( $data->{'runid'} !~ /^lcl\|/) { 
	    $data->{"RESULT-query_name"}= $data->{'runid'};
	} else { 
	    ($data->{"RESULT-query_name"},$data->{"RESULT-query_description"}) = split(/\s+/,$data->{"RESULT-query_description"},2);
	}
	
	if( my @a = split(/\|/,$data->{'RESULT-query_name'}) ) {
	    my $acc = pop @a ; # this is for accession |1234|gb|AAABB1.1|AAABB1
	    # this is for |123|gb|ABC1.1|
	    $acc = pop @a if( ! defined $acc || $acc =~ /^\s+$/);
	    $data->{"RESULT-query_accession"}= $acc;
	}
	delete $data->{'runid'};
    }
    my %args = map { my $v = $data->{$_}; s/RESULT//; ($_ => $v); } 
               grep { /^RESULT/ } keys %{$data};
    
    $args{'-algorithm'} =  uc( $args{'-algorithm_name'} || $type);
    $args{'-hits'}      =  $self->{'_hits'};
    my $result = $self->factory('result')->create(%args);
    $self->{'_hits'} = [];
    return $result;
}

=head2 start_hit

 Title   : start_hit
 Usage   : $handler->start_hit()
 Function: Starts a Hit event cycle
 Returns : none
 Args    : type of event and associated hashref


=cut

sub start_hit{
    my ($self,$type) = @_;
    return;
}


=head2 end_hit

 Title   : end_hit
 Usage   : $handler->end_hit()
 Function: Ends a Hit event cycle
 Returns : Bio::Search::Hit::HitI object
 Args    : type of event and associated hashref


=cut

sub end_hit{
    my ($self,$type,$data) = @_;   
    my %args = map { my $v = $data->{$_}; s/HIT//; ($_ => $v); } grep { /^HIT/ } keys %{$data};
    $args{'-algorithm'} =  uc( $args{'-algorithm_name'} || $type);
    $args{'-query_len'} =  $data->{'RESULT-query_length'};
    my ($hitrank) = scalar @{$self->{'_hits'}} + 1;
    $args{'-rank'} = $hitrank;
    my $hit = $self->factory('hit')->create(%args);
    push @{$self->{'_hits'}}, $hit;
    $self->{'_hsps'} = [];
    return $hit;
}

=head2 Factory methods

=cut

=head2 register_factory

 Title   : register_factory
 Usage   : $handler->register_factory('TYPE',$factory);
 Function: Register a specific factory for a object type class
 Returns : none
 Args    : string representing the class and
           Bio::Factory::ObjectFactoryI

See L<Bio::Factory::ObjectFactoryI> for more information

=cut

sub register_factory{
   my ($self, $type,$f) = @_;
   if( ! defined $f || ! ref($f) || 
       ! $f->isa('Bio::Factory::ObjectFactoryI') ) { 
       $self->throw("Cannot set factory to value $f".ref($f)."\n");
   }
   $self->{'_factories'}->{lc($type)} = $f;
}


=head2 factory

 Title   : factory
 Usage   : my $f = $handler->factory('TYPE');
 Function: Retrieves the associated factory for requested 'TYPE'
 Returns : a Bio::Factory::ObjectFactoryI or undef if none registered
 Args    : name of factory class to retrieve

See L<Bio::Factory::ObjectFactoryI> for more information

=cut

sub factory{
   my ($self,$type) = @_;
   return $self->{'_factories'}->{lc($type)} || $self->throw("No factory registered for $type");
}

=head2 inclusion_threshold

See L<Bio::SearchIO::blast::inclusion_threshold>.

=cut

sub inclusion_threshold {
    my $self = shift;
    return $self->{'_inclusion_threshold'} = shift if @_;
    return $self->{'_inclusion_threshold'};
}

1;
