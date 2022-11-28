
/********************************
PREDICT COUNTY LEVEL COVERAGE
	This file will take the coefficients from the first stage prediction
	equation and compute predicted coverage levels for each station/county pair.
	We will then collapse and save county level coverage for all counties. This 
	will then be merged to the student level data which will be drawn from a 
	bootstrap random sample with replacement.
Start Date: February 16, 2015
Prepared by: Riley Wilson

Compiled by George Zuo for use in "0_RunAll.do"
Compilation Date: June 20, 2018

Data needed:
	stage2_sample.dta
********************************/
cd "$temp"
use stage2_sample, clear

gen covratehat = b[1,1]*distance+b[1,2]*uhf+b[1,3]*dist_uhf+ b[1,4]*hgtground+ ///
				 b[1,5]*power_vis+b[1,6]

*Now we must deal with stations that are over 200 miles away
replace covratehat = . if distance>20 
replace lattower = . if distance>20
replace longtower = . if distance>20
*We are going to define a counties coverage by its highest predicted coverage rate
bys stfips_hh ctyfips_hh: egen maxcov = max(covratehat)
gen channel_best = channel if covratehat == maxcov
*for our third measure we will use areas with low vhf coverage as control
gen maxvhfcov= covratehat if channel<=13
*Lets also preserve the coordinates of the max coverage station
gen latstation = lattower if channel_best~=.
gen longstation = longtower if channel_best~=.
gen maxpbs = pbs==1 if channel_best~=.
gen st_best = station if channel_best~=.
gsort stfips_hh ctyfips_hh -st_best
replace st_best = st_best[_n-1] if stfips_hh==stfips_hh[_n-1] & ctyfips_hh==ctyfips_hh[_n-1] & _n~=1
*get the time the station with the best coverage was played
gen time1 = showtime1 if channel_best~=.
gen time2 = showtime2 if channel_best~=.
gen time3 = showtime3 if channel_best~=.
gen time4 = showtime4 if channel_best~=.
collapse (max) covratehat channel_best maxvhfcov lathh longhh pop70 latstation ///
				longstation maxpbs time1 time2 time3 time4 , by(stfips_hh ctyfips_hh ctyname stname state st_best)

rename stfips_hh stfips
rename ctyfips_hh ctyfips
replace st_best = "" if covratehat == . //For counties with no coverage there should be no station
replace covratehat = 0 if covratehat <0 //We are replacing negative predicted coverage with 0 coverage
*Specification 1: Linear Predicted Coverage Rate
*Make it something easier to interpret in regression
replace covratehat = covratehat/100

geodist lathh longhh latstation longstation, gen(distance) miles

*Specification 2: Assign each county to UHF or VHF best Sesame Street Broadcast station
gen uhfbest = channel_best>13
gen vhfbest = channel_best<=13

*Specification 3: Flag counties that are within the top 100 or 200 counties by population
gsort - pop70
gen ctypoprank = _n
gen large100cty = ctypoprank<=100
gen large200cty = ctypoprank<=200

*Specification 4: Flag counties that have VERY LOW VHF coverage
gen vhfover_50 = maxvhfcov>=50

*Specification 5: Flag counties where the best broadcast station played in the morning only
for X in any 1 2 3 4: replace timeX = . if covratehat == 0
egen earliest = rowmin(time1 time2 time3 time4)
egen latest = rowmax(time1 time2 time3 time4)

gen morningonly = latest<=12
replace morningonly = . if latest==.
gen eveningonly = earliest>12 & earliest~=.
replace eveningonly = . if earliest==.
gen bothtimes = (earliest<=12 & latest>12 & latest~=.)
replace bothtimes = . if latest==. | earliest == .

gen whenshow = "both" if bothtimes==1
replace whenshow = "morning" if morningonly==1
replace whenshow = "evening" if eveningonly==1

save predicted_cov, replace
