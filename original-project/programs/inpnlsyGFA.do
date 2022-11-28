# delimit ;
capture log close;
log using "$logs/inpnlsyGFA.log", replace;

*********************************

INPNLSYGFA

*********************************

This program inputs NLSY79 data to estimate the relationship between grade
for age status in 1980 on hourly wages and employment in 2010;

set more 1;
clear;
infile using "$raw/grade_for_age.dct";


replace R0000100 = . if R0000100 < 0;
replace R0000300 = . if R0000300 < 0;  
replace R0000500 = . if R0001900 < 0;  
replace R0001900 = . if R0000500 < 0;  
replace R0006500 = . if R0006500 < 0;  
replace R0007900 = . if R0007900 < 0;  
replace R0017200 = . if R0017200 < 0;  
replace R0214700 = . if R0214700 < 0;  
replace R0214800 = . if R0214800 < 0; 
replace R0216100 = . if R0216100 < 0;
replace R0229100 = . if R0229100 < 0;  
replace R0329200 = . if R0329200 < 0;  
replace T2290400 = . if T2290400 < 0;  
replace T3106900 = . if T3106900 < 0;   

rename R0000100 id; 
rename R0000300 dobmonth;
rename R0000500 dobyear;
rename R0001900 wholiv14;
rename R0006500 mtreduc;
rename R0007900 ftreduc;
rename R0017200 hga79;
rename R0214700 raceeth;
rename R0214800 sex;
rename R0216100 wgt79;
rename R0229100 hga80;
rename R0329200 intmth80;
rename T2290400 emp2010;
rename T3106900 hrwage2010;

label var id "ID# (1-12686) 79";
label var dobmonth "DATE OF BIRTH - MONTH 79";
label var dobyear "DATE OF BIRTH - YR 79";
label var wholiv14 "WITH WHOM DID R LIVE @ AGE 14 79";
label var mtreduc "HGC BY RS MOTHER 79";
label var ftreduc "HGC BY RS FATHER 79";
label var hga79 "HIGHEST GRD ATND 79";
label var raceeth "RACL/ETHNIC COHORT /SCRNR 79";
label var sex "SEX OF R 79";
label var hga80 "HIGHEST GRD ATND 80";
label var intmth80 "INT REM INT DATE - MONTH 80";
label var emp2010 "R CURR WORKING FOR EMP? L1 2010";
label var hrwage2010 "HRLY RATE OF PAY JOB# 1 2010";

keep if dobyear == 62 | dobyear == 63 | dobyear == 64;

replace hrwage2010 = hrwage2010/100;
gen lnwage = log(hrwage2010);
replace hga80 = . if hga80 == 95;
replace hga79 = . if hga79 == 95;

gen female = sex-1;
gen blacknh = raceeth == 2;
gen hispanic = raceeth == 1;

gen mtrpres = 1 if wholiv14 == 11 | wholiv14 == 12 | wholiv14 == 21 | 
      wholiv14 == 22 | wholiv14 == 31 | wholiv14 == 32 | wholiv14 == 41 |
      wholiv14 == 42 | wholiv14 == 51 | wholiv14 == 52 | wholiv14 == 91;
replace mtrpres = 0 if mtrpres == .;
gen ftrpres = 1 if wholiv14 == 11 | wholiv14 == 12 | wholiv14 == 21 | 
      wholiv14 == 22 | wholiv14 == 13 | wholiv14 == 32 | wholiv14 == 15 |
      wholiv14 == 19 | wholiv14 == 23 | wholiv14 == 24 | wholiv14 == 25;
replace ftrpres = 0 if ftrpres == .;
gen bothpar = 1 if mtrpres == 1 & ftrpres == 1;
      replace bothpar = 0 if bothpar == .;
gen mtronly = 1 if mtrpres == 1 & ftrpres == 0;
     replace mtronly = 0 if mtronly == .;
gen ftronly = 1 if mtrpres == 0 & ftrpres == 1;
     replace ftronly = 0 if ftronly == .;
	 
replace mtreduc = 0 if mtrpres == 0;
replace ftreduc = 0 if ftrpres == 0;

sort id;
save "$temp/temp1.dta", replace;

clear;
infile using "$raw/geocodes7991.dct";

keep R0000100 R0000400 R0001000;

rename R0000100 id;
rename R0000400 dobday;
rename R0001000 stbirth;

replace dobday = . if dobday < 0;
replace stbirth = . if stbirth < 0 | stbirth > 56;

sort id;
merge id using "$temp/temp1.dta";
keep if _merge == 3;
drop _merge;

sort stbirth;
save "$temp/temp1.dta", replace;

clear;
use "$raw/convstate.dta";
rename statefips stbirth;
sort stbirth;
merge 1:m stbirth using "$temp/temp1.dta";
tab _merge;
keep if _merge == 3;
drop _merge;

gen dayage6 = 365.25*6 + mdy(dobmonth, dobday, 1900+dobyear);

gen cutmonth = 9 if stname == "CO" | stname == "DE" | stname == "KS" |
     stname == "MD" | stname == "MN" | stname == "MT" | stname == "TX" |
	 stname == "UT" | stname == "NH" | stname == "IA" | stname == "WY" |
	 stname == "MO" | stname == "TN" | stname == "VA";
replace cutmonth = 10 if stname == "AL" | stname == "AR" | stname == "NJ" |
     stname == "NC" | stname == "ME" | stname == "NE" | stname == "ID" |
	 stname == "ND" | stname == "OH" | stname == "SD";
replace cutmonth = 11 if stname == "OK" | stname == "SC" | stname == "WV" |
     stname == "AK" | stname == "OR";
replace cutmonth = 12 if stname == "CA" | stname == "IL" | stname == "MI" |
     stname == "NY";
replace cutmonth = 1 if cutmonth == .;

gen start68 = 1 if mdy(cutmonth,15,1968) >= dayage6;
     replace start68 = 1 if mdy(cutmonth,15,1969) >= dayage6 & cutmonth == 1;
gen start69 = 1 if mdy(cutmonth,15,1969) >= dayage6;
     replace start69 = 1 if mdy(cutmonth,15,1970) >= dayage6 & cutmonth == 1;
gen start70 = 1 if mdy(cutmonth,15,1970) >= dayage6;
     replace start70 = 1 if mdy(cutmonth,15,1971) >= dayage6 & cutmonth == 1;

gen schlstartyr = 1968 if start68 == 1;
replace schlstartyr = 1969 if start69 == 1 & start68 == .;
replace schlstartyr = 1970 if start70 == 1 & start69 == .;
drop if schlstartyr == .;

gen predgrade79 = 1979 - schlstartyr;
gen gfa79 = hga79 >= predgrade79;

sum gfa79 [weight=wgt79];
regress emp2010 gfa79 [weight=wgt79], robust;
regress emp2010 gfa79 female blacknh hispanic dobyear bothpar ftrpres mtreduc 
     ftreduc [weight=wgt79], robust;
regress lnwage gfa79 [weight=wgt79], robust;
regress lnwage gfa79 female blacknh hispanic dobyear bothpar ftrpres mtreduc 
     ftreduc [weight=wgt79], robust;

log close;

