/***************************************************
High School and Beyond Analysis
Start Date: 10/1/2014
Prepared By: Riley Wilson
Compiled by George Zuo for use in "0_RunAll.do"
Compilation Date: June 20, 2018

This do.file contains the bulk of our analysis and estimation procedures.

Data Needed:
	allyrs_v1.dta				Includes all of the High School and Beyond (HSB) data 
	SScovcty_final.dta			County Level predicted Coverage Rates
	fs_background.dta			food stamps funding rates
	ludwig_miller_HSspend		Head start county level funding
	school_cutoffs				State level school entry laws
	
**************************************************/

**********************************
*Before starting analysis we are going to do some data preparation
**********************************

*First we are going to merge in the Food Stamps and Head Start variables

/* Merge in data on the availability of Food Stamps in the individual's county
at the time of starting school and the fraction of the child's life between
ages 0 and 6 that Food Stamps were available. These data were provided by
Diane Schanzenbach.
*/
cd "$temp"
use "$raw/fs_background", clear
keep stfips countyfips fs_month fs_year
rename countyfips ctyfips

merge 1:m ctyfips stfips using "$raw/allyrs_v1"

tab _merge
keep if _merge == 3
drop _merge

gen fsage6 = (fs_year<=1970 & sophomore==1) | (fs_year<=1968 & senior==1)
gen fsage0_6 = (fs_year<1970 & sophomore==1) | (fs_year<1968 & senior==1)
	 
gen yearage6 = 1970 if sophomore == 1
replace yearage6 = 1968 if senior == 1

save temp, replace

/* Merge in data on Head Start spending in the individual's county in the year
the individual was age 4. These data are available from Ludgwig and Miller's
2007 QJE paper. Values are only available for 1968 and 1972. I linearly
interpolate between those years to fill in. No spending took place before
1968*/ 

use "$raw/ludwig_miller_HSspend", clear

rename qje68 hsspend68
rename qje72a hsspend72

keep oldcode hsspend* pop70
merge 1:m oldcode using "$raw/ludwig_miller_fipsrecode"
tab _merge
keep if _merge == 3
drop _merge

rename state stfips
rename county ctyfips
drop if ctyfips == .
sort cfips90
drop if cfips90 == cfips90[_n-1]

reshape long hsspend, i(cfips90) j(year)

expand 6
sort cfips90 year

replace year = year + 1900
replace year = 1963 if cfips90 ~= cfips90[_n-1] & year == 1968
replace year = year[_n-1] + 1 if cfips90 == cfips90[_n-1]
replace hsspend = 0 if year <= 1967
replace hsspend = .75*hsspend[_n-1] + .25*hsspend[_n+3] if year == 1969
replace hsspend = .5*hsspend[_n-2] + .5*hsspend[_n+2] if year == 1970
replace hsspend = .25*hsspend[_n-3] + .75*hsspend[_n+1] if year == 1971

gen hspercap = hsspend/pop70
drop if year > 1971
gen yearage6 = year+2
drop cfips90 oldcode year pop70
*We don't have birthdays for all of the senior sample, so we are going to go with
*the assumption that the seniors started in 1968 and the sophomores in 1970.
keep if inlist(year,1968,1970)
reshape 
merge 1:m ctyfips stfips yearage6 using temp
keep if _m==3

*ADDITIONAL ADJUSTMENTS

*create proper weighting variable
gen mixwt = 0
replace mixwt = DESIGNWT if (senior==1 & DESIGNWT~=.)
replace mixwt = BYWT if (sophomore==1 & BYWT~=.) //WE NEED TO DECIDED HOW WE ARE GOING TO WEIGHT THIS. I AM CURRENTLY USING BYWT

*We want test outcomes to be interpreted as percentages
foreach test in math vocab read {
	gen std`test' = .
	qui sum `test'_pctsryr if sophomore==1, detail
	replace std`test' = (`test'_pctsryr-r(mean))/r(sd) if sophomore==1
	qui sum `test'_pctsryr if senior==1, detail
	replace std`test' = (`test'_pctsryr-r(mean))/r(sd) if senior==1
}
for X in any math vocab read : replace X_pctsryr = 100*X_pctsryr

*Create Urban/Rural indicators
bys schoolid: egen tempurban = max(SCHURB)
gen urban = tempurban==1
gen rural = tempurban==3
gen suburb = tempurban==2
for X in any urban rural suburb: replace X = . if tempurban==.


***********************
*Create Socio-Emotional Indices
***********************
*For now I am going to create an index for locus of control and self_concpt

*LOCUS OF CONTROL and SELF ESTEEM: 
/* It seems unclear how to interpret the coefficients for the current locus of control. I am going to recreate it by
(1) standardizing each of the four questions over the entire sample's senior year response
(2) average these four responses to create the Locus of control. 
I think this is what they did, but they standardized within weighted cohort. And it is unclear how they have values as large as 8 */
foreach var in luckoverwork peoplestopme planningpaysoff acptlife ///
			   pstv_self selfworth goodasothers stsfy_self{
	gen temp`var' = .
	replace temp`var' = 0 if scale_`var'_sryr==5
	replace temp`var' = -2 if scale_`var'_sryr==4
	replace temp`var' = -1 if scale_`var'_sryr==3
	replace temp`var' = 1 if scale_`var'_sryr==2
	replace temp`var' = 2 if scale_`var'_sryr==1
	qui sum temp`var'
	replace temp`var' = (temp`var'-r(mean))/r(sd)
}
for X in any luckoverwork peoplestopme planningpaysoff acptlife : replace tempX = -tempX //These are all negative control measures. This is to help us understand direction of coefficients
egen locusindex = rowmean(templuckoverwork temppeoplestopme tempplanningpaysoff tempacptlife) 
qui sum locusindex
replace locusindex = (locusindex - r(mean))/r(sd)
egen esteemindex = rowmean(temppstv_self tempselfworth tempgoodasothers tempstsfy_self)
qui sum esteemindex
replace esteemindex = (esteemindex - r(mean))/r(sd)

*Define our Cohorts
gen sr82 = sophomore

***Merge on State School Cut off Information:
merge m:1 state using "$raw/school_cutoffs", gen(alltocutoffs) //all but Hawaii and Alaska match
drop if alltocutoffs~=3
drop alltocutoffs
/*Now we want to flag all students who by State Law, should have started 
1st grade in 1970 or later -- and thus are intended to treat. This means that 
they were born after the 1963 birth (1969 first grade) cut off. This should 
include most all of our Sophomore Cohort */
gen bylawstart1970 = birthdate>cutoffdate1969 & sophomore==1 
replace bylawstart1970 = 1 if cutoffdate1969==. & sophomore==1 //for those states where left to local discretion.
/*THIS CURRENTLY INCLUDES THOSE SOPHOMORES WHO DO NOT HAVE A REPORTED BIRTHDATE 
AND ALL SOPHOMORES IN STATES WHERE CUT OFF DATES ARE LEFT TO LOCAL DISCRETION.
WE ARE ACTING AS THOUGH THEY ALL ARE TREATED. */

/*We are going to merge on the coverage data, so that we can get the appropriate
 sample, but then we need to drop the coverage variables to get the correct 
 bootstrapped coverage.*/
merge m:1 stfips ctyfips using predicted_covhsb, gen(hsbtocov)
keep if hsbtocov==3
*base model
gen covratehatsr82 = covratehat*sr82
*by law model
gen covratehatbylaw1970 = covratehat*bylawstart1970
*alternative coverage measures
gen highcov = covratehat>.50
gen highcovsr82 = highcov*sr82
gen vhfbestsr82 = vhfbest*sr82
gen vhfover_50sr82 = vhfover_50*sr82

*create stateXcohort FE
egen statecohort = group(stfips sophomore)
egen statecohort2 = group(stfips bylawstart1970)
*This is the data we will use for the bootstrap
save hsbdata_all, replace
