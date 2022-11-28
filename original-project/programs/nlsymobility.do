# delimit ;
capture log close;
log using "$logs/nlsymobility.log", replace;

**********************

NLSYMOBILITY

**********************

This program reads in NLSY79 data on location of residence at birth and then in
1980/1990/2000 to examine mobility rates over time. I also merge on Sesame
Street coverage data to see whether mobility over time is at all linked to
Sesame Street coverage rates;

set matsize 4000;
set more 1;
clear;

infile using "$raw/survey_and_created_variables_032212.dct";
keep R0000100 R0000900 R0001000;

rename R0000100 studentid;
rename R0000900 ctyfipsbth;
rename R0001000 stfipsbth;

replace studentid = . if studentid < 0;
replace ctyfipsbth = . if ctyfipsbth < 0;
replace stfipsbth = . if stfipsbth < 0;

sort studentid;
save "$temp/temp1.dta", replace;

clear;
infile using "$raw/location_032212.dct";
keep R0000100 R0219001 R0219002 R3076900 R3077000 R3076900 R3077000 
     R7017300 R7017400 R0408001 R0408002 R3411300 R3411400;
rename R0000100 studentid; 
rename R0219001 ctyfips79;
rename R0219002 stfips79;
rename R0408001 ctyfips80;
rename R0408002 stfips80;
rename R3076900 ctyfips89; 
rename R3077000 stfips89;
rename R3411300 ctyfips90;
rename R3411400 stfips90;
rename R7017300 ctyfips2000;
rename R7017400 stfips2000;

replace stfips79 = . if stfips79 < 0;
replace ctyfips79 = . if ctyfips79 < 0;
replace stfips89 = . if stfips89 < 0;
replace ctyfips89 = . if ctyfips89 < 0;
replace stfips80 = . if stfips80 < 0;
replace ctyfips80 = . if ctyfips80 < 0;
replace stfips90 = . if stfips90 < 0;
replace ctyfips90 = . if ctyfips90 < 0;
replace stfips2000 = . if stfips2000 < 0;
replace ctyfips2000 = . if ctyfips2000 < 0;

sort studentid;
merge studentid using "$temp/temp1.dta";
tab _merge;
keep if _merge == 3;
drop _merge;

sort studentid;
save "$temp/temp1.dta", replace;

clear;
infile using "$raw/nlsy79-hsdrop.dct";

keep R0000100 R0000600 R0172700 R0216100 R0214700 R0214800 R1890901;

rename	R0000100	studentid;
rename	R0000600	age79;
rename	R0172700	race;
rename	R0216100	weight79;
rename	R0214800	sex;
rename	R0214700	raceeth;
rename  R1890901    hgc85;

gen hispanic = raceeth == 1;
gen blacknh = hispanic == 0 & race == 2;
gen othernh = hispanic == 0 & race == 3;
gen whitenh = raceeth == 3;
gen female = sex == 2;

gen hsgrad = hgc85 >= 12;
replace hsgrad = . if hgc85 < 0;

sort studentid;
merge studentid using "$temp/temp1.dta";
tab _merge;
keep if _merge == 3;
drop _merge;

sort stfipsbth ctyfipsbth;
save "$temp/temp1.dta", replace;
clear;

* Merge in Sesame Street coverage data at the county level with county of
birth from the NLSY data;

clear;
use "$raw/SScovcty_final.dta";

sum covratehat [weight=pop70];

keep ctyfips stfips covratehat;
rename stfips stfipsbth;
rename ctyfips ctyfipsbth;

sort stfipsbth ctyfipsbth;
merge stfipsbth ctyfipsbth using "$temp/temp1.dta";
tab _merge;
keep if _merge == 3;
drop _merge;

sort stfipsbth ctyfipsbth;
save "$temp/temp1.dta", replace;

clear;
use "$raw/SScov-instruments.dta";

rename stfips stfipsbth;
rename ctyfips ctyfipsbth;

sort stfipsbth ctyfipsbth;
merge stfips ctyfips using "$temp/temp1.dta";
tab _merge;
drop if _merge ~= 3;
drop _merge;

*Create distance measures;

sort stfips80 ctyfips80;
save "$temp/temp1.dta", replace;

use "$raw/counties.dta";
keep stfips ctyfips lathh longhh;
rename stfips stfips80;
rename ctyfips ctyfips80;
sort stfips80 ctyfips80;

merge stfips80 ctyfips80 using "$temp/temp1.dta";
tab _merge;
keep if _merge == 3;
drop _merge;
rename lathh lat80;
rename longhh long80;

sort stfipsbth ctyfipsbth;
save "$temp/temp1.dta", replace;

use "$raw/counties.dta";
keep stfips ctyfips lathh longhh;
rename stfips stfipsbth;
rename ctyfips ctyfipsbth;
sort stfipsbth ctyfipsbth;

merge stfipsbth ctyfipsbth using "$temp/temp1.dta";
tab _merge;

keep if _merge == 3;
drop _merge;
rename lathh latbth;
rename longhh longbth;
geodist lat80 long80 latbth longbth, gen(distance80) miles;

sort stfips90 ctyfips90;
save "$temp/temp1.dta", replace;

use "$raw/counties.dta";
keep stfips ctyfips lathh longhh;
rename stfips stfips90;
rename ctyfips ctyfips90;
sort stfips90 ctyfips90;

merge stfips90 ctyfips90 using "$temp/temp1.dta";
tab _merge;
drop if _merge == 1; 
drop _merge;
rename lathh lat90;
rename longhh long90;
geodist lat90 long90 latbth longbth, gen(distance90) miles;

sort stfips2000 ctyfips2000;
save "$temp/temp1.dta", replace;

use "$raw/counties.dta";
keep stfips ctyfips lathh longhh;
rename stfips stfips2000;
rename ctyfips ctyfips2000;
sort stfips2000 ctyfips2000;

merge stfips2000 ctyfips2000 using "$temp/temp1.dta";
tab _merge;
drop if _merge == 1;
drop _merge;
rename lathh lat2000;
rename longhh long2000;
geodist lat2000 long2000 latbth longbth, gen(distance2000) miles;

gen movestate80 = stfips80 ~= stfipsbth;
     replace movestate80 = . if stfips80 == . | stfipsbth == .;
tab movestate80;
tab movestate80 [weight=weight79];
gen movecty80 = ctyfips80 ~= ctyfipsbth;
     replace movecty80 = . if ctyfips80 == . | ctyfipsbth == .;
tab movecty80 if movestate80 == 0;
tab movecty80 if movestate80 == 0 [weight=weight79];

sum distance80 if movecty80 == 1 & movestate80 == 0, detail;
sum distance80 if movecty80 == 1 & movestate80 == 0 [weight=weight79], detail;

gen movestate90 = stfips90 ~= stfipsbth;
     replace movestate90 = . if stfips90 == . | stfipsbth == .;
tab movestate90;
tab movestate90 [weight=weight79];
gen movecty90 = ctyfips90 ~= ctyfipsbth;
     replace movecty90 = . if ctyfips90 == . | ctyfipsbth == .;
tab movecty90 if movestate90 == 0;
tab movecty90 if movestate90 == 0 [weight=weight79];

gen movestate2000 = stfips2000 ~= stfipsbth;
     replace movestate2000 = . if stfips2000 == . | stfipsbth == .;
tab movestate2000;
tab movestate2000 [weight=weight79];
gen movecty2000 = ctyfips2000 ~= ctyfipsbth;
     replace movecty2000 = . if ctyfips2000 == . | ctyfipsbth == .;
tab movecty2000 if movestate2000 == 0;
tab movecty2000 if movestate2000 == 0 [weight=weight79];

sum distance90 if movecty90 == 1 & movestate90 == 0, detail;
sum distance90 if movecty90 == 1 & movestate90 == 0 [weight=weight79], detail;

gen dist2000lt60 = distance2000 < 60;
     replace dist2000lt60 = . if movestate2000 == 1;
gen dist90lt60 = distance90 < 60;
     replace dist90lt60 = . if movestate90 == 1;
gen dist80lt60 = distance80 < 60;
     replace dist80lt60 = . if movestate80 == 1;

*Generate second panel in Table 2; 
sum movestate80 [weight=weight79];
global staystate80_wt = 1-r(mean);
sum movestate90 [weight=weight79];
global staystate90_wt = 1-r(mean);
sum movestate2000 [weight=weight79];
global staystate2000_wt = 1-r(mean);

sum dist80lt60 if movestate80 == 0 [weight=weight79];
global dist80lt60_wt = r(mean);
sum dist90lt60 if movestate90 == 0 [weight=weight79];
global dist90lt60_wt = r(mean);
sum dist2000lt60 if movestate2000 == 0 [weight=weight79];
global dist2000lt60_wt = r(mean);

tab age79, gen(agedv);

gen yearage6 = 1979 - age79 + 6;
gen preschl69 = yearage6 > 1969;
gen preschlcov = preschl69*covratehat;
gen preschldist = preschl69*mindist;
gen preschluhf = preschl69*uhfclosest;

gen statecty = stfipsbth*1000+ctyfipsbth;
tab statecty, gen(stctydv);

*OLS;
	 
areg movestate80 preschlcov female blacknh hispanic agedv2-agedv9 [weight=weight79], 
     absorb(statecty) robust cluster(statecty);
areg movestate90 preschlcov female blacknh hispanic agedv2-agedv9 [weight=weight79], 
     absorb(statecty) robust cluster(statecty);
areg movestate2000 preschlcov female blacknh hispanic agedv2-agedv9 [weight=weight79], 
     absorb(statecty) robust cluster(statecty);
	 
areg dist80lt60 preschlcov female blacknh hispanic agedv2-agedv9 [weight=weight79]
     if movestate80 == 0, absorb(statecty) robust cluster(statecty);
areg dist90lt60 preschlcov female blacknh hispanic agedv2-agedv9 [weight=weight79]
     if movestate90 == 0, absorb(statecty) robust cluster(statecty);
areg dist2000lt60 preschlcov female blacknh hispanic agedv2-agedv9 [weight=weight79]
     if movestate2000 == 0, absorb(statecty) robust cluster(statecty);


erase "$temp/temp1.dta";
log close;


