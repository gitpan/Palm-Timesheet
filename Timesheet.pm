package Palm::Timesheet;
$VERSION = "0.1";

=head1 NAME

Palm::Timesheet - Handler for Timesheet1.5.3 databases.

=head1 VERSION

This document refers to version 0.1 of Palm::Timesheet, released
Tue Oct 30 2001.

=head1 SYNOPSIS

	use Palm::Timesheet;

	my $ts = Palm::Timesheet->new( file => $filename );
	my $clients     = $ts->get_clients;
	my $projects    = $ts->get_projects;
	my $tasks       = $ts->get_tasks;  

	
	while ( my $d = $ts->get_days->each ) {
    	while ( my $e = $d->each ) {
			print join( ";", (	
        			$d->get_day,
                    $clients->get_record($e->get_client),
                    $projects->get_record($e->get_project),
                    $tasks->get_record($e->get_task),
                    sprintf("%02d:%02d", $e->get_hour, $e->get_min ),
                    ($e->get_chargeable)?"Y":" ",
					$e->get_comment
            		)) . "\n";
    	}
	}	    

=head1 DESCRIPTION

The Timesheet PDB handler is a class that parses Timesheet1.5.3 databases.
Timesheet1.5.3 is created by Stuart Nicholson <snic@ihug.co.nz>.

It can be used to read and write Timesheet databases.

=head2 Overview

The Palm::Timesheet class parses a Timesheet PDB and collects the data
contained in a set of objects. A timesheet entry consists of a client
, project, task, date, duration (hour and minutes) a comment and if the entry
is chargeable or not.

=head2 Constructor and Initialization

For the moment one constructor is available, it takes an existing PDB
as a parameter and parses the database.

	my $ts = Palm::Timesheet->new( -file => $filename );

=head2 Class and other object methods

=over 4

=item write

	# Write to filename
	$ts->write( $filename );

	# Rewrite, using constructor filename.
	$ts->write

=item get_days

Returns a Palm::Timesheet::DayRecordList    

=item get_preferences

Returns a Palm::Timesheet::PreferenceRecord

=item get_clients

Returns a Palm::Timesheet::ClientRecordList

=item get_projects

Returns a Palm::Timesheet::ProjectRecordList

=item get_tasks 

Returns a Palm::Timesheet::TaskRecordList

=back

=head1 BUGS

Probably a few ... but it works for now. PDB writing has *not* been
thoroughly tested. 

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>

=head1 COPYRIGHT

Copyright (c) 2001, Johan Van den Brande. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut

use strict;
use Carp;
use vars '$AUTOLOAD';

use constant PDB_NAME 		=> 'TimesheetDB';
use constant PDB_TYPE 		=> 'data';
use constant PDB_CREATORID	=> 'TiSh';
use constant PDB_VERSION 	=> 261;
use constant PDB_MODIFICATION	=> 350;
use constant PDB_BASEID		=> 14360577;

use Palm::Timesheet::Utilities;
use Palm::Timesheet::PreferenceRecord;
use Palm::Timesheet::ClientRecordList;
use Palm::Timesheet::ProjectRecordList;
use Palm::Timesheet::TaskRecordList;
use Palm::Timesheet::DayRecord;
use Palm::Timesheet::DayRecordList;
use Palm::Timesheet::EntryRecord;

use Palm::PDB;
use Palm::Raw;

{
	my %_attributes = (
		preferences	=> undef,
		days		=> undef,
		clients		=> undef,
		projects	=> undef,
		tasks		=> undef
	);

# create one from a file ....
sub new {
	my ($proto, %args) = @_;
	my $class = ref($proto) || $proto;

	my $self = { 
		_file => $args{file} || croak "Missing 'file' parameter.", 
	};
	bless $self, $class;	
	$self->_parse;
	return $self;
}

}

sub write {
	my ($self, $filename) = @_;
	$filename = $self->{_file} unless $filename;

	my $PDB = Palm::Raw->new();
	$PDB->{"name"} = PDB_NAME;
	$PDB->{"type"} = PDB_TYPE;
	$PDB->{"creator"} = PDB_CREATORID;
	$PDB->{"attributes"}{"backup"} = 1;
	$PDB->{"version"} = PDB_VERSION;
	$PDB->{"modnum"} = PDB_MODIFICATION;

	my $record;
	my $id = PDB_BASEID;
	
	# preferences
	my $preferences = $self->get_preferences;
	$preferences->set_numclientcategories($self->get_clients->get_size);
	$preferences->set_numprojectcategories($self->get_projects->get_size);
	$preferences->set_numtaskcategories($self->get_tasks->get_size);

	$record = $PDB->new_Record;
	$record->{"data"} = $preferences->pack;
	$record->{"id"} = $id++;
	$PDB->append_Record( $record );

	# clients
	$record = $PDB->new_Record;
	$record->{"data"} = $self->get_clients->pack;
	$record->{"id"} = $id++;
	$PDB->append_Record( $record );

	# projects
	$record = $PDB->new_Record;
	$record->{"data"} = $self->get_projects->pack;
	$record->{"id"} = $id++;
	$PDB->append_Record( $record );

	# tasks
	$record = $PDB->new_Record;
	$record->{"data"} = $self->get_tasks->pack;
	$record->{"id"} = $id++;
	$PDB->append_Record( $record );	

	# entries
	while ( my $d = $self->get_days->each ) {
		$record = $PDB->new_Record;
		$record->{"data"} = $d->pack;
		$record->{"category"} = 1;
		$record->{"id"} = $id++;

		$PDB->append_Record( $record );
		while ( my $e = $d->each ) {
			$record = $PDB->new_Record;
			$record->{"data"} = $e->pack;
			$record->{"category"} = 2 | ($e->get_chargeable << 3);
			$record->{"id"} = $id++;
			$PDB->append_Record( $record );
		}
	}

	$PDB->Write($filename);
}

sub _parse 
{ 
	my $self = shift;

	my $PDB = Palm::PDB->new();		
	$PDB->Load( $self->{_file} ) || croak "Couldn't open file: $!"; 
	my @records = @{$PDB->{"records"}};

	# Parse the preference record
	my $preference = Palm::Timesheet::PreferenceRecord->from_record( $records[0]->{data} );
	$self->set_preferences( $preference );

	my $clientrecordlist = Palm::Timesheet::ClientRecordList->from_record( 
				$records[1]->{data},
				$preference->get_numclientcategories );
	$self->set_clients( $clientrecordlist );

	my $projectrecordlist = Palm::Timesheet::ProjectRecordList->from_record( 
				$records[2]->{data},
				$preference->get_numprojectcategories );
	$self->set_projects( $projectrecordlist );

	my $taskrecordlist = Palm::Timesheet::TaskRecordList->from_record( 
				$records[3]->{data},
				$preference->get_numtaskcategories );
	$self->set_tasks( $taskrecordlist );

	my $daylist = Palm::Timesheet::DayRecordList->new();

	my @entries = @records[4..$#records];
	while ( @entries ) {
		my $entry = shift @entries;
		my $day = Palm::Timesheet::DayRecord->from_record( $entry->{data});
		$daylist->push( $day );
		for(my $i=0; $i<$day->get_numentries; $i++) {
			my $entry = shift @entries;
			my $e = Palm::Timesheet::EntryRecord->from_record( $entry );
			$day->push( $e );	
		}
	}
	$self->set_days( $daylist );
}

sub AUTOLOAD
{
	my ($self, $newval) = @_;
	
	$AUTOLOAD =~ /.*::get_(\w+)/ and return $self->{$1};
	$AUTOLOAD =~ /.*::set_(\w+)/ and do { $self->{$1} = $newval; return; };

	croak "No such method: $AUTOLOAD";

}

1;
