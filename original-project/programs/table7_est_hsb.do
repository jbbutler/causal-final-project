
/************************************
THE IMPACT OF SESAME STREET OF CHILDHOOD OUTCOMES: BOOTSTRAPPED INFERENCE
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
	(5) repeat this 100 times to get bootstrapped standard errors, to account 
	for the fact that we are predicting the first stage.
Start Date: February 16, 2015
Prepared by: Riley Wilson

Compiled by George Zuo for use in "0_RunAll.do"
Compilation Date: June 20, 2018

Data Needed:
	coverage.dta 	commtowers.dta 
	pbstowers.dta 	counties.dta 		SSstations.dta
	school_cutoffs.dta					SScovcty_final.dta
	allyrs_v1.dta	fs_background.dta	ludwig_miller_HSspend
***************************************/
set more off
*Set globals 

global final "$temp"
global tables "$output"
global dofiles "$prog/bs_dofiles"
global regspecs "excel append bdec(4) nocons nor2"

global educ_momr "no_mom mom_lesshs mom_somecol mom_college momeduc_missing" //mom_hs base category
global educ_dadr "no_dad dad_lesshs dad_somecol dad_college dadeduc_missing" //dad_hs base category
global incomer "inc12_25 inc_over25 inc_missing" //inc_less12 base category
global racer "hisp black other_race" //white base category

global educ_mom "no_mom mom_lesshs mom_hs mom_somecol mom_college momeduc_missing" //This is for summary stats
global educ_dad "no_dad dad_lesshs dad_hs dad_somecol dad_college dadeduc_missing" //This is for summary stats
global income "inc_less12 inc12_25 inc_over25 inc_missing" //This is for summary stats
***Variable arrays:
global outcomes "stdmath stdvocab stdread ggrades_tosryr locusindex esteemindex nodis_prob_sryr dont_cutclass_sryr like_workatschool_sryr"
global outcomes_ss "math_pctsryr vocab_pctsryr read_pctsryr ggrades_tosryr locusindex esteemindex nodis_prob_sryr dont_cutclass_sryr like_workatschool_sryr"
global controls "male $racer $educ_momr $educ_dadr singleparent $incomer fsage0_6 hspercap" //urban and rural is captured by school FE
global covariates "male hisp black other_race white $educ_mom $educ_dad $income singleparent urban suburb rural otherlangathome"
***Sample specifications
global srsample "((FU1PART==1 & sophomore==1 & inlist(FUSTTYPE,1,3)) | (senior==1 & BYPART==1))"
global bysample " BYPART==1"
global finalsample "FU3PART~=."

/*We are going to store our estimated coefficients and standard errors in a matrix 
that we will then turn into a table */
local ys : word count $outcomes
matrix define base_hsb = J(5,`ys',.)
matrix define bylaw_hsb = J(5,`ys',.) //for now we are only going to look at the alternative specs. for those that are significant
matrix define alt_hsb = J(5,9,.) //for now we are only going to look at the alternative specs. for those that are significant
*******************************


*We will first get our Coefficient estimates:
cd "$final" 
use stage1_sample, clear
qui reg covrate2 distance uhf dist_uhf hgtground power_vis [aweight=totalhh], vce(cluster stationid)
matrix b = e(b)
*Now we use the estimated prediction equation to predict coverage for station/county pairs.
cd "$dofiles"
qui do predict_covhsb.do

*PREP FOR HSB ESTIMATION
qui do "$dofiles/hsb_toestimate.do"

*Now we merge to county coverage rate to the individual level for estimation
cd "$final"
use hsbdata_all, clear


*******************************

*Now we can begin analysis

*Base HSB Estimates
local num : word count $outcomes
forval i = 1/`num' {
	local outcome : word `i' of $outcomes
	areg `outcome' covratehatsr82 sr82 covratehat $controls i.statecohort if $srsample, absorb(schoolid) vce(cluster schoolid)
	matrix define base_hsb[1,`i'] = _b[covratehatsr82]
	matrix define base_hsb[3,`i'] = _b[sr82]
	matrix define base_hsb[5,`i'] = e(N)	
}

*Alternative Specifications
*State School Age Entry Law Cohort Definitions

local num : word count $outcomes
forval i = 1/`num' {
	local outcome : word `i' of $outcomes
	areg `outcome' covratehatbylaw1970 bylawstart1970 covratehat $controls i.statecohort2 if $srsample & (senior==1 | sophomore==1 & bylawstart1970==1), absorb(schoolid) vce(cluster schoolid)
	matrix define bylaw_hsb[1,`i'] = _b[covratehatbylaw1970]
	matrix define bylaw_hsb[3,`i'] = _b[bylawstart1970]
	matrix define bylaw_hsb[5,`i'] = e(N)	
}

*Alternative Coverage Specifications

local suboutcomes = "stdmath esteemindex like_workatschool_sryr"
local num : word count `suboutcomes'
forval i = 1/`num' {
	local outcome : word `i' of `suboutcomes'
	local j = 3*`i'-2
	local k = `j'+1
	local l = `k'+1
	*vhf vs. uhf
	areg `outcome' vhfbestsr82 sr82 vhfbest $controls i.statecohort if $srsample, absorb(schoolid) vce(cluster schoolid)
	matrix define alt_hsb[1,`j'] = _b[vhfbestsr82]
	matrix define alt_hsb[3,`j'] = _b[sr82]
	matrix define alt_hsb[5,`j'] = e(N)
	*vhf vs. uhf Top 100 counties
	areg `outcome' vhfbestsr82 sr82 vhfbest $controls i.statecohort if $srsample & large100cty==1, absorb(schoolid) vce(cluster schoolid)
	matrix define alt_hsb[1,`k'] = _b[vhfbestsr82]
	matrix define alt_hsb[3,`k'] = _b[sr82]
	matrix define alt_hsb[5,`k'] = e(N)
	*Any VHF over 50% coverage
	areg `outcome' vhfover_50sr82 sr82 vhfover_50 $controls i.statecohort if $srsample & large100cty==1, absorb(schoolid) vce(cluster schoolid)
	matrix define alt_hsb[1,`l'] = _b[vhfover_50sr82]
	matrix define alt_hsb[3,`l'] = _b[sr82]
	matrix define alt_hsb[5,`l'] = e(N)
}

/*Before we start our bootstrap, we are going to create a dataset that we can 
append the station/county coverage for each iteration to so that we can look 
at first stage variation */
clear
set obs 1
for X in any ctyfips stfips covratehat: gen X = .
cd "$final"
save predicted_bsvariation, replace
	
****************************************
*We will cluster the Bootstrap at the school level
cap program drop bootstrap2stage
program define bootstrap2stage, rclass
	cd "$final"
	*Coverage Prediction estimation
	use stage1_sample, clear
	*Get our Random Sample with Replacement
	bsample , cluster(stationid)
	*Estimate Prediction Equation
	qui reg covrate2 distance uhf dist_uhf hgtground power_vis [aweight=totalhh], vce(cluster stationid)
	matrix b = e(b)
	*Assign predicted coverage rates to Sesame Street Broadcasting stations
	cd "$dofiles"
	qui do predict_covhsb.do
	/*We are going to store the predicted coverage rates for each iteration, to 
	see how much variation there is in the first stage of predictions */
	keep ctyfips stfips covratehat
	cd "$final"
	append using predicted_bsvariation
	save predicted_bsvariation, replace
	
	*Attach predicted coverage to individual level data for estimation 
	cd "$final"
	use hsbdata_all, clear
	foreach outcome in $outcomes {
		*****For the Base Setting
		preserve
		*Get sample of observations where outcomes and covariates are not missing (will vary by outcome)
		areg `outcome' covratehatsr82 sr82 covratehat $controls i.statecohort if $srsample, absorb(schoolid) vce(cluster schoolid)
		keep if e(sample)
		*Now we need to drop our coverage variables
		drop covratehat* hsbtocov
		*From this sample, we will draw a random sample with replacement
		bsample , cluster(schoolid)
	
		*Now we need to merge on the coverage data:
		cd "$final"
		merge m:1 stfips ctyfips using predicted_covhsb, gen(hsbtocov)
		keep if hsbtocov==3
		gen covratehatsr82 = covratehat*sr82
		*Base Estimate:
		areg `outcome' covratehatsr82 sr82 covratehat $controls i.statecohort if $srsample, absorb(schoolid) vce(cluster schoolid)
		return scalar b_`outcome'2 = _b[covratehatsr82]
		return scalar b_`outcome'4 = _b[sr82]
		restore
		
		*****For State Law Cohort Definition
		preserve
		areg `outcome' covratehatbylaw1970 bylawstart1970 covratehat $controls i.statecohort2 if $srsample & (senior==1 | sophomore==1 & bylawstart1970==1), absorb(schoolid) vce(cluster schoolid)
		keep if e(sample)
		*Now we need to drop our coverage variables
		drop covratehat* hsbtocov
		*From this sample, we will draw a random sample of clusters with replacement 
		bsample , cluster(schoolid)
		
		*Now we need to merge on the coverage data:
		cd "$final"
		merge m:1 stfips ctyfips using predicted_covhsb, gen(hsbtocov)
		keep if hsbtocov==3
		gen covratehatbylaw1970 = covratehat*bylawstart1970
		*State Law Cohort Definition
		areg `outcome' covratehatbylaw1970 bylawstart1970 covratehat $controls i.statecohort2 if $srsample & (senior==1 | sophomore==1 & bylawstart1970==1), absorb(schoolid) vce(cluster schoolid)
		return scalar bylaw_`outcome'2 = _b[covratehatbylaw1970]
		return scalar bylaw_`outcome'4 = _b[bylawstart1970]
		restore
		
		****For the Alternative Coverage Measures
		if inlist("`outcome'", "stdmath", "esteemindex", "like_workatschool_sryr") {
			*Alternative 1: VHF vs. UHF
			preserve
			areg `outcome' vhfbestsr82 sr82 vhfbest $controls i.statecohort if $srsample, absorb(schoolid) vce(cluster schoolid)
			keep if e(sample)
			drop vhfbest* hsbtocov
			bsample, cluster(schoolid)
			cd "$final"
			merge m:1 stfips ctyfips using predicted_covhsb, gen(hsbtocov)
			keep if hsbtocov==3
			gen vhfbestsr82 = vhfbest*sr82
			areg `outcome' vhfbestsr82 sr82 vhfbest $controls i.statecohort if $srsample, absorb(schoolid) vce(cluster schoolid)
			return scalar alt1_`outcome'2 = _b[vhfbestsr82]
			return scalar alt1_`outcome'4 = _b[sr82]
			restore
			
			*Alternative 2: VHF vs. UHF in 100 largest
			preserve
			areg `outcome' vhfbestsr82 sr82 vhfbest $controls i.statecohort if $srsample & large100cty==1, absorb(schoolid) vce(cluster schoolid)
			keep if e(sample)
			drop vhfbest* hsbtocov
			bsample, cluster(schoolid)
			cd "$final"
			merge m:1 stfips ctyfips using predicted_covhsb, gen(hsbtocov)
			keep if hsbtocov==3
			gen vhfbestsr82 = vhfbest*sr82
			areg `outcome' vhfbestsr82 sr82 vhfbest $controls i.statecohort if $srsample & large100cty==1, absorb(schoolid) vce(cluster schoolid)
			return scalar alt2_`outcome'2 = _b[vhfbestsr82]
			return scalar alt2_`outcome'4 = _b[sr82]
			restore
			
			*Alternative 3: Any VHF over 50 in 100 largest
			preserve
			areg `outcome' vhfover_50sr82 sr82 vhfover_50 $controls i.statecohort if $srsample & large100cty==1, absorb(schoolid) vce(cluster schoolid)
			keep if e(sample)
			drop vhfover_50* hsbtocov
			bsample, cluster(schoolid)
			cd "$final"
			merge m:1 stfips ctyfips using predicted_covhsb, gen(hsbtocov)
			keep if hsbtocov==3
			gen vhfover_50sr82 = vhfover_50*sr82
			areg `outcome' vhfover_50sr82 sr82 vhfover_50 $controls i.statecohort if $srsample & large100cty==1, absorb(schoolid) vce(cluster schoolid)
			return scalar alt3_`outcome'2 = _b[vhfover_50sr82]
			return scalar alt3_`outcome'4 = _b[sr82]
			restore
		}
	}
end

/*Now that we have a program that gets the bootstrap samples and estimates, we
will simulate to get our 100 bootstrap estimates to obtain bootstrapped 
standard errors */
cd "$final"
simulate  b_stdmath2 = r(b_stdmath2) b_stdmath4 = r(b_stdmath4) ///
		  b_stdvocab2 = r(b_stdvocab2) b_stdvocab4 = r(b_stdvocab4) ///
		  b_stdread2 = r(b_stdread2) b_stdread4 = r(b_stdread4) ///
		  b_ggrades_tosryr2 = r(b_ggrades_tosryr2) b_ggrades_tosryr4 = r(b_ggrades_tosryr4) ///
		  b_locusindex2 = r(b_locusindex2) b_locusindex4 = r(b_locusindex4) ///
		  b_esteemindex2 = r(b_esteemindex2) b_esteemindex4 = r(b_esteemindex4) ///
		  b_nodis_prob_sryr2 = r(b_nodis_prob_sryr2) b_nodis_prob_sryr4 = r(b_nodis_prob_sryr4) ///
		  b_dont_cutclass_sryr2 = r(b_dont_cutclass_sryr2) b_dont_cutclass_sryr4 = r(b_dont_cutclass_sryr4) ///
		  b_like_workatschool_sryr2 = r(b_like_workatschool_sryr2) b_like_workatschool_sryr4 = r(b_like_workatschool_sryr4) ///
		  ///
		  bylaw_stdmath2 = r(bylaw_stdmath2) bylaw_stdmath4 = r(bylaw_stdmath4) ///
		  bylaw_stdvocab2 = r(bylaw_stdvocab2) bylaw_stdvocab4 = r(bylaw_stdvocab4) ///
		  bylaw_stdread2 = r(bylaw_stdread2) bylaw_stdread4 = r(bylaw_stdread4) ///
		  bylaw_ggrades_tosryr2 = r(bylaw_ggrades_tosryr2) bylaw_ggrades_tosryr4 = r(bylaw_ggrades_tosryr4) ///
		  bylaw_locusindex2 = r(bylaw_locusindex2) bylaw_locusindex4 = r(bylaw_locusindex4) ///
		  bylaw_esteemindex2 = r(bylaw_esteemindex2) bylaw_esteemindex4 = r(bylaw_esteemindex4) ///
		  bylaw_nodis_prob_sryr2 = r(bylaw_nodis_prob_sryr2) bylaw_nodis_prob_sryr4 = r(bylaw_nodis_prob_sryr4) ///
		  bylaw_dont_cutclass_sryr2 = r(bylaw_dont_cutclass_sryr2) bylaw_dont_cutclass_sryr4 = r(bylaw_dont_cutclass_sryr4) ///
		  bylaw_like_workatschool_sryr2 = r(bylaw_like_workatschool_sryr2) bylaw_like_workatschool_sryr4 = r(bylaw_like_workatschool_sryr4) ///
		  ///
		  alt1_stdmath2 = r(alt1_stdmath2) alt1_stdmath4 = r(alt1_stdmath4) ///
		  alt1_esteemindex2 = r(alt1_esteemindex2) alt1_esteemindex4 = r(alt1_esteemindex4) ///
		  alt1_like_workatschool_sryr2 = r(alt1_like_workatschool_sryr2) alt1_like_workatschool_sryr4 = r(alt1_like_workatschool_sryr4) ///
		  ///
		  alt2_stdmath2 = r(alt2_stdmath2) alt2_stdmath4 = r(alt2_stdmath4) ///
		  alt2_esteemindex2 = r(alt2_esteemindex2) alt2_esteemindex4 = r(alt2_esteemindex4) ///
		  alt2_like_workatschool_sryr2 = r(alt2_like_workatschool_sryr2) alt2_like_workatschool_sryr4 = r(alt2_like_workatschool_sryr4) ///
		  ///
		  alt3_stdmath2 = r(alt3_stdmath2) alt3_stdmath4 = r(alt3_stdmath4) ///
		  alt3_esteemindex2 = r(alt3_esteemindex2) alt3_esteemindex4 = r(alt3_esteemindex4) ///
		  alt3_like_workatschool_sryr2 = r(alt3_like_workatschool_sryr2) alt3_like_workatschool_sryr4 = r(alt3_like_workatschool_sryr4) ///
		  ///
		  , reps(400) saving(hsb_bootstrap400, replace) seed(3865788): bootstrap2stage
	

*Now we must combine to get our tables
cd "$final"
use hsb_bootstrap400, clear
cd "$tables"
*Base Analysis Table
local num : word count $outcomes
forval i = 1/`num' {
	local outcome : word `i' of $outcomes
	foreach x in 2 4 {
		qui sum b_`outcome'`x'
		matrix define base_hsb[`x',`i'] = r(sd)
	}
}
cap file close hsb
file open hsb using hsb_bootstrap.txt, write replace
file write hsb _tab "Achievement Tests" _tab _tab _tab _tab "Non-Cognitive Outcomes" _n
file write hsb _tab "Math" _tab "Vocab" _tab "Reading" _tab "Mostly A's and B's" _tab "Locus of Control" _tab "Self Esteem" _tab "No Discipline Problems" _tab "Doesn't cut class" _tab "Likes Work at School" _n _n
file write hsb "Covratehat*Senior82"
local num : word count $outcomes 
forval i = 1/`num'	{
	file write hsb _tab %7.3f (base_hsb[1,`i'])
}
file write hsb _n 
forval i = 1/`num'	{
	file write hsb _tab "(" %5.3f (base_hsb[2,`i']) ")"
}
file write hsb _n "Senior82" 
forval i = 1/`num'	{
	file write hsb _tab %7.3f (base_hsb[3,`i'])
}
file write hsb _n 
forval i = 1/`num'	{
	file write hsb _tab "(" %5.3f (base_hsb[4,`i']) ")"
}
file write hsb _n _n
file write hsb "Observations" 
forval i = 1/`num'	{
	file write hsb _tab %9.0gc (base_hsb[5,`i'])
}
file close hsb

*State Law Age Cohort Table
local num : word count $outcomes
forval i = 1/`num' {
	local outcome : word `i' of $outcomes
	foreach x in 2 4 {
		qui sum bylaw_`outcome'`x'
		matrix define bylaw_hsb[`x',`i'] = r(sd)
	}
}
cap file close hsb
file open hsb using hsbbylaw_bootstrap.txt, write replace
file write hsb _tab "Achievement Tests" _tab _tab _tab _tab "Non-Cognitive Outcomes" _n
file write hsb _tab "Math" _tab "Vocab" _tab "Reading" _tab "Mostly A's and B's" _tab "Locus of Control" _tab "Self Esteem" _tab "No Discipline Problems" _tab "Doesn't cut class" _tab "Likes Work at School" _n _n
file write hsb "Covratehat*Bylaw1970"
local num : word count $outcomes 
forval i = 1/`num'	{
	file write hsb _tab %7.3f (bylaw_hsb[1,`i'])
}
file write hsb _n 
forval i = 1/`num'	{
	file write hsb _tab "(" %5.3f (bylaw_hsb[2,`i']) ")"
}
file write hsb _n "By Law Start 1970" 
forval i = 1/`num'	{
	file write hsb _tab %7.3f (bylaw_hsb[3,`i'])
}
file write hsb _n 
forval i = 1/`num'	{
	file write hsb _tab "(" %5.3f (bylaw_hsb[4,`i']) ")"
}
file write hsb _n _n
file write hsb "Observations" 
forval i = 1/`num'	{
	file write hsb _tab %9.0gc (bylaw_hsb[5,`i'])
}
file close hsb

*Alternative Coverage Specifications
local suboutcomes = "stdmath esteemindex like_workatschool_sryr"
local num : word count `suboutcomes'
forval i = 1/`num' {
	local outcome : word `i' of `suboutcomes'
	local j = 3*`i'-2
	local k = `j'+1
	local l = `k'+1
	foreach x in 2 4 {
		qui sum alt1_`outcome'`x'
		matrix define alt_hsb[`x',`j'] = r(sd)
		qui sum alt2_`outcome'`x'
		matrix define alt_hsb[`x',`k'] = r(sd)
		qui sum alt3_`outcome'`x'
		matrix define alt_hsb[`x',`l'] = r(sd)
	}
}
cap file close hsb
file open hsb using hsbalt_bootstrap.txt, write replace
file write hsb _tab "Math" _tab _tab  _tab "Self Esteem" _tab _tab _tab "Likes Work at School" _n
file write hsb _tab "VHF/UHF" _tab "Urban VHF/UHF" _tab "Urban Any VHF" _tab "VHF/UHF" _tab "Urban VHF/UHF" _tab "Urban Any VHF" _tab "VHF/UHF" _tab "Urban VHF/UHF" _tab "Urban Any VHF" _n
file write hsb "High Cov.*Senior82"
local suboutcomes = "stdmath esteemindex like_workatschool_sryr"
local num : word count `suboutcomes'
forval i = 1/`num'	{
	local j = 3*`i'-2
	local k = `j'+1
	local l = `k'+1
	file write hsb _tab %7.3f (alt_hsb[1,`j']) _tab %7.3f (alt_hsb[1,`k']) _tab  %7.3f (alt_hsb[1,`l'])
}
file write hsb _n 
forval i = 1/`num'	{
	local j = 3*`i'-2
	local k = `j'+1
	local l = `k'+1
	file write hsb _tab "(" %5.3f (alt_hsb[2,`j']) ")" _tab "(" %5.3f (alt_hsb[2,`k']) ")" _tab "(" %5.3f (alt_hsb[2,`l']) ")"
}
file write hsb _n "Senior82" 
forval i = 1/`num'	{
	local j = 3*`i'-2
	local k = `j'+1
	local l = `k'+1
	file write hsb _tab %7.3f (alt_hsb[3,`j']) _tab %7.3f (alt_hsb[3,`k']) _tab %7.3f (alt_hsb[3,`l'])
}
file write hsb _n 
forval i = 1/`num'	{
	local j = 3*`i'-2
	local k = `j'+1
	local l = `k'+1
	file write hsb _tab "(" %5.3f (alt_hsb[4,`j']) ")" _tab "(" %5.3f (alt_hsb[4,`k']) ")" _tab "(" %5.3f (alt_hsb[4,`l']) ")"
}
file write hsb _n _n
file write hsb "Observations" 
forval i = 1/`num'	{
	local j = 3*`i'-2
	local k = `j'+1
	local l = `k'+1
	file write hsb _tab %9.0gc (alt_hsb[5,`j']) _tab %9.0gc (alt_hsb[5,`k']) _tab %9.0gc (alt_hsb[5,`l'])
}
file close hsb


******************
/*We now need to combine the original coverage rates with the BS coverage rates
to understand how much variation we are experiencing. */
use predicted_covhsb, clear
keep stfips ctyfips stname ctyname covratehat pop70 ctypoprank large100cty large200cty
rename covratehat orig_covratehat
save orig_prediction, replace
use predicted_bsvariation, clear
bys stfips ctyfips: gen rep = _n
reshape wide covratehat, i(stfips ctyfips) j(rep)
merge 1:1 stfips ctyfips using orig_prediction, gen(mergeorig_bs)
keep if mergeorig_bs==3 //only the initial blank observation is dropped
forval i = 1/100 {
	gen diff`i' = covratehat`i' - orig_covratehat
}
reshape long covratehat diff, i(stfips ctyfips) j(rep)
save bs_variation, replace
cd "$tables"
gen diff2 = diff*100
hist diff2 ,bin(50) xtitle("Bootstrapped Predicted Coverage - Original Predicted Coverage") ///
lcolor(grey*.6) fcolor(grey*.4)  graphregion(color(white)) saving(stage1_variation400, replace)
*graph export stage1_variation.png, replace

cd "$tables"
cap file close variation
file open variation using variation400.txt, write replace
file write variation "Bootstrapped Predicted Coverage - Original Predicted Coverage" _n
file write variation "Percentage Point Differences at Points in the Distribution" _n
file write variation _tab "Mean" _tab "10th" _tab "25th" _tab "50th" _tab "75th" _tab "90th" _n
qui sum diff2, detail
file write variation "Full Sample" _tab %7.3f (r(mean)) _tab %7.3f (r(p10)) _tab %7.3f (r(p25)) _tab %7.3f (r(p50)) _tab %7.3f (r(p75)) _tab %7.3f (r(p90)) _n
qui sum diff2 if large100cty == 1, de
file write variation "Largest 100 Counties" _tab %7.3f (r(mean)) _tab %7.3f (r(p10)) _tab %7.3f (r(p25)) _tab %7.3f (r(p50)) _tab %7.3f (r(p75)) _tab %7.3f (r(p90)) _n
file close variation


		  
		  
		  
		  
