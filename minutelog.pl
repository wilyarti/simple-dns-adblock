#! /usr/bin/env perl
use 5.020;
use warnings;
use strict;
use DateTime;
use Data::Dumper;

#use Regexp::Debugger;

&main;

sub main {
    my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    my @days   = qw(Sun Mon Tue Wed Thu Fri Sat Sun);

    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      localtime();
      #    print "$mday $months[$mon] $days[$wday]\n";
      #    over ride day with line below:
      #    $mday = 25;
    my $dt = DateTime->new(
        year   => $year,
        month  => $mon,
        day    => $mday,
        hour   => 00,
        minute => 00,
    );
    my %store;
    my %blstore;
    while ( <<>> ) {
        my $string = sprintf "%s %s %02d:%02d", $months[$mon], $mday,
          $dt->hour, $dt->minute;
        if (m/^$months[$mon] $mday/) {
            my $count = 0;
            while (1) {
                $string = sprintf "%s %s %02d:%02d", $months[$mon], $mday,
                  $dt->hour, $dt->minute;
                if ( !m/^$string/ ) {
                    $dt->add( minutes => 1 );
                    $count++;
                }
                else {
                    if ( m/query/ ) {
                        my $s = sprintf "2018-%02d-%02d %02d:%02d", $mon, $mday, $dt->hour, $dt->minute;
                        $store{$s}++;
                    } elsif ( m/blocklist.txt/ ) {
                        $blstore{$string}++;

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
    foreach my $date (sort keys %store) {
        # create csv file for GNUplot
        say "$date,$store{$date}";
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

