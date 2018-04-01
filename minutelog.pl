#! /usr/bin/env perl
use 5.020;
use warnings;
use strict;
use DateTime;
use Data::Dumper;

#use Regexp::Debugger;


our $now = DateTime->now();

&main;

sub main {
    if (!defined $ARGV[2]) {
        &usage;
    } elsif (!-f $ARGV[2]) { 
        &usage; 
    } 
    my $err = &process($ARGV[0], $ARGV[1], $ARGV[2]);
    if ($err != 0) {
        die "Error processing failed!";
    }
    &plot($ARGV[0], $ARGV[1], "$now.dat");
    &cleanup($now);
}
sub cleanup {
    my $file = shift;
    unlink ("$file.dat") or warn "Couldn't remove file!";
    unlink ("$file.plot") or warn "Couldn't remove file!";

}

sub usage {
    say "Usage: minutelog <day> <Mon(th)> <logfile>";
    die;
}

sub process {
    my ($day, $month, $file) = @_;
    use DateTime;
    my $dt = DateTime->new(
        year => $now->year,
        month => $now->month,
        hour   => 0,
        minute => 0,
    );
      #    $mday = 25;
    my %store;
    my %blstore;
    open (my $FH, "<", $file) or die "Can't open $file";
    while ( <$FH> ) {
        #$_ =~ s/ +/ /;
        my $string = sprintf "%02d:%02d",$dt->hour, $dt->minute;
        # beware of multiple white space. log format is often single digit or
        # date
        if (m/^$month( +)$day/) {
            my $count = 0;
            while (1) {
                $string = sprintf "%02d:%02d", $dt->hour, $dt->minute;
                if ( !m/$string/ ) {
                    $dt->add( minutes => 1 );
                    $count++;
                    my $s = sprintf "%02d:%02d", $dt->hour, $dt->minute;
                    if (! defined $store{$s} ) {
                        $store{$s} = 0;
                    }
                }
                else {
                    if ( m/query/ ) {
                        my $s = sprintf "%02d:%02d", $dt->hour, $dt->minute;
                        $store{$s}++;
                    } elsif ( m/blocklist.txt/ ) {
                        my $s = sprintf "%02d:%02d", $dt->hour, $dt->minute;
                        $blstore{$s}++;

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
    open (my $OF, ">", "./$now.dat") or die "Can't open output file!";
    foreach my $date (sort keys %store) {
        # create csv file for GNUplot
        if (defined $blstore{$date}) {
            print $OF "$date,$store{$date},$blstore{$date}\n";
        } else {
            print $OF "$date,$store{$date},0\n";
        }
    }
    close ($OF);
    return !! 0;
}

sub plot {
    my ($day, $month, $file) = @_;
    my $plot_data = <<END;
    set datafile separator ","
set timefmt '%H:%M:%S'

set xlabel "Queries for $month $day"
set ylabel "Queries Per Minute"

set xdata time
set grid

set style line 1 linetype 1 linecolor rgb "green" linewidth 1.000
set style line 2 linetype 1 linecolor rgb "red" linewidth 1.000

set terminal jpeg size 1024, 512
set output "$file.jpg"

set xrange ['00:00':'23:59']
set format x '%H:%M'
set autoscale y

plot '$file' u 1:(\$2) title 'Allowed Quieries' with lines,\\
    '$file' u 1:(\$3) title 'Blocked Quieries' with lines
END
    open (my $GP, ">", "./$now.plot") or die "Can't open file to plot!";
    print $GP $plot_data;
    close($GP);
    my $o = `gnuplot $now.plot`;
    print $o;
    if ($? ne 0) {
        die "Failed to plot graph!";
    }




}
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

