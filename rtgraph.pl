#! /usr/bin/env perl
use 5.020;
use warnings;
use strict;
use Data::Dumper;
use Mojolicious::Lite;
use DateTime;
use Mojo::JSON qw(decode_json encode_json);
use File::Copy;
use DBI;


our $basename;
our %clients;
our $numq;
our $numqb;
our %store;
our $aget = 0;
our %blstore;
our $text_status;

our $logfile  = "/var/log/pihole.log";
our $wwwpath  = "/home/nobody/public/";
our $datapath = "/home/nobody/";

app->config( hypnotoad => { listen => ['http://*:8090'] } );

helper stats => sub {
    return $text_status;

};
helper thisparam => sub {
    my $c     = shift;
    my $param = $c->param('param');
    return $param;

};

get '/' => sub {
    my $self = shift;
    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my (
        $second,    $minute,    $hour,
        $day,       $m,         $yearOffset,
        $dayOfWeek, $dayOfYear, $daylightSavings
    ) = localtime();
    my $year = 1900 + $yearOffset;

    # fix 0 index of month. (Jan = 0)
    $m++;
    $self->redirect_to("$months[$m]-$day");

};
get '/:param' => 'block';

get '/allowed/:param' => sub {
    my $self   = shift;
    my $param  = $self->param('param');
    ## PARAM CHECK
    my @check = split /-/, $param;
    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my $i = 0;
    foreach (@months) {
        if ($check[0] eq $_) {
            $i++;
            last;
        }
    }
    for (1 .. 31) {
        if ($check[1] eq $_) {
            $i++;
            last;
        }
    }
    if ($i != 2) {
        say "invalid!";
       $self->render( text => "invalid" );
       return !! 1;
    }

    my $dbfile = "/home/undef/db.sqlite";
    my $dbh    = DBI->connect( "dbi:SQLite:dbname=$dbfile", "", "" );
    my %query;
    for ( 0 .. 23 ) {
        my $i = $_;
        for ( 0 .. 59 ) {
            my $s = sprintf "%02d:%02d", $i, $_;
            $query{$s} = 0;
        }
    }
    my $stmt = qq(SELECT time FROM query WHERE time like '$param-%' );
    my $sth  = $dbh->prepare($stmt);
    my $rv   = $sth->execute() or die $DBI::errstr;
    if ( $rv < 0 ) {
        print $DBI::errstr;
    }

    while ( my @row = $sth->fetchrow_array() ) {
        my @time = split /-/, $row[0];
        $query{ $time[2] }++;
    }
    $self->render( json => \%query );
};

get '/blocked/:param' => sub {
    my $self   = shift;
    my $param  = $self->param('param');
    ## PARAM CHECK
        my @check = split /-/, $param;
        my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
        my $i = 0;
        foreach (@months) {
            if ($check[0] eq $_) {
                $i++;
                last;
            }
        }
        for (1 .. 31) {
            if ($check[1] eq $_) {
                $i++;
                last;
            }
        }
        if ($i != 2) {
            say "invalid!";
           $self->render( text => "invalid" );
           return !! 1;
        }

    my $dbfile = "/home/undef/db.sqlite";
    my $dbh    = DBI->connect( "dbi:SQLite:dbname=$dbfile", "", "" );
    my %query;
    for ( 0 .. 23 ) {
        my $i = $_;
        for ( 0 .. 59 ) {
            my $s = sprintf "%02d:%02d", $i, $_;
            $query{$s} = 0;
        }
    }
    my $stmt = qq(SELECT time FROM blocked WHERE time like '$param-%' );
    my $sth  = $dbh->prepare($stmt);
    my $rv   = $sth->execute() or die $DBI::errstr;
    if ( $rv < 0 ) {
        print $DBI::errstr;
    }

    while ( my @row = $sth->fetchrow_array() ) {
        my @time = split /-/, $row[0];
        $query{ $time[2] }++;
    }
    $self->render( json => \%query );
};

get '/domain/:param' => sub {
    my $self   = shift;
    my $param  = $self->param('param');
    ## PARAM CHECK
        my @check = split /-/, $param;
        my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
        my $i = 0;
        foreach (@months) {
            if ($check[0] eq $_) {
                $i++;
                last;
            }
        }
        for (1 .. 31) {
            if ($check[1] eq $_) {
                $i++;
                last;
            }
        }
        if ($i != 2) {
            say "invalid!";
           $self->render( text => "invalid" );
           return !! 1;
        }


    my $dbfile = "/home/undef/db.sqlite";
    my $dbh    = DBI->connect( "dbi:SQLite:dbname=$dbfile", "", "" );

    my $stmt = qq(SELECT domain FROM blocked WHERE time like '$param%');
    my $sth  = $dbh->prepare($stmt);
    my $rv   = $sth->execute() or die $DBI::errstr;
    if ( $rv < 0 ) {
        print $DBI::errstr;
    }
	my %clients;
    while ( my @row = $sth->fetchrow_array() ) {
        $clients{ $row[0] }++;
    }
    my %top;
    my $i;
    foreach my $name ( sort { $clients{$b} <=> $clients{$a} } keys %clients ) {
            $top{$name} = $clients{$name};
            $i++;
            if ( $i > 29 ) {
                last;
            }
        }
    $self->render( json => \%top );
};


get '/top/clients' => sub {
    my $self   = shift;
    my $dbfile = "/home/undef/db.sqlite";
    my $dbh    = DBI->connect( "dbi:SQLite:dbname=$dbfile", "", "" );

    my $stmt = qq(SELECT source FROM query;);
    my $sth  = $dbh->prepare($stmt);
    my $rv   = $sth->execute() or die $DBI::errstr;
    if ( $rv < 0 ) {
        print $DBI::errstr;
    }
	my %clients;
    while ( my @row = $sth->fetchrow_array() ) {
        my @time = split /-/, $row[0];
        $clients{ $row[0] }++;
    }
    my %top;
    my $i;
    foreach my $name ( sort { $clients{$b} <=> $clients{$a} } keys %clients ) {
            $top{$name} = $clients{$name};
            $i++;
            if ( $i > 29 ) {
                last;
            }
        }
    $self->render( json => \%top );
};


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
    $.getJSON("/allowed/<%= thisparam %>", function(data) {
            $.each(data, function(key, value){
            time = key.split(/\:|\-/g);
            dataPoints.push({x: new Date(2018, 5, 9, time[0], time[1]),y: parseInt(value)});
            });

        var dataPoints2 = [];
        $.getJSON("/blocked/<%= thisparam %>", function(data) {
            $.each(data, function(key, value){
            time = key.split(/\:|\-/g);
            dataPoints2.push({x: new Date(2018, 5, 9, time[0], time[1]),y: parseInt(value)});
            });
            chart.render();
         });

        var chart = new CanvasJS.Chart("chartContainer", {
            theme: "light2", // "light1", "light2", "dark1", "dark2"
            animationEnabled: true,
            zoomEnabled: true,
            title: {
                text: "Queries"
            },
            axisX:{
                //Try Changing to MMMM
                valueFormatString: "HH:mm"
                },
                data: [{
                    type: "line",
                    color: "green",
                    dataPoints : dataPoints,
                },
                {
                    type: "line",
                    color: "red",
                    dataPoints : dataPoints2,
                }],
        });
        chart.render();

    });


    
     var dataPoints3 = [];
        $.getJSON("/domain/<%= thisparam %>", function(data3) {
            $.each(data3, function(key, value){
            dataPoints3.push({y: parseInt(value), label: key});
            });
        var chart3 = new CanvasJS.Chart("chartContainer3", {
        animationEnabled: true,
	
		title:{
			text:"Top Blocked Queries",
			fontSize: 18
		},
		axisX:{
			   labelFontSize: 12,
			interval: 1
		},
		axisY2:{
			interlacedColor: "rgba(1,77,101,.2)",
			gridColor: "rgba(1,77,101,.1)",

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

<div id="chartContainer" style="height: 300px; max-width: 1000px; margin: 0px auto;"></div>
<div id="chartContainer3" style="height: 800px; max-width: 1000px; margin: 0px auto;"></div>

<script src="https://canvasjs.com/assets/script/canvasjs.min.js"></script>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js"></script></body>
</html>

