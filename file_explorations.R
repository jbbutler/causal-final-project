library(haven)
library(dplyr)
library(ggplot2)

setwd('/Users/jbbutler129/Desktop/causal-final-project/data/raw/')

# Census Files (a bit weird, come back to this)
census1980 <- read.table('census1980.dat', header=F)

# .dta STATA files
commtowers <- read_dta('commtowers.dta')
convstate <- read_dta('convstate.dta')
counties <- read_dta('counties.dta')
coverage <- read_dta('coverage.dta')
cty_dma_xwalk <- read_dta('cty_dma_xwalk.dta')
fs_background <- read_dta('fs_background.dta')
ludwig_miller_fips_recode <- read_dta('ludwig_miller_fipsrecode.dta')
ludwig_miller_HSspend <- read_dta('ludwig_miller_HSspend.dta')
pbs_towers <- read_dta('pbstowers.dta')
school_cutoffs <- read_dta('school_cutoffs.dta')
SScovinstruments <- read_dta('SScov-instruments.dta')
SScovcty_final <- read_dta('SScovcty_final.dta')
SSstations <- read_dta('SSstations.dta')


allyrs_v1 <- read_dta('allyrs_v1.dta')


