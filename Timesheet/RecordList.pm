package Palm::Timesheet::RecordList;
use strict;
use base qw ( Palm::Timesheet::List );
use Palm::Timesheet::Utilities;
use Carp;

=head1 NAME

Palm::Timesheet::RecordList - A recordlist, used to contain projects, clients and tasks.

=head1 SYNOPSIS

	package Palm::Timesheet::SomethingRecordList;
	use strict;
	use base qw ( Palm::Timesheet::RecordList );
	1;

=head1 DESCRIPTION

This basically a Palm::Timesheet::List with the following extra
methods

=over 4

=item from_record

Constructor that uses a record entry to fill the list. One PDB record
keeps the list of clients another the projects and yet another the
tasks.

=item get_record( $index )

Get record at position $index.

=item add_record( $name )

Try to add something without breaking the rest ...

=item find( $needle, @haystack )

Try to find the position of an entry. Internal function and should be
name _find.

=item del_record( $name )

Delete that record.

=item pack

Serialize list so it can live in a PDB record.

=back

=head1 COPYRIGHT
 
Copyright (c) 2001, Johan Van den Brande. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.  

=cut

sub from_record 
{
	my ( $class, $record, $len ) = @_;
	
	my ($trans, $names) = crack_categories( $record, $len );
	my $self = $class->SUPER::new( @$names );
	$self->{_trans} = [ @$trans ];
	
	return $self;
}

sub get_record
{
	my ($self, $index) = @_;
	
	return $self->{_list}->[$self->{_trans}->[$index]];
}

sub add_record
{
	my ($self, $client) = @_;

	my @original = @{$self->{_list}};
	my @map_original = @{$self->{_trans}};
	my @new;
	my @map_new;

	push( @new, $original[0] );
	@new[1..$#original] = sort ( @original[1..$#original-1], $client );
	push( @new, $original[$#original] );

	# print join( ";", @original ) . "\n";
	# print join( ";", @new ) . "\n";


	$map_new[0] = 0;
	$map_new[101] = $#new;	
	my $i;
	for( $i=1; $i<101; $i++ ) {
		my $old_pos = $map_original[$i];
		my $old_name = $original[$old_pos];
		if ( $old_pos != 102 ) {
			my $new_pos = $self->find($old_name, @new);
			$map_new[$i] = $new_pos;
		} else {
			last;
		} 
	}
	$map_new[$i++] = $self->find( $client, @new );
	for(;$i<101;$i++) { $map_new[$i] = 102; }

	# print join( ";", @map_original ) . "\n";
	# print join( ";", @map_new ) . "\n";
	
	@{$self->{_list}}	= @new;
	@{$self->{_trans}}	= @map_new;
}

sub find {
	my ($self, $needle, @haystack) = @_;
	my $position = 102;
	my $i = 0;
	foreach my $j (@haystack) {
		if ( $j eq $needle ) {
			$position=$i;
			last;
		}
		$i++;
	}
	return $position;	
}


sub del_record
{
	my ($self, $client) = @_;

	# croak "Not yet implemented!\n";

	my @original = @{$self->{_list}};
	my @map_original = @{$self->{_trans}};
	my @new;
	my @map_new;


	map { push( @new, $_) unless  $_ eq $client; } @original;
	
	# print join( ";", @original ) . "\n";
	# print join( ";", @new ) . "\n";

	$map_new[0] = 0;
	$map_new[101] = $#new;	
	my $i;
	my $j;
	for( $i=1, $j=1; $i<101; $i++, $j++ ) {
		my $old_pos = $map_original[$i];
		my $old_name = $original[$old_pos];
		if ( $old_name eq $client ) {
			$j--;
			next;
		}
		if ( $old_pos != 102 ) {
			my $new_pos = $self->find($old_name, @new);
			$map_new[$j] = $new_pos;
		} else {
			last;
		} 
	}
	for(;$j<101;$j++) { $map_new[$j] = 102; }

	# print join( ";", @map_original ) . "\n";
	# print join( ";", @map_new ) . "\n";
	
	@{$self->{_list}}	= @new;
	@{$self->{_trans}}	= @map_new;

}

sub pack
{
	my $self = shift;
	return encode_categories( $self->{_trans}, $self->{_list} );
}
1;
