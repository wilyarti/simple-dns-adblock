set datafile separator ","
set timefmt '%Y-%m-%d %H:%M:%S'

set xlabel "Time"
set ylabel "Queries Per Minute" 

set xdata time
set grid

#set xzeroaxis linetype 3 linewidth 1.5

#set style line 1 linetype 1 linecolor rgb "green" linewidth 1.000
#set style line 2 linetype 1 linecolor rgb "red" linewidth 1.000

set terminal png size 4000, 600
set output "chart_1.png"

set xrange ['2018-02-25 00:00':'2018-02-25 23:59']
set format x '%Y-%m-%d %H:%M:%S'
set autoscale y

plot 'plot.dat' u 1:($2) with lines
