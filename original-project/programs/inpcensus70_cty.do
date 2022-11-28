# delimit ;
capture log close;
log using "$logs/inpcensus70_cty.log", replace;

**********************

INPCENSUS70_CTY

**********************

This program inputs data from the 1970 Census to be used to examine whether
the introduction of Sesame Street had an impact on school enrollment. This
analysis is a placebo test, replicating the approach used with the 1980 Census
for this purpose;

set more 1;
clear;
infix 
  year         1-4       
  datanum      5-6       
  serial       7-14      
  hhwt        15-24      
  statefip    25-26      
  county      27-30      
  gq          31         
  pernum      32-35      
  perwt       36-45      
  momloc      46-47      
  sex         48         
  age         49-51      
  birthqtr    52         
  birthyr     53-56      
  race        57         
  raced       58-60      
  hispan      61         
  hispand     62-64      
  bpl         65-67      
  bpld        68-72      
  school      73         
  higrade     74-75      
  higraded    76-78      
  educ        79-80      
  educd       81-83      
  gradeatt    84         
  gradeattd   85-86      
  migplac5    87-89      
  using "$raw/census_1970_placebo.dat";
  
save "$temp/temp1.dta", replace;

gen momid = pernum;
sort year datanum serial pernum;

rename age momage;
rename bpl mombpl;
rename higrade momhigrad;
rename educd momeduc;

keep year datanum serial pernum momage mombpl momhigrad momeduc 
     momid;
sort year datanum serial momid;

save "$temp/tempmom.dta", replace;

clear;
use "$temp/temp1.dta";
  
keep if birthyr >= 1949 & birthyr <= 1965;
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

gen yearage6 = birthyr + 6;

gen schlstartyr = birthyr + 6;
     replace schlstartyr = birthyr + 7 if birthqtr == 3 & qtrcut == 3;
	 replace schlstartyr = birthyr + 7 if birthqtr == 4 & qtrcut >= 3;
* note Census is conducted in the spring of 1970;
gen hsclass = schlstartyr + 12;
gen predgrade70 = 12 - (hsclass - 1970);  
replace predgrade70 = 13 if predgrade70 >= 13;

gen grade70 = 0 if higraded <= 30;
	 replace grade70 = 1 if higraded >= 31 & higraded <= 40;
	 replace grade70 = 2 if higraded >= 41 & higraded <= 50;
	 replace grade70 = 3 if higraded >= 51 & higraded <= 60;
	 replace grade70 = 4 if higraded >= 61 & higraded <= 70;
	 replace grade70 = 5 if higraded >= 71 & higraded <= 80;
	 replace grade70 = 6 if higraded >= 81 & higraded <= 90;
     replace grade70 = 7 if higraded >= 091 & higraded <= 100;
     replace grade70 = 8 if higraded >= 101 & higraded <= 110;
     replace grade70 = 9 if higraded >= 111 & higraded <= 120;
     replace grade70 = 10 if higraded >= 121 & higraded <= 130;
	 replace grade70 = 11 if higraded >= 131 & higraded <= 140;
	 replace grade70 = 12 if higraded == 141 | higraded == 142;
	 replace grade70 = 13 if higraded >= 150;
gen gradeage = grade70 >= predgrade70;

tab predgrade70, sum(gradeage);
tab schlstartyr, sum(gradeage);
keep if birthyr <= 1961;

replace county = county/10;
replace county = . if county == 0;
rename county ctyfips;
sort year datanum serial pernum;
save "$temp/temp1.dta", replace;

* Drop those respondents who moved states between the time that they were
born and the time they completed the Census;

rename statefip stfips;
drop if stfips == 99;
gen moved = stbirth ~= stfips;
tab moved;
drop if moved == 1;

sort ctyfips stbirth;
save "$temp/tempcens70.dta", replace;

* Merge in Sesame Street coverage data at the state level with state of
birth from the Census data. Note that these data are the ones that Riley 
coded that includes a few tweaks from the version I originally coded;

clear;
use "$raw/SScovcty_final.dta";

sum covratehat [weight=pop70];

keep ctyfips stfips covratehat vhfbest whenshow;
rename stfips stbirth;

sort ctyfips stbirth;
merge ctyfips stbirth using "$temp/tempcens70.dta";
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

replace fs_year = fs_year - 20;

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

replace yearage6 = yearage6 - 10;

sort ctyfips stbirth yearage6;
merge ctyfips stbirth yearage6 using "$temp/temp1.dta";
tab _merge;
keep if _merge == 3;
drop _merge;	 

sort ctyfips stbirth;
save "$temp/gradeforage70_cty.dta", replace;

erase "$temp/temp1.dta";


log close;


