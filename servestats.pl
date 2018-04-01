#! /usr/bin/env perl
use 5.020;
use warnings;
use strict;
use Data::Dumper;
use Mojolicious::Lite;
use DateTime;

our $basename;
our $logfile = "/home/undef/pihole.log";
our $wwwpath = "public";
our $datapath = "/home/undef/Workspace/src/log_stats/web";

app->config(hypnotoad => {listen => ['http://*:8080']});

get '/' => sub {

  my $c   = shift;
  $c->render(text => "Enter a valid data string: MM/DD");
};


get '/:param' => sub {
    my $c = shift;
    my $param = $c->param('param');
    my @args = split /:/, $param;
    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my ($second, $minute, $hour, $day, $m, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
    my $year = 1900 + $yearOffset;
    # fix 0 index of month. (Jan = 0)
    $m++;

    # custome date entry
    if (defined $args[0] && defined $args[1]) {
        $day = $args[1];
        $m = ($args[0]-1);
    }
    my $month = $months[$m];
    my $basename = sprintf ("%04d-%02d-%02d:%02d", $year, $m, $day, $hour);
    say $basename;
    my $err = &main($year, $month, $m, $day, $basename, $logfile);
    if ($err != 0) {
        $c->render(text => "No results found for $param" );
    } else {
        $c->render(text => "Server stats for $month $day:<br> <img src=\"$basename.dat.jpg\"> <br> <img src=\"$basename.qd.jpg\"> <br> <img src=\"$basename.bd.jpg\">" );
    }
};



sub main {
    my ($year, $month, $m, $day, $basename, $file) = @_;
    say "$year, $month, $m, $day, $basename, $file";
    # check if log file exists.
    if (!-f $file) { 
        say "Log file missing!";
    # check if file are already generated for this hour
    } elsif (-e "$wwwpath/$basename.bd.jpg" && -e "$wwwpath/$basename.qd.jpg" && -e "$wwwpath/$basename.dat.jpg") {
        say "Files exists for time $basename.";
    # finally generate plots
    } else {
        my $err = &process($year, $month, $m, $day, $basename, $file);
        if ($err != 0) {
            warn "Error processing failed!";
            return !! 1;
        } else {
            my $err = &plot($month, $day, "Queries", $basename, "$basename.dat");
            if ($err != 0) {
                warn "Error plotting file!";
                return !! 1;
            }
            $err = &plot2($month, $day, "Blocked Domains", $basename, "$basename.bd");
            if ($err != 0) {
                warn "Error plotting file!";
                return !! 1;
            }
            $err = &plot2($month, $day, "Most Queried Domains", $basename, "$basename.qd");
            if ($err != 0) {
                warn "Error plotting file!";
                return !! 1;
            }
            &cleanup($basename);
        }
    }
    return !! 0;
}
sub cleanup {
    my $file = shift;
    unlink ("$file.dat") or warn "Couldn't remove file!";
    unlink ("$file.plot") or warn "Couldn't remove file!";
    unlink ("$file.qd") or warn "Couldn't remove file!";
    unlink ("$file.bd") or warn "Couldn't remove file!";
}


sub process {
    my ($year, $month, $m, $day, $basename, $file) = @_;
    my $dt = DateTime->new(
        year => $year,
        month => $m,
        hour   => 0,
        minute => 0,
    );
    my %store;
    my %blstore;
    my %domains;
    my %bdomains;
    my %clients;
    open (my $FH, "<", $file) or die "Can't open $file";
    my $i = 0;
    while ( <$FH> ) {
        my $string = sprintf "%s %s %02d:%02d", $month, $day,
          $dt->hour, $dt->minute;
        if (m/^$month $day/) {
            my $count = 0;
            while (1) {
                $string = sprintf "%s %s %02d:%02d", $month, $day,
                  $dt->hour, $dt->minute;
                if ( !m/^$string/ ) {
                    $dt->add( minutes => 1 );
                    $count++;
                    my $s = sprintf "%02d:%02d", $dt->hour, $dt->minute;
                    if (! defined $store{$s} ) {
                        $store{$s} = 0;
                    }
                }
                else {
                    # split up text to remove various data points.
                    my @words = split / /, $_;
                    if ( m/query/ ) {
                        $domains{$words[7]}++;
                        my @host = split /\//, $words[5];
                        $clients{$host[0]}++;
                        my $s = sprintf "%02d:%02d", $dt->hour, $dt->minute;
                        $store{$s}++;
                        $i++;
                    } elsif ( m/blocklist.txt/ ) {
                        $bdomains{$words[7]}++;
                        my $s = sprintf "%02d:%02d", $dt->hour, $dt->minute;
                        $blstore{$s}++;
                        $i++;

                    }
                    $count = 0;
                    last;
                }
                if ($count > 61) {
                    next;
                }
            }

        }
    }
    if ($i == 0) {
        return !! 1;
    }
    open (my $OF, ">", "$datapath/$basename.dat") or die "Can't open output file!";
    foreach my $date (sort keys %store) {
        # create csv file for GNUplot
        if (defined $blstore{$date}) {
            print $OF "$date,$store{$date},$blstore{$date}\n";
        } else {
            print $OF "$date,$store{$date},0\n";
        }
    }
    close ($OF);
    # find top 30 blocked and looked up domains
    $i = 0;
    open (my $BD, ">", "$datapath/$basename.bd") or die "Can't open output file!";
    foreach my $name (sort { $bdomains{$b} <=> $bdomains{$a} } keys %bdomains) {
        my $s = sprintf "%02d %-8s %s\n", $i, $name, $bdomains{$name};
        print $BD $s;
        if ($i > 30) {
            last;
        }
        $i++;
    }
    close ($BD);
    $i = 0;
    open (my $QD, ">", "$datapath/$basename.qd") or die "Can't open output file!";
    foreach my $name (sort { $domains{$b} <=> $domains{$a} } keys %domains) {
        my $s = sprintf "%02d %-8s %s\n", $i, $name, $domains{$name};
        print $QD $s;
        if ($i > 30) {
            last;
        }
        $i++;
    }
    close ($QD);
    return !! 0;
}

sub plot {
    my ($month, $day, $title, $basename, $file) = @_;
    my $plot_data = <<END;
    set datafile separator ","
set timefmt '%H:%M:%S'

set xlabel "$title for $month $day"
set ylabel "Queries Per Minute"

set xdata time
set grid

set style line 1 linetype 1 linecolor rgb "green" linewidth 1.000
set style line 2 linetype 1 linecolor rgb "red" linewidth 1.000

set terminal jpeg size 1024, 512
set output "$wwwpath/$file.jpg"

set xrange ['00:00':'23:59']
set format x '%H:%M'
set autoscale y

plot '$datapath/$file' u 1:(\$2) title 'Allowed Queries' with lines,\\
    '$datapath/$file' u 1:(\$3) title 'Blocked Queries' with lines
END
    open (my $GP, ">", "$datapath/$basename.plot") or die "Can't open file to plot!";
    print $GP $plot_data;
    close($GP);
    my $o = `gnuplot $datapath/$basename.plot`;
    print $o;
    if ($? ne 0) {
        warn "Failed to plot graph!";
        return !! 1;
    }
    return !! 0;

}
sub plot2 {
    my ($month, $day, $title, $basename, $file) = @_;
    my $plot_data = <<END;
set terminal png size 1024, 768 font 10
set output "$wwwpath/$file.jpg"

set boxwidth 0.5
set style fill solid
set bmargin 15

set xtics rotate by 90 right
set ytics rotate by 90 right
set title '$title'

plot "$datapath/$file" using 1:3:xtic(2) with boxes

END
    open (my $GP, ">", "$datapath/$basename.plot") or die "Can't open file to plot!";
    print $GP $plot_data;
    close($GP);
    my $o = `gnuplot $datapath/$basename.plot`;
    print $o;
    if ($? ne 0) {
         warn "Failed to plot graph!";
         return !! 1;
    }
    return !! 0;

}
app->start;

__END__ 
=head1 NAME
minutelog.pl - [description here]
=head1 VERSION
This documentation refers to minutelog.pl version 0.0.1
=head1 USAGE
    minutelog.pl [options]
=head1 REQUIRED ARGUMENTS
=over
None
=back
=head1 OPTIONS
=over
None
=back
=head1 DIAGNOSTICS
None.
=head1 CONFIGURATION AND ENVIRONMENT
Requires no configuration files or environment variables.
=head1 DEPENDENCIES
None.
=head1 BUGS
None reported.
Bug reports and other feedback are most welcome.
=head1 AUTHOR
Wilyarti Howard C<< wilyarti@gmail.com >>
=head1 COPYRIGHT
Copyright (c) 2018, Wilyarti Howard C<< <wilyarti@gmail.com> >>. All rights reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)
=head1 DISCLAIMER OF WARRANTY
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentatio
n and/or other materials provided with the distribution.
 
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software w
ithout specific prior written permission.
 
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRIC
T LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SU
CH DAMAGE.

