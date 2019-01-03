#! /usr/bin/env perl
use warnings;
use strict;
use Data::Dumper;
use DateTime;
use File::Tail;
use 5.26.1;
use Redis;
use feature "say";

my $redis = Redis->new(
    server => "127.0.0.1:6379",
    name => "stattera",
) or die ("Can't connect to server!");

our $logfile = "pihole.log";
our $dbfile = "db.sqlite";


&main;

sub main {
    open( my $FH, "<", $logfile ) or die "Can't open $logfile";
    while (<$FH>) {
        &proc($_);
    }
    close($FH);
    my $file=File::Tail->new($logfile);
    my $line;
    while (defined($line=$file->read)) {
        &proc($line);
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

            say
            &doitnow( "query", "$words[0]-$words[1]-$hms[0]:$hms[1]","$words[0]-$words[1]", "$hms[0]:$hms[1]", "$host[0]", "$words[7]", 0 );
        }
    }
    elsif ( $line =~ m/blocklist.txt/ && $line ne m/bad name/) {
        $line =~ s/ +/ /g;
        my @words = split / /, $line;
        my @hms  = split /:/, $words[2];
        my @host  = split /\//, $words[5];

        ### DBI stuff
        if (scalar(@hms) >= 2) {
                &doitnow( "blocked", "$words[0]-$words[1]-$hms[0]:$hms[1]", "$words[0]-$words[1]", "$hms[0]:$hms[1]", "$host[0]", "$words[7]", 1 );
        }
    }

}

sub doitnow {
    my ( $table, $time,$short_date, $hms, $source, $domain, $type ) = @_;
    say "inserting $table, $short_date, $time, $hms, $source, $domain, $type ";
    #normal query

    #overall totals
    say $redis->hincrby("totals", "$table",1 );
    say $redis->hincrby("totals", "$source",1 );
    say $redis->hincrby("domains", "$domain",1 );

    # daily table
    # statistics for time
    say $redis->hincrby("$short_date:$table", "$hms", 1);

    # overall daily table
    say $redis->hincrby("$table", "$short_date",1 );

    if ($type == 1) {
        #count blocked domains
        say $redis->hincrby("$short_date:$table:domains", "$domain", 1);
    } else {
        return !! 1;
    }
    return !! 0;
}
