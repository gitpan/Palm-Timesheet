package Palm::Timesheet::DayRecord;
$VERSION= 1.00;
use strict;
use base qw( Palm::Timesheet::List );
use Carp;
use vars '$AUTOLOAD';

=head1 NAME 

Palm::Timesheet::DayRecord - A Day record entry

=head1 SYNOPSIS
	
	use Palm::Timesheet::DayRecordList;
	use Palm::Timesheet::DayRecord;

	my $daylist = Palm::Timesheet::DayRecordList->new();

	...

	my $day = Palm::Timesheet::DayRecord->from_record( $data );

	$daylist->push( $day );  

=head1 DESCRIPTION

Contains a Day record entry with the following methods

=head2 Constructors

=over 4

=item new

=item from_record

=back

=head2 Methods

=over 4

=item pack

Serialize

=item delete

Delete a $record from the list.

=item add_entry

Add a day

=item get/set_day

=back

=head1 COPYRIGHT
 
Copyright (c) 2001, Johan Van den Brande. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.  

=cut

{

	my %_attributes = (
		day		=> undef,
		numentries	=> undef
		);


sub new 
{
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = $class->SUPER::new( @_ );
	my %args = @_;

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

	my $self = $class->SUPER::new();
	bless $self, $class;

	$self->set_numentries( unpack( "C", substr($record, 0, 1) ) );
	my $bits = unpack( "N", $record ) & 0x00FFFFFF;
	$self->set_day( sprintf("%04d-%02d-%02d",
				(( $bits >> 9 ) & 0x7F) +1920 ,
				(( $bits >> 5 ) & 0x0F),
				 $bits & 0x1F 
				)
		       );
		
	return $self;
}

}

sub pack
{
	my $self = shift;
	my $record;
	
	my $date = $self->get_day();
	$date =~ /(\d{4})-(\d{2})-(\d{2})/;
	my ( $year, $month, $day ) = ( $1, $2, $3 );

	my $temp = 	$self->get_numentries() << 24 
			|
			0xC6 << 16
			|
			( $year - 1920 ) << 9
			|
			$month  << 5
			|
			$day;
	my @temp = split //, $temp;
	
	$record = pack( "N", $temp );
	return $record;
}

sub delete 
{
	my ($self, $record) = @_;

	if ( $self->SUPER::delete( $record ) ) {
		$self->set_numentries( $self->get_numentries - 1 );

		# renumber rest of entries
		my $num = 1;
		while (my $e = $self->each) {
		 	$e->set_numentries( $num++ );
		}
	}
}

sub add_entry
{
	my ($self, $record) = @_;

	$self->SUPER::push( $record );
	$self->set_numentries( $self->get_numentries + 1 );
	$record->set_numentries( $self->get_numentries );	
}

sub AUTOLOAD
{
	my ($self, $newval) = @_;

	$AUTOLOAD =~ /.*::get_(\w+)/ and return $self->{$1};
	$AUTOLOAD =~ /.*::set_(\w+)/ and do { $self->{$1} = $newval; return; };

	croak "No such method: $AUTOLOAD";
}
1;
