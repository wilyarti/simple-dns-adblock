#! /usr/bin/env perl
use 5.24.0;
use warnings;
use strict;
use LWP::Simple;

my $url =
  "https://raw.githubusercontent.com/wilyarti/simple-dns-adblock/master/master.list";
my $outfile = "C:/Windows/system32/drivers/etc/hosts";
my $ip      = "127.0.0.l";
our %hash;

# start our main sub routine
&main();

sub main {
    my $num = &download();
    writefile($outfile);
    my $numb_dom = scalar keys %hash;
    say

"Successfully download and processed $num files. Containing $numb_dom number of domains.";
	say "Press enter to exit. All jobs completed.";
	my $s = <STDIN>;


}


sub download {
    my $i    = 0;
    my $list = get($url);
    if ( !defined $url ) {
        say "Error couldn't get list. Press enter to exit.";
        my $a = <STDIN>;
        exit(1);
    }
    my @lines = split "\n", $list;
    foreach (@lines) {
        if (m/^#/) {
            next;
        }
        elsif ( $_ eq "" ) {
            next;
        }
        else {
            say "Downloading \"$_\"";
            my $s = get($_);
            if (!defined $s) {
                warn "Warning $_ failed to download!";
            }
            else {
                if ( &process($s) ) {
                    $i++;
                }
            }
        }
    }
    return $i;
}

sub process {
    my $file = shift;
    my @lines = split "\n", $file;
    my $lc = scalar @lines;
    print "Processing $lc entries...";
    my $counter;
    foreach (@lines) {
        s/0.0.0.0//g;
        s/127.0.0.1//g;
        s/\s//g;
        if (m/^#/) {
            next;
        }
        elsif (m /((\w+[\.-])+\w+)/) {
		$counter++;
            $hash{$_} = 0;
        }
    }
    print " found $counter\n";

    return !!1;
}

sub writefile {
    my $file = shift;
    if ( open( my $FH, ">", $file ) ) {
        while ( ( my $hash, my $blank ) = each %hash ) {
            print $FH "$ip $hash\n";
        }
		print $FH "127.0.0.1 localhost";
        close($FH);
    }
    else {
        die "Can't open file";
    }
}

__END__ 
=head1 NAME
download.pl - [description here]
=head1 VERSION
This documentation refers to download.pl version 0.0.1
=head1 USAGE
    download.pl [options]
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
