package Palm::Timesheet::PreferenceRecord;
$VERSION= 1.00;
use strict;
use Carp;
use vars '$AUTOLOAD';
use Palm::Timesheet::Utilities;

=head1 NAME 

Palm::Timesheet::PreferenceRecord -  Stores the preferences ...

=head1 SYNOPSIS

        get/set_numclientcategories
        get/set_numprojectcategories
        get/set_numtaskcategories 
        get/set_defaultclientindex
        get/set_defaultprojectindex
        get/set_defaulttaskindex 
        get/set_marknewentriesaschargeable( 1|0 )
        get/set_autoduration_hour
        get/set_autoduration_min
        get/set_autoduration( 1|0 )
        get/set_autocategories( 1|0 )
        get/set_underlinechargeable( 1|0 )
        get/set_shortdateformat( 1|0 )

=head1 COPYRIGHT
 
Copyright (c) 2001, Johan Van den Brande. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.  

=cut

{

	my %_attributes = (
		numclientcategories		=> undef,
		numprojectcategories		=> undef,
		numtaskcategories		=> undef,
		defaultclientindex		=> undef,
		defaultprojectindex		=> undef,
		defaulttaskindex		=> undef,
		marknewentriesaschargeable	=> undef,
		autoduration_hour			=> undef,
		autoduration_min			=> undef,
		autoduration			=> undef,
		autocategories			=> undef,
		underlinechargeable		=> undef,
		shortdateformat			=> undef
		);

sub get_attributes { keys %_attributes; }

sub new 
{
	my ($proto, %args ) = @_;
	my $class = ref($proto) || $proto;

	my $self = { };

	foreach my $_attr ( keys %_attributes ) {
		if ( exists($args{$_attr}) )	 {
			$self->{$_attr} = $args{$_attr};
		} else {
			$self->{$_attr} = $_attributes{$_attr};
		}
	}
	bless $self, $class;
}

sub from_record
{
	my ($proto, $record) = @_;
	my $class = ref($proto) || $proto;

	my $self = {};
	bless $self, $class;

	my @pref_bytes = split //, $record;
	$self->set_numclientcategories( unpack( "C", $pref_bytes[0] ) );
	$self->set_numprojectcategories( unpack( "C", $pref_bytes[1] ) );
	$self->set_numtaskcategories( unpack( "C", $pref_bytes[2] ) );
	$self->set_defaultclientindex( unpack( "C", $pref_bytes[3] ) );
	$self->set_defaultprojectindex( unpack( "C", $pref_bytes[4] ) );
	$self->set_defaulttaskindex( unpack( "C", $pref_bytes[5] ) );
	my $pref_flag = unpack("C", $pref_bytes[6] );
	
	$self->set_marknewentriesaschargeable( ( $pref_flag & 0x10 ) >> 4 );
	$self->set_autoduration( ( $pref_flag & 0x08 ) >> 3 );
	$self->set_autocategories( ( $pref_flag & 0x04 ) >> 2 );
	$self->set_underlinechargeable( ( $pref_flag & 0x02 ) >> 1 );
	$self->set_shortdateformat( ( $pref_flag & 0x01 ) >> 0 ); 

	my ( $auto_duration_hour, $auto_duration_min) = 
		record_to_hour_min( unpack( "C", $pref_bytes[7] ) );

	$self->set_autoduration_hour( $auto_duration_hour );
	$self->set_autoduration_min( $auto_duration_min );

	return $self;
}

}


sub pack
{
	my $self = shift;
	my $record;	
	
	$record .= pack( "C", $self->get_numclientcategories() );
	$record .= pack( "C", $self->get_numprojectcategories() );
	$record .= pack( "C", $self->get_numtaskcategories() );
	$record .= pack( "C", $self->get_defaultclientindex() );
	$record .= pack( "C", $self->get_defaultprojectindex() );
	$record .= pack( "C", $self->get_defaulttaskindex() );

	my $flag;	
	$flag |= $self->get_marknewentriesaschargeable() << 4;
	$flag |= $self->get_autoduration() << 3;
	$flag |= $self->get_autocategories() << 2;
	$flag |= $self->get_underlinechargeable() << 1;
	$flag |= $self->get_shortdateformat(); 
	$record .= pack( "C", $flag );

	$record .= pack( "C",
				hour_min_to_record(
					$self->get_autoduration_hour(),
					$self->get_autoduration_min()
				)
			   );
	$record .= pack( "C", 0 ) x 6;
	return $record;
}

sub AUTOLOAD
{
	my ($self, $newval) = @_;

	$AUTOLOAD =~ /.*::get_(\w+)/ and return $self->{$1};
	$AUTOLOAD =~ /.*::set_(\w+)/ and do { $self->{$1} = $newval; return; };

	croak "No such method: $AUTOLOAD";
}
1;
