#! /usr/bin/env perl
use 5.020;
use warnings;
use strict;
use Data::Dumper;
use Mojolicious::Lite;
use DateTime;
use Mojo::JSON qw(decode_json encode_json);
use File::Copy;

our $basename;
our %clients;
our $numq;
our $numqb;
our %store;
our $aget =0 ;
our %blstore;
our $text_status;

our $logfile  = "/home/undef/pihole.log";
our $wwwpath  = "./public";
our $datapath = "./";

app->config( hypnotoad => { listen => ['http://*:8090'] } );

helper stats => sub {
    return $text_status;

};
helper thisparam =>  sub {
    my $c      = shift;
    my $param = $c->param('param');
    return $param;

};

get '/' => sub {
    my $c = shift;
    $c->render( text => "invalid" );
};
get '/:param'           => 'block';

get '/allowed/:param' => sub {
    my $self = shift;
    $self->render(json => \%store );
};

get '/blocked/:param' => sub {
    my $self = shift;
    &block($self);
    $self->render(json => \%blstore );
};

get '/top/clients' => sub {
	my $self = shift;
	my %top;
	my $i =0;
	foreach my $name (sort { $clients{$b} <=> $clients{$a} } keys %clients) {
        $top{$name} = $clients{$name};
        say "$name => $clients{$name}";
                $i++;
        if ($i > 29) {
			last;
		}
    }
    $self->render(json => \%top);
};

 sub block {
    my $c      = shift;
    my $param = $c->param('param');
    my @args = split /:/, $param;
    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my (
        $second,    $minute,    $hour,
        $day,       $m,         $yearOffset,
        $dayOfWeek, $dayOfYear, $daylightSavings
    ) = localtime();
    my $year = 1900 + $yearOffset;

    # fix 0 index of month. (Jan = 0)
    $m++;
    my $t;

    # custome date entry
    if ( defined $args[0] && defined $args[1] ) {
        $day = $args[1];
        $m   = ( $args[0] - 1 );
    }
    my $month = $months[$m];
    my $basename = sprintf( "%04d-%02d-%02d:%02d", $year, $m, $day, $hour );
    say $basename;
    my $err = &main( $year, $month, $m, $day, $basename, $logfile );
    if ( $err != 0 ) {
        $c->render( text => "No results found for $param" );
        return !! 1;
    }
    return !! 0;
};

sub main {
    my ( $year, $month, $m, $day, $basename, $file ) = @_;
    say "$year, $month, $m, $day, $basename, $file";

    # check if log file exists.
    if ( !-f $file ) {
        say "Log file missing!";

        #server is not public. regerate for every request.
        # check if file are already generated for this hour
        # finally generate plots
    }
    elsif ($aget == 0) {
        say "Performing calculations!";
        my $err = &process( $year, $month, $m, $day, $basename, $file );
        if ( $err != 0 ) {
            warn "Error processing failed!";
            return !!1;
        }
        $aget++;
    } else {
        say "Skipping calcualtions!";
        if ($aget > 2) {
            $aget = 0;
        } else {
            $aget++;
        }
    }

    return !!0;
}

sub process {
    my ( $year, $month, $m, $day, $basename, $file ) = @_;
    my $dt = DateTime->new(
        year   => $year,
        month  => $m,
        hour   => 0,
        minute => 0,
    );
    my %domains;
    my %bdomains;
    delete @clients{ keys %clients };
    delete @blstore{ keys %blstore };
    delete @store{ keys %store };
    $numq = $numqb = 0;
    open( my $FH, "<", $file ) or die "Can't open $file";

    # force scalar context for $day as the logfile is has single digit
    # date format: Apr 1
    $day = $day + 0;
    while (<$FH>) {
        my $string = sprintf "%02d:%02d", $dt->hour, $dt->minute;
        if (m/^$month( +)$day/) {
            my $count = 0;
            while (1) {
                $string = sprintf "%02d:%02d", $dt->hour, $dt->minute;
                if ( !m/$string/ ) {
                    $dt->add( minutes => 1 );
                    $count++;
                    my $s = sprintf "%02d:%02d", $dt->hour, $dt->minute;
                    if ( !defined $store{$s} ) {
                        $store{$s} = 0;
                    }
                }
                else {
                    # split up text to remove various data points.
                    # remove multiple space as it ruins simple matching log
                    # below
                    $_ =~ s/ +/ /g;
                    my @words = split / /, $_;
                    if (m/query/) {
                        $domains{ $words[7] }++;
                        my @host = split /\//, $words[5];
                        $clients{ $host[0] }++;
                        my $s = sprintf "%02d:%02d", $dt->hour, $dt->minute;
                        $store{$s}++;
                        $numq++;
                    }
                    elsif (m/blocklist.txt/) {
                        $bdomains{ $words[7] }++;
                        my $s = sprintf "%02d:%02d", $dt->hour, $dt->minute;
                        $blstore{$s}++;
                        $numqb++;

                    }
                    $count = 0;
                    last;
                }
                if ( $count > 61 ) {
                    next;
                }
            }

        }
    }
    if ( $numq == 0 ) {
        return !!1;
    }
    return !!0;
}
#	<%= timeseries %> 
app->start;

__DATA__

@@ block.html.ep
<!DOCTYPE HTML>

<html>
<head>

<meta charset="UTF-8">
<script>
window.onload = function () {

    var dataPoints = [];
    $.getJSON("/blocked/<%= thisparam %>", function(data) {
        $.each(data, function(key, value){
        time = key.split(/\:|\-/g);
        dataPoints.push({x: new Date(2018, 05, 09, time[0], time[1]),y: parseInt(value)});
        });
    var chart = new CanvasJS.Chart("chartContainer", {
    theme: "light2", // "light1", "light2", "dark1", "dark2"
    animationEnabled: true,
    zoomEnabled: true,
    title: {
        text: "Blocked Queries"
    },
    axisX:{
        //Try Changing to MMMM
        valueFormatString: "HH:mm"
      },
        data: [{
        type: "line",
        color: "red",
        dataPoints : dataPoints,
        }],
    });
        chart.render();
	    var sum = 0;
	    for( var i = 0; i < chart.options.data[0].dataPoints.length; i++ ) {
	        sum += chart.options.data[0].dataPoints[i].y;
	    }
	    $( "#sumblocked" ).html( "Total blocked: " + sum );

        });


     var dataPoints2 = [];
        $.getJSON("/allowed/<%= thisparam %>", function(data) {
            $.each(data, function(key, value){
            time = key.split(/\:|\-/g);
            dataPoints2.push({x: new Date(2018, 05, 09, time[0], time[1]),y: parseInt(value)});
            });
        var chart2 = new CanvasJS.Chart("chartContainer2", {
        theme: "light2", // "light1", "light2", "dark1", "dark2"
        animationEnabled: true,
        zoomEnabled: true,
        title: {
            text: "Total Queries"
        },
        axisX:{
            //Try Changing to MMMM
            valueFormatString: "HH:mm"
          },
            data: [{
            type: "line",
            color: "green",
            dataPoints : dataPoints2,
            }],
        });
	    chart2.render();
	    var sum = 0;
	    for( var i = 0; i < chart2.options.data[0].dataPoints.length; i++ ) {
	        sum += chart2.options.data[0].dataPoints[i].y;
	    }
	    $( "#sumallowed" ).html( "Total queries: " + sum );
        });
    
     var dataPoints3 = [];
        $.getJSON("/top/clients", function(data3) {
            $.each(data3, function(key, value){
				            console.log("Key " + key + " value " + value);
            dataPoints3.push({y: parseInt(value), label: key});
            });
        var chart3 = new CanvasJS.Chart("chartContainer3", {
        animationEnabled: true,
	
		title:{
			text:"Top Clients",
			fontSize: 18
		},
		axisX:{
			   labelFontSize: 16,
			interval: 1
		},
		axisY2:{
			interlacedColor: "rgba(1,77,101,.2)",
			gridColor: "rgba(1,77,101,.1)",
			title: "Number of Queries",
			   labelFontSize: 16

		},
            data: [{
			type: "bar",
			name: "companies",
			axisYType: "secondary",
			color: "#014D65",
            dataPoints : dataPoints3,
            			fontSize: 12
            }],
        });
        sortDataSeries(chart3);
        function sortDataSeries(chart){
    var total = [];
    var tempTotal, temp;
    var dpsTotal = 0;
    for(var j = 0; j < chart.options.data[0].dataPoints.length; j++) {
      dpsTotal = 0;
      for(var i = 0; i < chart.options.data.length; i++) {
        dpsTotal += (chart.options.data[i].dataPoints[j].y)
      }
      total.push(dpsTotal);
    }
		 
    for(var i = 0; i < total.length; i++) {        
      for( var j = 0; j < total.length - i - 1; j++){      
        if(total[j] > total[j+1]) {
        	tempTotal = total[j];
          total[j] = total[j+1];
          total[j+1] = tempTotal;
          for(var k = 0; k < chart.options.data.length; k++){
            temp = chart.options.data[k].dataPoints[j];
            chart.options.data[k].dataPoints[j] = chart.options.data[k].dataPoints[j+1];
            chart.options.data[k].dataPoints[j+1] = temp;
          }
        }
      }
    }    
}
	    chart3.render();
        });
        

}
</script>
</head>
<body>

	<%= stats %> 

<div id="chartContainer" style="height: 400px; max-width: 1400px; margin: 0px auto;"></div>
<div id="sumblocked"></div>
<div id="chartContainer2" style="height: 400px; max-width: 1400px; margin: 0px auto;"></div>
<div id="chartContainer3" style="height: 1400px; max-width: 1400px; margin: 0px auto;"></div>

<div id="sumallowed"></div>

<script src="/canvasjs.min.js"></script>
<script type="text/javascript" src="https://canvasjs.com/assets/script/jquery-1.11.1.min.js"></script>
</body>
</html>

