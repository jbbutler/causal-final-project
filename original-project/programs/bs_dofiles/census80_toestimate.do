cd "$final"
use gradeforage_cty, clear
drop if schlstartyr == 1975

gen preschl69 = schlstartyr > 1969
gen preschlcov = preschl69*covratehat

gen statecty = 1000*stbirth + ctyfips

forval yr = 65/74 {
	gen start`yr' = schlstartyr == 19`yr'
	gen covst`yr' = covratehat*start`yr'
}
gen start6768 = schlstartyr == 1967 | schlstartyr == 1968
gen start7072 = schlstartyr == 1970 | schlstartyr == 1971 | schlstartyr == 1972
gen start7374 = schlstartyr == 1973 | schlstartyr == 1974

gen covst6768 = covratehat*start6768
gen covst7072 = covratehat*start7072
gen covst7374 = covratehat*start7374

gen startyr = .
foreach yr in 65 66 67 68 69 70 71 72 73 74 {
	replace startyr = `yr' if start`yr' ==1
}
egen statecohort = group(stfips startyr)
replace statecty = 12086 if statecty == 12025
cd "$final" 
merge m:1 statecty using "$raw/cty_dma_xwalk"
drop if _m == 2
drop _m
cd "$final"
save census80, replace
