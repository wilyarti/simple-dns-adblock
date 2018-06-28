#! /usr/bin/env perl
use 5.020;
use warnings;
use strict;
use Data::Dumper;
use DateTime;

use DBI;

our $logfile = "/home/undef/pihole.log";
our $dbfile = "/home/undef/db.sqlite";
our $dbh;


&initdb;
&main;

# initialize database tables
sub initdb {
 $dbh = DBI->connect( "dbi:SQLite:dbname=$dbfile", "", "" );
eval { $dbh->do("CREATE TABLE query (time CHAR(16) NOT NULL, 
                                        source CHAR(16) NOT NULL,
                                        domain CHAR(16) NOT NULL)"); };
warn $@ if $@;
eval { $dbh->do("CREATE TABLE blocked (time CHAR(16) NOT NULL,
                                        domain CHAR(16) NOT NULL)"); };
warn $@ if $@;
}

sub main {
    open( my $FH, "<", $logfile ) or die "Can't open $logfile";
    while (<$FH>) {
        &proc($_);
    }
    return !!0;
}

sub proc {
    my $line = shift;
    if ( $line =~ m/query/ ) {
        $line =~ s/ +/ /g;
        my @words = split / /, $line;
        my @hms  = split /:/, $words[2];
        my @host  = split /\//, $words[5];

        ### DBI stuff
        if (scalar(@hms) >= 2) {
                &doitnow( "query", "$words[0]-$words[1]-$hms[0]:$hms[1]", "$host[0]", "$words[7]", 0 );
        }
    }
    elsif ( $line =~ m/blocklist.txt/ ) {
        $line =~ s/ +/ /g;
        my @words = split / /, $line;
        my @hms  = split /:/, $words[2];
        my @host  = split /\//, $words[5];

        ### DBI stuff
        if (scalar(@hms) >= 2) {
                &doitnow( "blocked", "$words[0]-$words[1]-$hms[0]:$hms[1]", "$host[0]", "", 1 );
        }
    }

}

sub doitnow {
    my ( $table, $time, $source, $domain, $type ) = @_;
    say "inserting $table, $time, $source, $domain, $type ";
    my $sql;
    if ($type == 0) {
        $sql = "INSERT INTO $table ( 'time', 'source', 'domain' ) VALUES ( '$time', '$source', '$domain')";
    } elsif ($type == 1) {
        $sql = "INSERT INTO $table ( 'time', 'domain' ) VALUES ( '$time', '$domain')";
    } else {
        return !! 1;
    }
    eval { $dbh->do($sql); };
    if ($@) {
        warn $@;
        return !! 1;
    }
    return !! 0;
}
