package Palm::Timesheet::List;
$VERSION = 1.00;
use strict;
use Carp;
use vars '$AUTOLOAD';

=head1 NAME

Palm::Timesheet::List - A generic list class. 

=head1 SYNOPSIS

	package Palm::Timesheet::SomeList;
	use strict;
	use base qw ( Palm::Timesheet::List );
	
	...

	1;


=head1 DESCRIPTION

A generic list class, primarily for subclassing.

=over 4

=item new

Constructor ...

	my $l = Palm::Timesheet::List->new( @stuff );

=item get_size

Returns size of list.

=item push( @stuff )

Push stuff on list.

=item pop

Pop last element from list.

=item delet( $name )

Delete a named item from list.

=item get_element( $index )

Return element at $index.

=item each

Iterator .. used as in ...

	while ( my $item = $list->each ) {
		do_something_with( $item );
	}

=back

=head1 COPYRIGHT
 
Copyright (c) 2001, Johan Van den Brande. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.  

=cut

sub new
{
	my( $proto, @list ) = @_;
	my $class = ref($proto) || $proto;

	my $self = { 
		_list => [ @list ],
		_iter => [],
		_iter_slot => -1
		   }; 
	bless $self, $class;
}

sub get_size { 0 + @{$_[0]->{_list}}; }

sub push 
{ 
	my ($self, @list) = @_;
	push( @{$self->{_list}}, @list );
}

sub pop
{
	pop( @{$_[0]->{_list}} );
}

sub delete
{
	my ($self, $day) = @_;

	my @new;
	my $deleted = 0;
	map {
		$deleted++ if $day == $_;
		push( @new, $_ ) unless $day == $_;		
	} @{$self->{_list}};

	@{$self->{_list}} = @new;

	return $deleted;
}

sub get_element
{
	my ( $self, $index ) = @_;
	$self->{_list}->[$index];
}

sub each {
	my $self = shift;

	if ( $self->{_iter_slot} == -1 ) {
		$self->{_iter} = [ @{$self->{_list}} ];
		$self->{_iter_slot} = 0;
	}
	
	my $ret = shift @{$self->{_iter}};
	$self->{_iter_slot} = -1 unless $ret;
	return $ret;
}
1;
