# delimit ;
capture log close;
log using "$logs/inpcensus80_cty.log", replace;

**********************

INPCENSUS80_CTY

**********************

This program inputs data from the 1980 Census to be used to examine whether
the introduction of Sesame Street had an impact on school enrollment. This
version is based on county level data. Since county of birth is not identified,
the sample is restricted to those who live in the same state as they were born
in. Using county identifiers also means losing about half of the observations
because they have missing county identifiers;

set more 1;
clear;
infix 
  int     year       1-4     
  byte    datanum    5-6     
  double  serial     7-14    
  float   hhwt       15-24   
  byte    statefip   25-26   
  int     county     27-30   
  byte    gq         31-31   
  int     pernum     32-35   
  float   perwt      36-45   
  byte    momloc     46-47   
  byte    sex        48-48   
  int     age        49-51   
  byte    birthqtr   52-52   
  int     birthyr    53-56   
  byte    race       57-57   
  int     raced      58-60   
  byte    hispan     61-61   
  int     hispand    62-64   
  int     bpl        65-67   
  long    bpld       68-72   
  int     yrimmig    73-76   
  byte    language   77-78   
  int     languaged  79-82   
  byte    speakeng   83-83   
  byte    school     84-84   
  byte    higrade    85-86   
  int     higraded   87-89   
  byte    educ       90-91   
  int     educd      92-94   
  byte    gradeatt   95-95   
  byte    gradeattd  96-97   
  int     migplac5   98-100  
  int     migcogrp   101-103 
  byte    samemet5   104-104 
  byte    migsamp    105-105 
  using "$raw/census1980.dat";

save "$temp/temp1.dta", replace;

gen momid = pernum;
sort year datanum serial pernum;

rename age momage;
rename bpl mombpl;
rename higrade momhigrad;
rename educd momeduc;
rename speakeng momspeakeng;

keep year datanum serial pernum momage mombpl momhigrad momeduc momspeakeng
     momid;
sort year datanum serial momid;

save "$temp/tempmom.dta", replace;

clear;
use "$temp/temp1.dta";
  
keep if birthyr >= 1959 & birthyr <= 1975;
gen nomom = momloc == 0;
tab birthyr nomom;

rename momloc momid;

replace momid = . if momid == 0;

sort year datanum serial momid;

merge year datanum serial momid 
     using "$temp/tempmom.dta";
tab _merge;
drop if _merge == 2;
gen livwmom = _merge == 3;
drop _merge;

gen momhsdrop = momeduc < 60;
     replace momhsdrop = . if nomom == 1;
gen momhsgrad = momeduc == 60;
     replace momhsgrad = . if nomom == 1;
gen momanycol = momeduc > 60;
     replace momanycol = . if nomom == 1;
	 
gen momhsdrop2 = momhsdrop;
     replace momhsdrop2 = 0 if livwmom == 0;
gen momhsgrad2 = momhsgrad;
     replace momhsgrad2 = 0 if livwmom == 0;
gen momanycol2 = momanycol;
     replace momanycol2 = 0 if livwmom == 0;
	 
gen mtreduc = 1 if momhsdrop == 1;
     replace mtreduc = 2 if momhsgrad == 1;
	 replace mtreduc = 3 if momanycol == 1;

gen momnative = mombpl <= 56;
gen momweakeng = momspeakeng == 6;

rename statefip stfips;
gen stbirth = bpl;
drop if stbirth > 56;
sort stbirth;
save "$temp/temp1.dta", replace;

* Use data from Cascio and Lewis (2006) on school entry age laws to determine
when students started school and what grade they should be in at the time of
the 1980 Census;

clear;
use "$raw/convstate.dta";
rename stfips stbirth;
sort stbirth;
merge 1:m stbirth using "$temp/temp1.dta";
tab _merge;
drop _merge;

gen qtrcut = 1 if stname == "AZ" | stname == "CT" | stname == "DE" |
     stname == "FL" | stname == "MS" | stname == "NM" | stname == "VT" |
	 stname == "PA" | stname == "PA";
replace qtrcut = 3 if stname == "CO" | stname == "DE" | stname == "KS" |
     stname == "MD" | stname == "MN" | stname == "MT" | stname == "TX" |
	 stname == "UT" | stname == "NH" | stname == "IA" | stname == "WY" |
	 stname == "MO" | stname == "TN" | stname == "VA" | stname == "GA" |
	 stname == "IN" | stname == "MA" | stname == "WA";
replace qtrcut = 4 if qtrcut == .;
	 
gen female = sex == 2;
gen hispanic = hispan ~= 0;
gen white = race == 1;
gen black = race == 2;
gen whitenh = white == 1 & hispanic == 0;
gen blacknh = black == 1 & hispanic == 0;
gen othernh = white == 0 & black == 0 & hispanic == 0;
gen native = bpl <= 56;
gen immigbef69 = yrimmig > 0 & yrimmig < 1970;
gen firstgen = native == 0;
gen secondgen = native == 1 & momnative == 0;
gen spanishhome = language == 12;
gen othlanghome = language > 1;
gen weakenglish = speakeng == 6;
gen yearage6 = birthyr + 6;

gen schlstartyr = birthyr + 6;
     replace schlstartyr = birthyr + 7 if birthqtr == 3 & qtrcut == 3;
	 replace schlstartyr = birthyr + 7 if birthqtr == 4 & qtrcut >= 3;
* note Census is conducted in the spring of 1980;
gen hsclass = schlstartyr + 12;
gen predgrade80 = 12 - (hsclass - 1980);  
replace predgrade80 = 13 if predgrade80 >= 13;

gen grade80 = 0 if higraded <= 30;
	 replace grade80 = 1 if higraded >= 31 & higraded <= 40;
	 replace grade80 = 2 if higraded >= 41 & higraded <= 50;
	 replace grade80 = 3 if higraded >= 51 & higraded <= 60;
	 replace grade80 = 4 if higraded >= 61 & higraded <= 70;
	 replace grade80 = 5 if higraded >= 71 & higraded <= 80;
	 replace grade80 = 6 if higraded >= 81 & higraded <= 90;
     replace grade80 = 7 if higraded >= 091 & higraded <= 100;
     replace grade80 = 8 if higraded >= 101 & higraded <= 110;
     replace grade80 = 9 if higraded >= 111 & higraded <= 120;
     replace grade80 = 10 if higraded >= 121 & higraded <= 130;
	 replace grade80 = 11 if higraded >= 131 & higraded <= 140;
	 replace grade80 = 12 if higraded == 141 | higraded == 142;
	 replace grade80 = 13 if higraded >= 150;
gen gradeage = grade80 >= predgrade80;

tab predgrade80, sum(gradeage);
tab schlstartyr, sum(gradeage);

keep if birthyr <= 1971;

replace county = county/10;
replace county = . if county == 0;
rename county ctyfips;
sort year datanum serial pernum;
save "$temp/temp1.dta", replace;

/*Generate a variable indicating whether each individual in the Census
subsample has another person living in his/her household who was 0 to 4 years
younger than them who may have been watching Sesame Street even after the
individual started school*/

* create a dataset of the ages of the other people in the household;

forvalues num = 1/20{;
clear;
use "$temp/temp1.dta";
keep if pernum == `num';
keep year datanum serial pernum age;
rename age ageoth`num';
gen pernumoth = `num';
drop pernum;
sort year datanum serial;
save "$temp/tempsib`num'.dta", replace;
};

* merge these data back onto the main dataset to identify if those other people 
are within 4 years younger;

forvalues num = 1/20{;
clear;
use "$temp/temp1.dta";
sort year datanum serial;
merge year datanum serial using "$temp/tempsib`num'";
drop _merge;
gen agediff`num' = age - ageoth`num';
replace agediff`num' = . if pernum == pernumoth;
gen yngsib`num' = (agediff`num' >= 0 & agediff`num' <= 4) & 
     (pernum ~= pernumoth);
keep year datanum serial pernum pernumoth yngsib*;
sort year datanum serial pernum;
save "$temp/tempsib`num'", replace;
};

*Determine whether individuals have ANY sibling within 4 years of age;

use "$temp/tempsib1.dta";
forvalues num = 2/20 {;
sort year datanum serial pernum;
merge year datanum serial pernum using 
     "$temp/tempsib`num'.dta";
drop _merge;
sort year datanum serial pernum;
save "$temp/tempsiball.dta", replace;
};

gen yngsib = yngsib1;
forvalues num = 2/20 {;
replace yngsib = 1 if yngsib`num' == 1;
};

keep year datanum serial pernum yngsib;
sort year datanum serial pernum;
merge year datanum serial pernum using "$temp/temp1.dta";
tab _merge;
drop _merge;

keep if birthyr <= 1968;

* Drop those respondents who moved states between the time that they were
born and the time they completed the Census;

gen moved = stbirth ~= stfips;
tab moved;
qui sum moved;
global stay1980 = 1-r(mean);
qui sum moved [aw=perwt];
global stay1980_wt = 1-r(mean);
drop if moved == 1;

sort ctyfips stbirth;
save "$temp/tempcens80.dta", replace;

* Merge in Sesame Street coverage data at the state level with state of
birth from the Census data. Note that these data are the ones that Riley 
coded that includes a few tweaks from the version I originally coded;

clear;
use "$raw/SScovcty_final.dta";

sum covratehat [weight=pop70];

keep ctyfips stfips covratehat vhfbest whenshow;
rename stfips stbirth;

sort ctyfips stbirth;
merge ctyfips stbirth using "$temp/tempcens80.dta";
tab _merge;
keep if _merge == 3;
drop _merge;

sort ctyfips stbirth;
save "$temp/temp1.dta", replace;

* Merge in data on the availability of Food Stamps in the individual's county
at the time of starting school and the fraction of the child's life between
ages 0 and 6 that Food Stamps were available. These data were provided by
Diane Schanzenbach.

clear;
use "$raw/fs_background.dta";
keep stfips countyfips fs_month fs_year;
rename countyfips ctyfips;
rename stfips stbirth;

sort ctyfips stbirth;
merge ctyfips stbirth using "$temp/temp1.dta";

tab _merge;
keep if _merge == 3;
drop _merge;

gen fsage6 = yearage6 >= fs_year;
gen fsage0_6 = (yearage6 - fs_year)/6;
     replace fsage0_6 = 0 if fsage0_6 < 0;
	 replace fsage0_6 = 1 if fsage0_6 > 1;
	 
sort ctyfips stbirth yearage6;
save "$temp/temp1.dta", replace;

* Merge in data on Head Start spending in the individual's county in the year
the individual was age 4. These data are available from Ludgwig and Miller's
2007 QJE paper. Values are only available for 1968 and 1972. I linearly
interpolate between those years to fill in. No spending took place before
1968;	 
*/
clear;
use "$raw/ludwig_miller_HSspend.dta";

rename qje68 hsspend68;
rename qje72a hsspend72;

keep oldcode hsspend* pop70;
merge oldcode using "$raw/ludwig_miller_fipsrecode";
tab _merge;
keep if _merge == 3;
drop _merge;

rename state stbirth;
rename county ctyfips;
drop if ctyfips == .;
sort cfips90;
drop if cfips90 == cfips90[_n-1];

reshape long hsspend, i(cfips90) j(year);

expand 6;
sort cfips90 year;

replace year = year + 1900;
replace year = 1963 if cfips90 ~= cfips90[_n-1] & year == 1968;
replace year = year[_n-1] + 1 if cfips90 == cfips90[_n-1];
replace hsspend = 0 if year <= 1967;
replace hsspend = .75*hsspend[_n-1] + .25*hsspend[_n+3] if year == 1969;
replace hsspend = .5*hsspend[_n-2] + .5*hsspend[_n+2] if year == 1970;
replace hsspend = .25*hsspend[_n-3] + .75*hsspend[_n+1] if year == 1971;
replace hsspend = hsspend[_n-4] if year == 1972;

gen hspercap = hsspend/pop70;
drop if year > 1972;
gen yearage6 = year+2;

drop cfips90 oldcode year pop70;

sort ctyfips stbirth yearage6;
merge ctyfips stbirth yearage6 using "$temp/temp1.dta";

tab _merge;
keep if _merge == 3;
drop _merge;	 
	 
sort ctyfips stbirth;
save "$temp/gradeforage_cty.dta", replace;

sort stbirth ctyfips yearage6;
collapse (mean) gradeage (count) numobs80=gradeage, by(stbirth ctyfips yearage6);
sort stbirth ctyfips yearage6;
save "$temp/agggfa80_cty.dta", replace;

erase "$temp/temp1.dta";
forvalues num = 1/20 {;
erase "$temp/tempsib`num'.dta";
};
erase "$temp/tempsiball.dta";

log close;


