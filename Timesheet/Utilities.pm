package Palm::Timesheet::Utilities;
use strict;
use vars qw( @EXPORT );
use base qw( Exporter );
@EXPORT = qw( 	record_to_hour_min hour_min_to_record  
				crack_categories encode_categories );

=head1 NAME

Palm::Timesheet::Utilities - Helper methods for the Timesheet package.

=head1 DESCRIPTION

This package contains some helper methods that are used throughout the
different modules.

=head1 METHODS

=over 4

=item B<1. ($hour, $min) = record_to_hour_min( $hourminrecord )>

Convert a time record to the hour and minutes it contains.
The format is:

	|7654|3210|
	|min |hour|

	minutes = 5 * min

=cut

sub record_to_hour_min { ( $_[0] % 16, ( $_[0] >> 4 ) *5 ); }

=item B<2. $hourminrecord = hour_min_to_record( $hour, $min )>

Convert the time ( hour and minutes ) to the PDB format.

=cut

sub hour_min_to_record { ($_[0] & 0x0F) | ((int($_[1] / 5) << 4) & 0xF0 ); }

=item B<3. ( $transarrayref, $namesarrayref ) = crack_categories( $categories, $len)>

Return a reference to an array containing the translation table and a reference to an array containing the names of the categories. The parameters are  the category record and the amount of categories in that record.

=cut

sub crack_categories 
{
	my ($categories, $len) = @_;

	my @transtable = map { unpack("C", $_);  } 
				split( //, substr($categories, 0, 102) );
	my @names;
	for(my $i=0; $i < $len; $i++) {
		my $t = substr( $categories, 102+($i*18), 18 );
		$t =~ /^(.*?)\0/;
		push(@names, $1 );
	}
	return(\@transtable, \@names);
}

=item B<4. $categories = encode_categories( $transarrayref, $namesarrayref )>

Create a PDB record to contain the categories. The transtable needs to build
somewhere else. This will probably be done in the package for that category

=cut

sub encode_categories
{
	my ( $transref, $namesref ) = @_;
	my $record;
	
	map { $record .= pack("C", $_); } @$transref;
	map { $record .= substr( $_ . pack( "C", 0) x 17 , 0, 17 ) . "\0"; } @$namesref;

	return $record; 	
}

=back

=head1 COPYRIGHT
 
Copyright (c) 2001, Johan Van den Brande. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.  

=cut 

1;
