# delimit ;
capture log close;
log using "$logs/inpcensus2000_cty.log", replace;

**********************

INPCENSUS2000_CTY

**********************

This program inputs data from the 2000 Census to be used to examine whether
the introduction of Sesame Street had an impact on labor market outcomes. This
version is based on county level data. Since county of birth is not identified,
the sample is restricted to those who live in the same state as they were born
in. Using county identifiers also means losing about half of the observations
because they have missing county identifiers;

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
  int     birthyr    52-55 
  byte    race       56-56 
  int     raced      57-59 
  byte    hispan     60-60 
  int     hispand    61-63 
  int     bpl        64-66 
  long    bpld       67-71 
  int     yrimmig    72-75 
  byte    language   76-77 
  int     languaged  78-81 
  byte    speakeng   82-82 
  byte    educ       83-84 
  int     educd      85-87 
  byte    empstat    88-88 
  byte    empstatd   89-90 
  byte    wkswork1   91-92 
  byte    uhrswork   93-94 
  long    incwage    95-100
  long    incwelfr   101-105
  int     poverty    106-108
  int     migplac5   109-111
  using "$raw/census2000.dat";

save "$temp/temp1.dta", replace;

gen yearage6 = birthyr + 6;
keep if yearage6 >= 1965 & yearage6 <= 1974;
rename statefip stfips;

replace county = county/10;
replace county = . if county == 0;
rename county ctyfips;
gen stbirth = bpl;
drop if stbirth > 56;

gen female = sex == 2;
gen hispanic = hispan ~= 0;
gen white = race == 1;
gen black = race == 2;
gen whitenh = white == 1 & hispanic == 0;
gen blacknh = black == 1 & hispanic == 0;
gen othernh = white == 0 & black == 0 & hispanic == 0;
gen native = bpl <= 56;
gen immigbef69 = yrimmig > 0 & yrimmig < 1970;
gen spanishhome = language == 12;
gen othlanghome = language > 1;
gen weakenglish = speakeng == 6;

gen move = stbirth ~= stfips;
tab move;
qui sum move;
global stay2000 = 1-r(mean);
qui sum move [aw=perwt];
global stay2000_wt = 1-r(mean);
keep if move == 0;
	 
gen hsdrop = educd < 62;
gen hsgrad = educd == 62;
gen anycol = educd > 62;
	 
gen educcat = 1 if hsdrop == 1;
     replace educcat = 2 if hsgrad == 1;
	 replace educcat = 3 if anycol == 1;
	 
gen working = empstat == 1;
gen inpov = poverty < 100;
gen welfare = incwelfr > 0 & incwelfr < 90000;
gen hrwage = incwage/(wkswork1*uhrswork);
     replace hrwage = . if hrwage < 1;
	 replace hrwage = . if hrwage > 1000;
	 
sort stbirth ctyfips;
save "$temp/temp1.dta", replace;

* Merge in Sesame Street coverage data at the state level with state of
birth from the Census data. Note that these data are the ones that Riley 
coded that includes a few tweaks from the version I originally coded;

clear;
use "$raw/SScovcty_final.dta";
keep stfips ctyfips covratehat;
rename stfips stbirth;

sort stbirth ctyfips;
merge stbirth ctyfips using "$temp/temp1.dta";
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

save "$temp\educearn2000_cty.dta", replace;
log close;


