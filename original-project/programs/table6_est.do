capture log close
log using "$logs/table6.log", replace

/************************************
THE IMPACT OF SESAME STREET OF CHILDHOOD OUTCOMES: BOOTSTRAPPED CENSUS INFERENCE
	This file takes the data from the commercial stations, the Sesame Street
	stations, and the HSB student level data and prepares it for analysis. Then
	in one combined program, we:
	(1) select a _N random sample with replacement of the commercial stations 
	and estimate the prediction equation
	(2) use this prediction equation to identify the station with the best 
	coverage for each county, and estimate that coverage level.
	(3) select a _N random sample with replacement of the HSB students which is 
	then merged to the coverage data.
	(4) perform our estimation of the effect of SS on cognitive and noncognitive 
	outcomes
	(5) repeat this 400 times to get bootstrapped standard errors, to account 
	for the fact that we are predicting the first stage.
Start Date: February 16, 2015
Prepared by: Riley Wilson

Compiled by George Zuo for use in "0_RunAll.do"
Compilation Date: June 20, 2018

Data Needed:
	coverage.dta 	commtowers.dta 
	pbstowers.dta 	counties.dta 		SSstations.dta
	
***************************************/

set more off
set matsize 1000
cap ssc install reghdfe
/* At this point I would set all of the globals that I will use throughout. The 
do files that I recall require some so I will set them here.
*/
*Set globals 

global final "$temp"
global tables "$output"
global dofiles "$prog/bs_dofiles"

*independent control variables
global controls "momhsdrop2 momhsgrad2 livwmom blacknh othernh hispanic female hspercap fsage6 fsage0_6 start66 start67 start68 start69 start70 start71 start72 start73 start74"
global controls902000 "blacknh othernh hispanic female hspercap fsage6 fsage0_6 start66 start67 start68 start69 start70 start71 start72 start73 start74"
/*We are going to store our estimated coefficients and standard errors in a matrix 
that we will then turn into a table */
matrix define census4a = J(4,6,.) //Table 4A: 6 different groups
matrix define census4b = J(9,6,.) //Table 4B: 6 different groups

*Some data prep
do "$bs_dofiles/census90_toestimate.do"
do "$bs_dofiles/census2000_toestimate.do"

/**************
*Table 6
Aggregate Impact of Sesame Street on Educational Attainment and 
Labor Market Outcomes in the 1990 and 2000 Census, Aggregate and Event Study
***************/
cd "$final" 
use census90, clear
local outcomes = "hsdrop hsgrad anycol"
local n1 : word count `outcomes'
forval i = 1/`n1' {
	local outcome : word `i' of `outcomes'
	
	reghdfe `outcome' preschlcov $controls902000, absorb(statecty statecohort) vce(cluster statecty) keepsingleton
	matrix define census6a[1,`i'] = _b[preschlcov]
	matrix define census6a[3,`i'] = e(N) //preserve sample size
	qui sum `outcome' if e(sample)
	matrix define census6a[4,`i'] = r(mean) //preserve dependent mean
	
	reghdfe	`outcome' covst6768 covst69 covst7072 covst7374 covratehat $controls902000 , absorb(statecty statecohort) vce(cluster statecty) keepsingleton
	matrix define census6b[1,`i'] = _b[covst6768]
	matrix define census6b[3,`i'] = _b[covst69]
	matrix define census6b[5,`i'] = _b[covst7072]
	matrix define census6b[7,`i'] = _b[covst7374]
	matrix define census6b[9,`i'] = e(N)
}

cd "$final"
use census2000, clear
local outcomes = "lnhrwage working inpov"
local n1 : word count `outcomes'
forval i = 1/`n1' {
	local outcome : word `i' of `outcomes'
	local l = `i'+3 //columns 4-6
	
	reghdfe `outcome' preschlcov $controls902000 , absorb(statecty statecohort) vce(cluster statecty) keepsingleton
	matrix define census6a[1,`l'] = _b[preschlcov]
	matrix define census6a[3,`l'] = e(N) //preserve sample size
	qui sum `outcome' if e(sample)
	matrix define census6a[4,`l'] = r(mean) //preserve dependent mean
	
	reghdfe	`outcome' covst6768 covst69 covst7072 covst7374  $controls902000 , absorb(statecty statecohort) vce(cluster statecty) keepsingleton
	matrix define census6b[1,`l'] = _b[covst6768]
	matrix define census6b[3,`l'] = _b[covst69]
	matrix define census6b[5,`l'] = _b[covst7072]
	matrix define census6b[7,`l'] = _b[covst7374]
	matrix define census6b[9,`l'] = e(N)
}
/**/
/**/

*******************************************		 
****BOOTSTRAP PROGRAM FOR TABLE 6 (90) ****
*******************************************
*We will cluster the Bootstrap at the county level
cap program drop bootstrapcensus690
program define bootstrapcensus690, rclass
	cd "$final"
	*First Stage
	use stage1_sample, clear
	*Get our Random Sample with Replacement
	bsample , cluster(stationid)
	*Estimate Prediction Equation
	qui reg covrate2 distance uhf dist_uhf hgtground power_vis [aweight=totalhh], cluster(stationid) robust
	matrix b = e(b)
	*Second Stage
	cd "$dofiles"
	qui do predict_cov.do
	gen statecty = 1000*stfips+ctyfips
	replace statecty = 12086 if statecty == 12025
	save predicted_cov, replace
	*Census Data
	cd "$final" 
	use census90, clear
	local outcomes = "hsdrop hsgrad anycol"
	local n1 : word count `outcomes'
	forval i = 1/`n1' {
		local outcome : word `i' of `outcomes'
		preserve
		qui reg `outcome' preschlcov preschl69 covratehat covst6768 covst69 covst7072  covst7374 $controls902000
		keep if e(sample)
		*Drop the Coverage Variables
		drop covratehat preschlcov 
		*Draw BS sample
		bsample, cluster(dmaindex)
		*Merge on the coverage data
		cd "$final"
		merge m:1 statecty using predicted_cov, gen(censustocov)
		keep if censustocov == 3
		gen preschlcov = preschl69*covratehat
		
		reghdfe `outcome' preschlcov $controls902000, absorb(statecty statecohort) vce(cluster dmaindex) keepsingleton
		return scalar tot_group`i' = _b[preschlcov]
		
		reghdfe `outcome' covst6768 covst69 covst7072  covst7374 $controls902000, absorb(statecty statecohort) vce(cluster dmaindex) keepsingleton
		return scalar yr_group`i'_2 = _b[covst6768]
		return scalar yr_group`i'_4 = _b[covst69]
		return scalar yr_group`i'_6 = _b[covst7072]
		return scalar yr_group`i'_8 = _b[covst7374]
		restore
	}
end

/*Now that we have a program that gets the bootstrap samples and estimates, we
will simulate to get our 400 bootstrap estimates to obtain bootstrapped 
standard errors */
cd "$final"

simulate tot_group1 = r(tot_group1) tot_group2 = r(tot_group2) ///
		 tot_group3 = r(tot_group3) ///
		 ///
		 yr_group1_2 = r(yr_group1_2) yr_group2_2 = r(yr_group2_2) ///
		 yr_group3_2 = r(yr_group3_2) ///
		 ///
		 yr_group1_4 = r(yr_group1_4) yr_group2_4 = r(yr_group2_4) ///
		 yr_group3_4 = r(yr_group3_4) ///
		 ///
		 yr_group1_6 = r(yr_group1_6) yr_group2_6 = r(yr_group2_6) ///
		 yr_group3_6 = r(yr_group3_6) ///
		 ///
		 yr_group1_8 = r(yr_group1_8) yr_group2_8 = r(yr_group2_8) ///
		 yr_group3_8 = r(yr_group3_8) ///
		 ///
		 , reps(400) saving(census_bootstrap690, replace) seed(3865788): bootstrapcensus690


*********************************************	
****BOOTSTRAP PROGRAM FOR TABLE 6 (2000) ****
*We will cluster the Bootstrap at the county level
cap program drop bootstrapcensus62000
program define bootstrapcensus62000, rclass
	cd "$final"
	*First Stage
	use stage1_sample, clear
	*Get our Random Sample with Replacement
	bsample , cluster(stationid)
	*Estimate Prediction Equation
	qui reg covrate2 distance uhf dist_uhf hgtground power_vis [aweight=totalhh], cluster(stationid) robust
	matrix b = e(b)
	*Second Stage
	cd "$dofiles"
	qui do predict_cov.do
	gen statecty = 1000*stfips+ctyfips
	save predicted_cov, replace
	*Census Data
	cd "$final"
	use census2000, clear
	local outcomes = "lnhrwage working inpov"
	local n1 : word count `outcomes'
	forval i = 1/`n1' {
		local outcome : word `i' of `outcomes'
		local l = `i'+3 //columns 4-6
		preserve
		qui reg `outcome' preschlcov preschl69 covratehat covst6768 covst69 covst7072  covst7374 $controls902000 
		keep if e(sample)
		*Drop the Coverage variables
		drop covratehat preschlcov
		*Draw the BS sample
		bsample, cluster(dmaindex)
		*Merge on the coverage data
		cd "$final"
		merge m:1 statecty using predicted_cov, gen(censustocov)
		keep if censustocov == 3
		gen preschlcov = preschl69*covratehat
		
		reghdfe `outcome' preschlcov $controls902000, absorb(statecty statecohort) vce(cluster dmaindex) keepsingleton
		return scalar tot_group`l' = _b[preschlcov]
		
		reghdfe `outcome' covst6768 covst69 covst7072  covst7374 $controls902000, absorb(statecty statecohort) vce(cluster dmaindex) keepsingleton
		return scalar yr_group`l'_2 = _b[covst6768]
		return scalar yr_group`l'_4 = _b[covst69]
		return scalar yr_group`l'_6 = _b[covst7072]
		return scalar yr_group`l'_8 = _b[covst7374]
		restore
	}
end
/*Now that we have a program that gets the bootstrap samples and estimates, we
will simulate to get our 400 bootstrap estimates to obtain bootstrapped 
standard errors */
cd "$final"

simulate tot_group4 = r(tot_group4) tot_group5 = r(tot_group5) ///
		 tot_group6 = r(tot_group6) ///
		 ///
		 yr_group4_2 = r(yr_group4_2) yr_group5_2 = r(yr_group5_2) ///
		 yr_group6_2 = r(yr_group6_2) ///
		 ///
		 yr_group4_4 = r(yr_group4_4) yr_group5_4 = r(yr_group5_4) ///
		 yr_group6_4 = r(yr_group6_4) ///
		 ///
		 yr_group4_6 = r(yr_group4_6) yr_group5_6 = r(yr_group5_6) ///
		 yr_group6_6 = r(yr_group6_6) ///
		 ///
		 yr_group4_8 = r(yr_group4_8) yr_group5_8 = r(yr_group5_8) ///
		 yr_group6_8 = r(yr_group6_8) ///
		 ///
		 , reps(400) saving(census_bootstrap62000, replace) seed(3865788): bootstrapcensus62000
*/

/**/

*********************
*******Table 6

cd "$final"
use census_bootstrap690, clear
cd "$tables"
forval i = 1/3 {
	qui sum tot_group`i'
	matrix define census6a[2,`i'] = r(sd)
	forval j = 2(2)8 {
		qui sum yr_group`i'_`j'
		matrix define census6b[`j',`i'] = r(sd)
	}
}

cd "$final"
use census_bootstrap62000, clear
cd "$tables"
forval i = 1/3 {
	local l = `i'+3 //we need to fill in columns 4-6
	qui sum tot_group`l'
	matrix define census6a[2,`l'] = r(sd)
	forval j = 2(2)8 {
		qui sum yr_group`l'_`j'
		matrix define census6b[`j',`l'] = r(sd)
	}
}

cap file close census
file open census using census_table6.txt, write replace
file write census _tab "HS Dropout" _tab "HS Graduate" _tab "Any College" _tab "Log Hourly Wage" _tab "Employed" _tab "In Poverty" _n 
file write census "Mean Rate" 
*Panel A
forval i = 1/6 {
	file write census _tab %7.3f (census6a[4,`i']) 
}
file write census _n
file write census _tab "Aggregate Effect" _n
file write census "Preschool post-1969"
forval i = 1/6 {
	file write census _tab %7.3f (census6a[1,`i'])
}
file write census _n
file write census "*coverage rate"
forval i = 1/6 {
	file write census _tab "(" %5.3f (census6a[2,`i']) ")"
}
file write census _n
*Panel B
file write census _tab "Event Study Approach" _n
local years = `" "1967-68" "" "1969" "" "1970-72" "" "1973-74" "' 
forval j = 1(2)7 {
	local year : word `j' of `years'
	local k = `j'+1
	file write census "Coverage Rate*`year'"
	forval i = 1/6 {
		file write census _tab %7.3f (census6b[`j',`i'])
	}
	file write census _n
	forval i = 1/6 {
		file write census _tab "(" %5.3f (census6b[`k',`i']) ")"
	}
	file write census _n
}
file close census

cd "$prog"
cap log close
