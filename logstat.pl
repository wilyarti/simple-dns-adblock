#! /usr/bin/env perl
use 5.020;
use warnings;
use strict;

&main;

sub main {
    my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    my @days   = qw(Sun Mon Tue Wed Thu Fri Sat Sun);

    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      localtime();
    print "$mday $months[$mon] $days[$wday]\n";
    my $qc = 0;
    my $qb = 0;
    my %tracker;
    my %tracker2;
    my @hrs = (
        "01", "02", "03", "04", "05", "06", "07", "08",
        "09", "10", "11", "12", "13", "14", "15", "16",
        "17", "18", "19", "20", "21", "22", "23", "00"
    );
    my @hrs2 = (
        "01", "02", "03", "04", "05", "06", "07", "08",
        "09", "10", "11", "12", "13", "14", "15", "16",
        "17", "18", "19", "20", "21", "22", "23", "00"
    );

    foreach my $hr (@hrs) {
        $tracker{$hr}  = 0;
        $tracker2{$hr} = 0;
    }

    while ( <<>> ) {
        unless (m/$months[$mon] $mday/) {
            next;
        }
        if (m/query/) {
            foreach my $hr (@hrs) {
                if (m/ $hr:/) {
                    $tracker{$hr}++;
                    last;
                }

            }
            $qc++;
        }
        if (m/blocklist/) {
            foreach my $hr (@hrs) {
                if (m/ $hr:/) {
                    $tracker2{$hr}++;
                    last;
                }

                $qb++;
            }
        }

    }

    foreach my $hr (@hrs) {
        say "Hour ($hr): queries: $tracker{$hr} blocked: $tracker2{$hr}";
    }
    say "$qc queries";
    say "$qb blocked";

}

__END__ 
=head1 NAME
logstat.pl - [description here]
=head1 VERSION
This documentation refers to logstat.pl version 0.0.1
=head1 USAGE
    logstat.pl [options]
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

