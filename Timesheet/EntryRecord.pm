package Palm::Timesheet::EntryRecord;
$VERSION= 1.00;
use strict;
use Carp;
use Palm::Timesheet::Utilities;
use vars '$AUTOLOAD';

=head1 NAME 

Palm::Timesheet::EntryRecord - A Timesheet record entry

=head1 DESCRIPTION

Encapsulates a timesheet record. Access is allowed with some getters
and setters. You can also create a new() record from scratch or
rely upon a PDB record to create one from.

=head2 Constructors

=over 4

=item new( %args )

Create a new record with the following arguments:

	my %args = {
		client => $index_in_client_list,
		project => $index_in_project_list,
		task => $index_in_task_list,
		hour => 2,
		min => 30,
		comment => 'A lot of work, that documenting!',
		chargeable => 1
	};

=item from_record( $record )

Create one from a PDB record

=back

=head2 Other methods

=over 4

=item get/set_client

=item get/set_project

=item get/set_task

=item get/set_hour

=item get/set_min

=item get/set_comment

=item get/set_chargeable

=item pack

Serialize into a PDB record.

=back

=head1 COPYRIGHT
 
Copyright (c) 2001, Johan Van den Brande. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.  

=cut

{

	my %_attributes = (
		client		=> undef,
		project		=> undef,
		task		=> undef,
		hour		=> undef,
		min		=> undef,
		numentries	=> undef,
		comment		=> undef,
		chargeable	=> undef 
		);


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
	my ($proto, $entry) = @_;
	my $class = ref($proto) || $proto;

	my $self = {};
	bless $self, $class;

	my $record = $entry->{data};
	chop ($record);
	my @record = split //, $record;
	$self->set_client( unpack("C", $record[0]) );
	$self->set_project( unpack("C", $record[1]) );
	$self->set_task( unpack("C", $record[2]) );
	my ($entry_hour, $entry_min) = 
		record_to_hour_min( unpack("C", $record[3]) );
	$self->set_hour( $entry_hour );
	$self->set_min( $entry_min );
	$self->set_numentries( 	unpack("C", $record[4]) );
	$self->set_comment( join("", @record[6..$#record]) );
	$self->set_chargeable( (($entry->{"category"} & 0x08)?1:0) );

	return $self;
}

}

sub pack
{
	my $self = shift;
	my $record;

	$record .= pack( "C", $self->get_client );
	$record .= pack( "C", $self->get_project );
	$record .= pack( "C", $self->get_task );
	$record .= pack( "C", hour_min_to_record(
			$self->get_hour,
			$self->get_min)
			);
	$record .= pack( "C", $self->get_numentries );
	$record .= pack( "C", 0 );
	$record .= $self->get_comment;
				
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
