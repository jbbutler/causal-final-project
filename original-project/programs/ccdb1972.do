# delimit ;
capture log close;
log using "$logs/ccdb1972.log", replace;

**********************

CCDB1972

**********************

This program inputs county level data mostly from the 1970 Census to help
distinguish between counties more and less likely to have larger impacts
associated with Sesame Street. These include things like poverty rates,
educational spending, population density, etc.;

set more 1;
clear;
infix 
	 deck 1-2
     tablenum 3
	 stfips 4-5 
	 ctyfips 6-8
	 totpop 46-54
	 popmile 55-63
	 if deck == 2	 
using "$raw/ccdb1972/data.txt";
sort stfips ctyfips;
save "$temp/temp1.dta", replace;

clear;
infix 
	 deck 1-2
     tablenum 3
	 stfips 4-5 
	 ctyfips 6-8
	 totblack 64-72
	 if deck == 3	 
using "$raw/ccdb1972/data.txt";

sort stfips ctyfips;
merge stfips ctyfips using "$temp/temp1.dta";
tab _merge;
drop _merge;

replace totblack = 0 if totblack < 0;
gen pctblack = 100*totblack/totpop;

sort stfips ctyfips;
save "$temp/temp1.dta", replace;

clear;
infix 
	 deck 1-2
     tablenum 3
	 stfips 4-5 
	 ctyfips 6-8
	 pcthisp 28-36
	 if deck == 6	 
using "$raw/ccdb1972/data.txt";

replace pcthisp = 0 if pcthisp < 0;
replace pcthisp = pcthisp/10;

sort stfips ctyfips;
merge stfips ctyfips using "$temp/temp1.dta";
tab _merge;
drop _merge;
sort stfips ctyfips;
save "$temp/temp1.dta", replace;

clear;
infix 
	 deck 1-2
     tablenum 3
	 stfips 4-5 
	 ctyfips 6-8
	 pcthsgrad 55-63
	 if deck == 7	 
using "$raw/ccdb1972/data.txt";

replace pcthsgrad = pcthsgrad/10;
gen pctlths = 100-pcthsgrad;

sort stfips ctyfips;
merge stfips ctyfips using "$temp/temp1.dta";
tab _merge;
drop _merge;
sort stfips ctyfips;
save "$temp/temp1.dta", replace;

clear;
infix 
	 deck 1-2
     tablenum 3
	 stfips 4-5 
	 ctyfips 6-8
	 unemrate 28-36
	 if deck == 10
using "$raw/ccdb1972/data.txt";

replace unemrate = unemrate/10;

sort stfips ctyfips;
merge stfips ctyfips using "$temp/temp1.dta";
tab _merge;
drop _merge;
sort stfips ctyfips;
save "$temp/temp1.dta", replace;

clear;
infix 
	 deck 1-2
     tablenum 3
	 stfips 4-5 
	 ctyfips 6-8
	 pctfemhd 64-72
	 if deck == 12
using "$raw/ccdb1972/data.txt";

replace pctfemhd = pctfemhd/10;

sort stfips ctyfips;
merge stfips ctyfips using "$temp/temp1.dta";
tab _merge;
drop _merge;
sort stfips ctyfips;
save "$temp/temp1.dta", replace;

clear;
infix 
	 deck 1-2
     tablenum 3
	 stfips 4-5 
	 ctyfips 6-8
	 pctinc1 46-54
	 pctinc2 55-63
	 pctinc3 64-72
	 if deck == 13
using "$raw/ccdb1972/data.txt";

replace pctinc1 = pctinc1/10;
replace pctinc2 = pctinc2/10;
replace pctinc3 = pctinc3/10;
gen pctlowinc = pctinc1 + pctinc2;

label var pctinc1 "pct income < $3,000";
label var pctinc2 "pct income b/w #3,000 and $5,000";
label var pctinc3 "pct income b/w $5,000 and $7,000";
label var pctlowinc "family income under $5,000";

sort stfips ctyfips;
merge stfips ctyfips using "$temp/temp1.dta";
tab _merge;
drop _merge;
sort stfips ctyfips;
save "$temp/temp1.dta", replace;

clear;
infix 
	 deck 1-2
     tablenum 3
	 stfips 4-5 
	 ctyfips 6-8
	 medfaminc 64-72
	 if deck == 14
using "$raw/ccdb1972/data.txt";

sort stfips ctyfips;
merge stfips ctyfips using "$temp/temp1.dta";
tab _merge;
drop _merge;
sort stfips ctyfips;
save "$temp/temp1.dta", replace;

clear;
infix 
	 deck 1-2
     tablenum 3
	 stfips 4-5 
	 ctyfips 6-8
	 povrate 46-54
	 if deck == 16
using "$raw/ccdb1972/data.txt";

replace povrate = povrate/10;

sort stfips ctyfips;
merge stfips ctyfips using "$temp/temp1.dta";
tab _merge;
drop _merge;
sort stfips ctyfips;
save "$temp/temp1.dta", replace;

clear;
infix 
	 deck 1-2
     tablenum 3
	 stfips 4-5 
	 ctyfips 6-8
	 pctexpeduc 55-63
	 if deck == 29
using "$raw/ccdb1972/data.txt";

replace pctexpeduc = pctexpeduc/10;
replace pctexpeduc = . if pctexpeduc < 0;

sort stfips ctyfips;
merge stfips ctyfips using "$temp/temp1.dta";
tab _merge;
drop _merge;

sum;

sort stfips ctyfips;
save "$temp/ccdb1972ext.dta", replace;


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
by category: sum totpop pctfemhd pctlowinc pctlths pctblack medfaminc 
                 unemrate;
by category: sum pctfemhd pctlowinc pctlths pctblack medfaminc 
                 unemrate [weight=totpop];

preserve;
drop if category == 1;
regress totpop goodrec, robust;
regress pctfemhd goodrec [weight=totpop], robust;
regress pctlowinc goodrec  [weight=totpop], robust;
regress pctlths goodrec [weight=totpop], robust;
regress pctblack goodrec [weight=totpop], robust;
regress medfaminc goodrec [weight=totpop], robust;
regress unemrate goodrec [weight=totpop], robust;
restore;

drop _merge;
keep stfips ctyfips totpop pctfemhd pctlowinc pctlths pctblack medfaminc 
     unemrate mindist uhfclosest far category;
gen year = 1970;
sort stfips ctyfips;
save "$raw/ccdb1972/final.dta", replace;				 
log close;

