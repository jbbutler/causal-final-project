# delimit ;
capture log close;
log using "$logs/ccdb1962.log", replace;

**********************

CCDB1962

**********************

This program inputs county level data mostly from the 1960 Census to help
distinguish between counties more and less likely to have larger impacts
associated with Sesame Street. These include things like poverty rates,
educational spending, population density, etc.;

set more 1;
clear;
infix 
	 state1960 15-16
	 cty1960 19-21
	 totpop 49-56
	 popmile 57-61
 	 pctblack 81-84
	 pcthsgrad 179-183
 	 unemrate 226-230
	 medfaminc 147-151

using "$raw/ccdb1962/data.txt";

drop if state1960 < 0 | cty1960 < 0;
replace popmile = . if popmile < 0;
replace pctblack = . if pctblack < 0;
replace pcthsgrad = . if pcthsgrad < 0;
replace unemrate = . if unemrate < 0;
replace medfaminc = . if medfaminc < 0;

replace pctblack = pctblack/10;
replace pcthsgrad = pcthsgrad/10;
replace unemrate = unemrate/10;
gen pctlths = 100-pcthsgrad;

sum;
sort state1960 cty1960;
save "$temp/ccdb1962ext.dta", replace;

merge state1960 cty1960 using 
     "$raw/ccdb1962/convcodes60.dta";
	 
tab _merge;
keep if _merge == 3;
drop _merge;
	 
sort stfips ctyfips;
save "$temp/ccdb1962ext.dta", replace;


* Now create summary statistics of county characteristics as a function of 
Sesame Street coverage;

merge stfips ctyfips using "$raw/SScov-instruments.dta";
tab _merge;
drop if _merge ~= 3;
drop _merge;
sort stfips ctyfips;
save "$temp/temp1.dta", replace;

use "$raw/SScovcty_final.dta";

keep stfips ctyfips covratehat vhfbest whenshow;
sort stfips ctyfips;
merge stfips ctyfips using "$temp/temp1.dta";
tab _merge;
drop if _merge ~= 3;
drop _merge;

sort stfips ctyfips;
save "$temp/temp1.dta", replace;

use "$temp/gradeforage_cty.dta";
sort stfips ctyfips;
drop if stfips == stfips[_n-1] & ctyfips == ctyfips[_n-1];

sort stfips ctyfips;
merge stfips ctyfips using "$temp/temp1.dta";

gen far = mindist > 6;
gen goodrec = 1 if uhfclosest == 0 & far == 0;
replace goodrec = 0 if uhfclosest == 1 | far == 1;

gen category = 1 if _merge ~= 3;
replace category = 2 if _merge == 3 & goodrec == 0;
replace category = 3 if _merge == 3 & goodrec == 1;

label define catlbl 1 "not in Census" 2 "low coverage" 3 "high coverage";
label values category catlbl;

sort category;
by category: sum totpop pctlths pctblack medfaminc unemrate;
by category: sum totpop pctlths pctblack medfaminc unemrate [weight=totpop];

preserve;
drop if category == 1;
regress totpop goodrec, robust;
regress pctlths goodrec [weight=totpop], robust;
regress pctblack goodrec [weight=totpop], robust;
regress medfaminc goodrec [weight=totpop], robust;
regress unemrate goodrec [weight=totpop], robust;
restore;

drop _merge;
keep stfips ctyfips totpop pctlths pctblack medfaminc 
     unemrate mindist uhfclosest far category;
gen year = 1960;
sort stfips ctyfips;
save "$raw/ccdb1962/final.dta", replace;				 
log close;

