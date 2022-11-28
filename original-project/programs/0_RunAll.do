
/*******************************************************************************
0. Sesame Street - Run All.do

Runs all programs to produce Tables 1 through 7. Programs can be run altogether 
or piecewise as desired. 

Edited by: George Zuo
Last Edited: June 20, 2018
*******************************************************************************/

clear all
set more off

/* Set the below directory to wherever the folder structure is located. This should
be the only step that the user is required to change, provided that the original
folder structure is preserved*/

	global main "C:\Users\georg\Dropbox\Economics\RA Tasks\Sesame Street\all files"

/*The following global macros should populate as long as the original folder 
structure is maintained.*/

	global raw "$main/data/raw"
	global temp "$main/data/temp"
	global prog "$main/programs"
	global logs "$main/logs"
	global bs_dofiles "$prog/bs_dofiles"
	global output "$main/data/output"

/*Two ssc commands that are needed*/

	ssc install geodist
	ssc install reghdfe

/*******************************************************************************
Data Prep: See "Programs and Data Files.xlsx" for details
*******************************************************************************/

*Needed for Tables 2, 4, 5, 6

	do "$prog/inpcensus70_cty.do"
	do "$prog/inpcensus80_cty.do"
	do "$prog/inpcensus90_cty.do"
	do "$prog/inpcensus2000_cty.do"
	
*Needed for Tables 4, 5, 6

	do "$bs_dofiles/stage1_sample.do"
	do "$bs_dofiles/stage2_sample.do"
	
/*******************************************************************************
Table 2: Inter- and Intra-State Mobility Patterns since Birth 
*******************************************************************************/

*Panel 1: Descriptive migration statistics from '80, '90, '00 Census data

	disp $stay1980_wt // Generated in "inpcensus80_cty.do" above
	disp $stay1990_wt // Generated in "inpcensus90_cty.do" above
	disp $stay2000_wt // Generated in "inpcensus2000_cty.do" above

*Panel 2: Similar statistics from the NLSY

	do "$prog/nlsymobility.do"
	
	disp $staystate80_wt
	disp $staystate90_wt
	disp $staystate2000_wt

	disp $dist80lt60_wt
	disp $dist90lt60_wt
	disp $dist2000lt60_wt

*Panel 3/4: See regression outputs at the end of nlsymobility.do

/*******************************************************************************
Table 3: Average Characteristics of Counties, by Availability of Census Data and  
Estimated Strength of Signal Reception 
*******************************************************************************/

*Some data prep

	do "$prog/ccdb1962.do"
	do "$prog/ccdb1972.do"

*Create four sub-tables underlying Table 3: 2 tables showing means, and 2 showing p-values
	
	do "$prog/ccdbcompare.do"

/*******************************************************************************
Table 4: Impact of Sesame Street on Grade-for-age Status in the 1980 Census, by 
Demographic Group 
*******************************************************************************/

*Runs bootstrapped estimates for Table 4. Run time: >24 hrs
	
	do "$prog/table4_est.do"

/*******************************************************************************
Table 5: Differential Impact of Sesame Street on Grade-for-age, by County 
Characteristic 
*******************************************************************************/

*Runs bootstrapped estimates for Table 5. Run time: >24 hrs
	
	do "$prog/table5_est.do"

/*******************************************************************************
Table 6: Aggregate Impact of Sesame Street on Educational Attainment and  
Labor Market Outcomes in the 1990 and 2000 Census 
*******************************************************************************/

*Runs bootstrapped estimates for Table 6. Run time: >30 hrs
	
	do "$prog/table6_est.do"

/*******************************************************************************
Table 7. Impact of Sesame Street on Cognitive and Non-cognitive Outcomes: 
High School and Beyond Data  
*******************************************************************************/

*Runs bootstrapped estimates for Table 7. Run time: >30 hrs
	
	do "$prog/table7_est_hsb.do"
	
/*******************************************************************************
Analysis of grade-for-age status on future wages (pg. 23)
*******************************************************************************/

	do "$prog/inpnlsyGFA.do"

