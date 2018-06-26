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
eval { $dbh->do("CREATE TABLE query (date CHAR(16) NOT NULL, count REAL) "); };
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

    print Dumper(%domains);
    print Dumper(%clients);
    return !!0;
}

sub proc {
    my $line = shift;
    if ( $line =~ m/query/ ) {
        $line =~ s/ +/ /g;
        my @words = split / /, $line;
        my @hms  = split /:/, $words[2];

        my @host = split /\//, $words[5];
        say "$words[7] ++ $host[0] host";
        $domains{ $words[7] }++;
        $clients{ $host[0] }++;
        ### DBI stuff
        if (scalar(@hms) >= 2) {
        &doitnow( "query", "$hms[0]-$hms[1]" );
        }
    }
    elsif ( $line =~ m/blocklist.txt/ ) {
        $line =~ s/ +/ /g;
        my @words = split / /, $line;
        my @hms  = split /:/, $words[2];

        #my @host = split /\//, $words[5];
        ### DBI stuff
        if (scalar(@hms) >= 2) {
                &doitnow( "blocked", "$hms[0]-$hms[1]" );
                }
    }

}

sub doitnow {
    my ( $table, $datestring ) = @_;
    my $stmt = qq(SELECT COUNT from blocked WHERE date = \"$datestring\");
    my $sth  = $dbh->prepare($stmt);
    my $rv   = $sth->execute() or die $DBI::errstr;
    if ( $rv < 0 ) {
        print $DBI::errstr;
    }
    eval {
        say "update into $table $datestring";
        my $sql =
          "UPDATE $table SET count = count + 1 WHERE date = \"$datestring\"";
        my $sendit = $dbh->prepare($sql);
        $sendit->execute();
    }; if ($@) {
        say "insert into $table $datestring";
        my $sql = "INSERT OR REPLACE INTO $table ( date, count ) VALUES( ?, ?)";
        my $sendit = $dbh->prepare($sql);
        $sendit->execute( "$datestring", 0 );
    }
}
