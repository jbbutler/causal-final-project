
/**************************************
PREDICTION FIRST STAGE
	This file gets the dataset ready for the first stage of the prediction so 
	that we can perform the bootstrap.
	
Start Date: Feb. 16, 2015
Prepared by: Riley Wilson

Compiled by George Zuo for use in "0_RunAll.do"
Compilation Date: June 20, 2018

Data Needed:
	coverage.dta 	commtowers.dta 
*These datasets have already been cleaned from manual errors.
************************************/
*ssc install geodist //this command will compute the distance between two lat/long points

/*First we will combine county level coverage data (coverage.dta) with tower 
level characteristics (commtowers.dta) and regress characteristics on coverage 
to get a prediction equation */

cd "$raw"
use coverage, clear
merge m:1 station channel using commtowers, gen(merge1)
*All but 5 from master and 3 from using merge. Most of these are because there isn't circulation data or they are satellite stations.
keep if merge1 == 3
drop merge1

*drop satellite stations 
drop if satellite ~=0

*Now we need to determine the distance between station towers and 1970 county population centroids
geodist lathh longhh lattower longtower, gen(distance) miles

drop if inlist(state_station, "Hawaii", "Alaska")
keep if distance<=200 //we are going to throw out extreme outliers
replace distance = distance/10
replace hgtground = hgtground/100
replace power_vis = power_vis/100

/*Currently we have coverage in probability bins, we are going to assign 
continuous values and use OLS to predict coverage. We have selected the following
values in order to predict as accurately as possible the nation coverage rate. */

gen covrate2 = 20 if covrate == "5-24%"
replace covrate2 = 40 if covrate == "25-50%"
replace covrate2 = 90 if covrate == "over 50%"

*create our explanatory variables
gen dist_uhf = distance*uhf


*Estimate the Relationship
reg covrate2 distance uhf dist_uhf hgtground power_vis [aweight=totalhh]
keep if e(sample)

*we will cluster the randomization at the station level so I need a station indicator
egen stationid = group(station)
cd "$temp"
save stage1_sample, replace
