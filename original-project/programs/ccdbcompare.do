
*Author: Phillip Levine
*Compiled by George Zuo for use in "0_RunAll.do"
*Compilation Date: June 20, 2018

# delimit ;
capture log close;
log using "$logs/ccdbcompare.log", replace;

clear;

/*******************************************************************************
*Create LHS panel of Table 3;
*******************************************************************************/

*Get means;
use "$raw/ccdb1972/final.dta";

global vars "pctfemhd pctlowinc pctlths pctblack medfaminc unemrate";
eststo clear;
bysort category: eststo: quietly estpost summarize totpop, listwise;
bysort category: eststo: quietly estpost summarize $vars [weight=totpop], listwise;
esttab, cells("mean(fmt(1))") title(Summary Statistics) mtitle("NIS" "Weak" "Strong" "NIS" "Weak" "Strong");

*Get p-values in column 3;
gen weakrec = uhfclosest == 1 | far == 1;
drop if category == 1;

matrix p = J(7,1,.);
local i = 1;
qui regress totpop weakrec, robust;
	mat table = r(table);
	matrix p[`i++',1] = table[4,1];
foreach var in $vars {;
	qui regress `var' weakrec [weight=totpop], robust;
	mat table = r(table);
	matrix p[`i++',1] = table[4,1];
};
mat list p;

/*******************************************************************************
Create RHS panel of Table 3
*******************************************************************************/

*Clean data, create vars;
use "$raw/ccdb1972/final.dta", clear;
append using "$raw/ccdb1962/final.dta";
gen weakrec = uhfclosest == 1 | far == 1;

drop if ctyfips == 510 | ctyfips == 550 | ctyfips == 810;

drop if category == 1;
gen stcty = 1000*stfips + ctyfips;
replace year = year - 1900;

reshape wide totpop medfaminc pctlowinc pctfemhd pctlths pctblack unemrate,
   i(stcty) j(year); 

gen chgpctlths = (pctlths70 - pctlths60)/pctlths60;
gen chgblack = (pctblack70 - pctblack60)/pctblack60;
gen chgunem = unemrate70 - unemrate60;
gen chgmedinc = (medfaminc70 - medfaminc60)/medfaminc60;
gen chgpop = (totpop70 - totpop60)/totpop60;

egen avepop = rmean(totpop60 totpop70);

*Get means;
global vars "chgpctlths chgblack chgmedinc chgunem";
eststo clear;
bysort category: eststo: quietly estpost summarize chgpop [weight=totpop60], listwise;
bysort category: eststo: quietly estpost summarize $vars [aweight=avepop], listwise;
esttab, cells("mean(fmt(3))") title(Summary Statistics) mtitle("Weak" "Strong" "Weak" "Strong");

*Get p-values;
matrix p = J(5,1,.);
local i = 1;
qui regress chgpop weakrec [weight=totpop60], robust;
	mat table = r(table);
	matrix p[`i++',1] = table[4,1];
foreach var in $vars {;
	qui regress `var' weakrec [weight=avepop], robust;
	mat table = r(table);
	matrix p[`i++',1] = table[4,1];
};
mat list p;

log close;
