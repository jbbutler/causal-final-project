library(haven)
library(dplyr)
library(ggplot2)
library(readr)

setwd('/Users/jbbutler129/Desktop/causal-final-project/data/raw/')

########## Census Files ##########
# the census files are fixed-width format, meaning instead of columns being delimted
# by commas or tabs, they're specified by fixed character widths

### 1970 Census Stuff ###

# get vector of char widths for each column (taken from authors STATA code)
widths1970 <- c(4-1, 6-5, 14-7, 24-15, 26-25, 30-27, 0, 35-32, 45-36, 
                47-46, 0, 51-49, 0, 56-53, 0, 60-58, 0, 64-62, 67-65,
                72-68, 0, 75-74, 78-76, 80-79, 83-81, 0, 86-85, 89-87)
widths1970 <- widths1970 + 1
# get vector of column names (taken from authors STATA code)
names1970 <- c('year', 'datanum', 'serial', 'hhwt', 'statefip', 'county', 'gq', 
               'pernum', 'perwt', 'momloc', 'sex', 'age', 'birthqtr', 'birthyr', 
               'race', 'raced', 'hispan', 'hispand', 'bpl', 'bpld', 'school', 
               'higrade', 'higraded', 'educ', 'educd', 'gradeatt', 'gradeattd', 
               'migplac5')
# read in the data
census1970 <- read_fwf(file='census_1970_placebo.dat', 
                       col_positions=fwf_widths(widths1970, names1970))

### 1980 Census Stuff ###

# get vector of char widths for each column (taken from authors STATA code)
widths1980 <- c(4-1, 6-5, 14-7, 24-15, 26-25, 30-27, 0, 35-32, 45-36, 
                47-46, 0, 51-49, 0, 56-53, 0, 60-58, 0, 64-62, 67-65,
                72-68, 76-73, 78-77, 82-79, 0, 0, 86-85, 89-87, 91-90, 94-92, 0, 
                97-96, 100-98, 103-101, 0, 0)
widths1980 <- widths1980 + 1
# get vector of column names (taken from authors STATA code)
names1980 <- c('year', 'datanum', 'serial', 'hhwt', 'statefip', 'county', 'gq', 
               'pernum', 'perwt', 'momloc', 'sex', 'age', 'birthqtr', 'birthyr', 
               'race', 'raced', 'hispan', 'hispand', 'bpl', 'bpld', 'yrimmig', 
               'language', 'languaged', 'speakeng', 'school', 
               'higrade', 'higraded', 'educ', 'educd', 'gradeatt', 'gradeattd', 
               'migplac5', 'migcogrp', 'samemet5', 'migsamp')
# read in the data
census1980 <- read_fwf(file='census1980.dat', 
                       col_positions=fwf_widths(widths1980, names1980))

### 1990 Census Stuff ###

# get vector of char widths for each column (taken from authors STATA code)
widths1990 <- c(4-1, 6-5, 14-7, 24-15, 26-25, 30-27, 0, 35-32, 45-36, 
                47-46, 0, 51-49, 55-52, 0, 59-57, 0, 63-61, 66-64, 71-67, 75-72, 
                77-76, 81-78, 0, 0, 85-84, 88-86, 0, 91-90, 93-92, 95-94, 101-96, 
                106-102, 109-107, 112-110)
widths1990 <- widths1990 + 1
# get vector of column names (taken from authors STATA code)
names1990 <- c('year', 'datanum', 'serial', 'hhwt', 'statefip', 'county', 'gq', 
               'pernum', 'perwt', 'momloc', 'sex', 'age', 'birthyr', 
               'race', 'raced', 'hispan', 'hispand', 'bpl', 'bpld', 'yrimmig', 
               'language', 'languaged', 'speakeng', 'school', 
               'educ', 'educd', 'empstat', 'empstatd', 'wkswork1', 'uhrswork', 
               'incwage', 'incwelfr', 'poverty', 'migplac5')
# read in the data
census1990 <- read_fwf(file='census1990.dat', 
                       col_positions=fwf_widths(widths1990, names1990))

### 2000 Census Stuff ###

# get vector of char widths for each column (taken from authors STATA code)
widths2000 <- c(4-1, 6-5, 14-7, 24-15, 26-25, 30-27, 0, 35-32, 45-36, 
                47-46, 0, 51-49, 55-52, 0, 59-57, 0, 63-61, 66-64, 71-67, 75-72, 
                77-76, 81-78, 0, 84-83, 87-85, 0, 90-89, 92-91, 94-93, 100-95, 
                105-101, 108-106, 111-109)
widths2000 <- widths2000 + 1
# get vector of column names (taken from authors STATA code)
names2000 <- c('year', 'datanum', 'serial', 'hhwt', 'statefip', 'county', 'gq', 
               'pernum', 'perwt', 'momloc', 'sex', 'age', 'birthyr', 
               'race', 'raced', 'hispan', 'hispand', 'bpl', 'bpld', 'yrimmig', 
               'language', 'languaged', 'speakeng', 
               'educ', 'educd', 'empstat', 'empstatd', 'wkswork1', 'uhrswork', 
               'incwage', 'incwelfr', 'poverty', 'migplac5')
# read in the data
census2000 <- read_fwf(file='census2000.dat', 
                       col_positions=fwf_widths(widths2000, names2000))

########## .dta STATA files ##########

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


