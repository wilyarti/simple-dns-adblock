#! /usr/bin/env perl
use 5.020;
use warnings;
use strict;
use Data::Dumper;
use DateTime;

use DBI;

our $basename;
our %clients;
our $numq;
our $numqb;
our %store;
our $aget = 0;
our %blstore;
our $text_status;

my @months;
my $month;
my $string;
my $matched   = 0;
my $lastmonth = 0;
my $lastday   = 1;
my $dt;
my %domains;
my %bdomains;
my (
    $second,    $minute,    $hour,
    $day,       $m,         $yearOffset,
    $dayOfWeek, $dayOfYear, $daylightSavings
) = localtime();

our $logfile = "/home/undef/pihole.log";
my $dbfile = "/home/undef/db.sqlite";
our $wwwpath  = "/home/undef/www/";
our $datapath = "/home/undef/www/public";

my $dbh = DBI->connect( "dbi:SQLite:dbname=$dbfile", "", "" );
eval { $dbh->do(
        "CREATE TABLE blocked (date CHAR(16) NOT NULL, count REAL) "); };
warn $@ if $@;
eval { $dbh->do(
        "CREATE TABLE query (date CHAR(16) NOT NULL, count REAL) "); };
warn $@ if $@;

&main;

sub main {
    @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

    my $year = 1900 + $yearOffset;

    # assume start of year
    $day = "01";
    $m   = "04";

    my $month = $months[ $m - 1 ];
    my $basename = sprintf( "%04d-%02d-%02d:%02d", $year, $m, $day, $hour );

    my $file = $logfile;
    say "$year, $month, $m, $day, $basename, $file";

    # check if log file exists.
    if ( !-f $file ) {
        say "Log file missing!";

        #server is not public. regerate for every request.
        # check if file are already generated for this hour
        # finally generate plots
    }
    $dt = DateTime->new(
        year   => $year,
        month  => $m,
        hour   => 0,
        minute => 0,
    );

    delete @clients{ keys %clients };
    delete @blstore{ keys %blstore };
    delete @store{ keys %store };
    $numq = $numqb = 0;
    open( my $FH, "<", $file ) or die "Can't open $file";

    # force scalar context for $day as the logfile is has single digit
    # date format: Apr 1
    $day = $day + 0;

    while (<$FH>) {
        &proc($_);
    }
    print Dumper(%store);
    return !!0;
}

sub proc {
    my $line = shift;
    my $j    = 0;
    for ( 0 .. 364 ) {
        $j++;
        $month = $months[ ( $dt->month ) - 1 ];
        $day   = $dt->day;
        $day   = $day + 0;
        if ($matched) {
            $dt->set_month($lastmonth);
            $dt->set_day($lastday);
        }
        if ( $line =~ m/^$month( +)$day( +)/ ) {
            $matched   = 1;
            $lastmonth = $dt->month;
            $lastday   = $dt->day;
            my $count = 0;
            my @words = split / /, $line;

            while(1) {
                $string = sprintf "%02d:%02d", $dt->hour, $dt->minute;
                if ( $words[2] =~ m/$string/ ) {
                    if ( $line =~ m/query/ ) {
                        $domains{ $words[7] }++;
                        my @host = split /\//, $words[5];
                        $clients{ $host[0] }++;
                        my $s = sprintf "%02d:%02d", $dt->hour, $dt->minute;
                        $store{$s}++;
                        $numq++;
                        ### DBI stuff
                        &doitnow("query", "$month-$day-$s");
                    }
                    elsif ( $line =~ m/blocklist.txt/ ) {
                        $bdomains{ $words[7] }++;
                        my $s = sprintf "%02d:%02d", $dt->hour, $dt->minute;
                        $blstore{$s}++;
                        $numqb++;
                        ### DBI stuff
                        &doitnow("blocked", "$month-$day-$s");
                    }
                    $count = 0;
                    last;
                } else {
                    $dt->add( minutes => 1 );
                    $count++;
                    my $s = sprintf "%02d:%02d", $dt->hour, $dt->minute;
                    if ( !defined $store{$s} ) {
                        $store{$s} = 0;
                    }
                }
                if ( $count > 60*24 ) {
                    say "no match! $line $words[2]";
                    last;
                }
            }
            last;
        }
        else {
            $dt->add( days => 1 );
            $matched = 0;
        }
    }

}

sub doitnow {
    my ($table, $datestring) = @_;
    my $stmt =
      qq(SELECT COUNT from blocked WHERE date = \"$datestring\");
    my $sth = $dbh->prepare($stmt);
    my $rv = $sth->execute() or die $DBI::errstr;
    if ( $rv < 0 ) {
        print $DBI::errstr;
    }
    if ( $dbh->selectrow_array( $stmt, undef ) ) {
        say "update into $table $datestring";
        my $sql = "UPDATE $table SET count = count + 1 WHERE date = \"$datestring\"";
        my $sendit = $dbh->prepare($sql);
        $sendit->execute();
    }
    else {
        say "insert into $table $datestring";
        my $sql = "INSERT OR REPLACE INTO $table ( date, count ) VALUES( ?, ?)";
        my $sendit = $dbh->prepare($sql);
        $sendit->execute( "$datestring", 0 );
    }
}
