
/******************************
PREDICTION SECOND STAGE AND ESTIMATION
	This file gets the Sesame Street broadcasting station/county pairs ready to
	have their coverage rate predicted in the bootstrap.

Start Date: Feb. 16, 2015
Prepared by: Riley Wilson

Compiled by George Zuo for use in "0_RunAll.do"
Compilation Date: June 20, 2018

Data Needed:
	pbstowers.dta 	counties.dta 	SSstations.dta
*These datasets have already been cleaned from manual errors.
********************************/

/*Now that we have the prediction equation, we need to create a dataset of 
Sesame Street broadcasting station/county pairs to estimated the predicted 
coverage of Sesame Street. */

*First merge commercial and PBS stations to get all existing stations
cd "$raw"
use commtowers, clear
gen pbs = 0
append using pbstowers
replace pbs = 1 if pbs == .

*merge on Sesame Street broadcast data to get all of the stations that played SS.
merge m:1 station using SSstations, gen(merge2)
*There is one station that broadcast SS in Marquette Michigan that doesn't merge, the rest don't show it.
drop if merge2~=3
drop merge2
cd "$temp"
save station_points, replace

***********PREDICT COVERAGE RATES****************

gen id = _n
global num = _N
cd "$temp"
save sstowers, replace

use "$raw/counties", clear
*I will now compute the coverage between EVERY county and EVERY station.
expand $num
bys stfips_hh ctyfips_hh: gen id = _n
merge m:1 id using sstowers, gen(merge3)
drop merge3

*calculate the distance between county centroids and stations
geodist lathh longhh lattower longtower, gen(distance) miles

*We will use the same cutoffs as above 
replace distance = distance/10
replace hgtground = hgtground/100
replace power_vis = power_vis/100
*Now we will calculate the predicted coverage rate
gen uhf = channel>13
gen dist_uhf = distance*uhf

save stage2_sample, replace

