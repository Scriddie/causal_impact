cd "c:\3ie\data"

****************************************************************************************
****************************************************************************************
* SECTION 1:  CREATE MONTHLY MISSED VISIT ESTIMATES FOR TIME SERIES - ALL PATIENTS
****************************************************************************************
****************************************************************************************
log using "c:\3ie\analysis\ITS_analysis_existing_all.log", replace
* log close
use "existing pts\3ie_exist_vis.dta", clear

* restrict sample
drop if out_of_range==1

* create time series variables by facility
sort fac_id sched_mon
by fac_id sched_mon: egen miss_1 = mean(miss)
by fac_id sched_mon: egen miss_3 = mean(miss3)
by fac_id sched_mon: egen miss_7 = mean(miss7)
by fac_id sched_mon: egen miss_15 = mean(miss15)
by fac_id sched_mon: egen miss_60 = mean(miss60)
by fac_id sched_mon: keep if _n==1
gen group_no=fac_id+100
drop group
drop if out_of_range==1
rename fac_label group

keep group group_no interv post_its post_its2 sched_mon sched_yr sched_mo post_its miss_1 miss_3 miss_7 miss_15 miss_60 out_of_range
order group group_no interv sched_mon sched_yr sched_mo post_its miss_1 miss_3 miss_7 miss_15 miss_60
save temp_ITS_byfacility.dta, replace

use "existing pts\3ie_exist_vis.dta", clear

* restrict sample
drop if out_of_range==1

* create time series variables by group
sort group sched_mon
by group sched_mon: egen miss_1 = mean(miss)
by group sched_mon: egen miss_3 = mean(miss3)
by group sched_mon: egen miss_7 = mean(miss7)
by group sched_mon: egen miss_15 = mean(miss15)
by group sched_mon: egen miss_60 = mean(miss60)
by group sched_mon: keep if _n==1
gen group_no=0
replace group_no=1 if group=="Intervention"
order group group_no interv sched_mon sched_yr sched_mo post_its miss_1 miss_3 miss_7 miss_15 miss_60 out_of_range

keep group group_no interv post_its post_its2 sched_mon sched_yr sched_mo post_its miss_1 miss_3 miss_7 miss_15 miss_60 out_of_range
save temp_ITS_bygroup.dta, replace

gen diff_1 = miss_1-miss_1[_n-21] if _n>21
gen diff_3 = miss_3-miss_3[_n-21] if _n>21
gen diff_7 = miss_7-miss_7[_n-21] if _n>21
gen diff_15 = miss_15-miss_15[_n-21] if _n>21
gen diff_60 = miss_60-miss_60[_n-21] if _n>21
drop if group=="Control"
replace group="Diff"
replace group_no=2
replace interv=.
drop miss_1 miss_3 miss_7 miss_15 miss_60
rename diff_1 miss_1
rename diff_3 miss_3
rename diff_7 miss_7
rename diff_15 miss_15
rename diff_60 miss_60
save temp_ITS_diff.dta, replace

use temp_ITS_bygroup.dta, clear
append using temp_ITS_diff.dta
append using temp_ITS_byfacility.dta

order group group_no interv sched_mon sched_yr sched_mo post_its post_its2 miss_1 miss_3 miss_7 miss_15 miss_60
keep group group_no interv sched_mon sched_yr sched_mo post_its post_its2 miss_1 miss_3 miss_7 miss_15 miss_60

save "temp_ITS_monthly_missed_visits_all.dta", replace

**************************************************************************************
* CREATE MONTHLY ADHERENCE ESTIMATES
**************************************************************************************
* create time series variables by facility
use "existing pts\3ie_exist_PDC.dta", clear

* restrict sample
drop if out_of_range==1

sort fac_id sched_mon
by fac_id sched_mon: egen avgPDC = mean(PDC)
* divide PDC by 100 to put in percent scale
replace avgPDC = avgPDC/100
by fac_id sched_mon: egen PDC80 = mean(PDCge80)
by fac_id sched_mon: egen PDC95 = mean(PDCge95)
by fac_id sched_mon: keep if _n==1
gen group_no=fac_id+100
drop group
rename fac_label group

keep group group_no interv sched_mon sched_yr sched_mo post_its post_its2 avgPDC PDC80 PDC95
order group group_no interv sched_mon sched_yr sched_mo post_its post_its2 avgPDC PDC80 PDC95
save temp_PDC_byfacility.dta, replace

* create time series variables by group
use "existing pts\3ie_exist_PDC.dta", clear

* restrict sample
drop if out_of_range==1

sort group sched_mon
tabulate group, missing

by group sched_mon: egen avgPDC = mean(PDC)
* divide PDC by 100 to put in percent scale
replace avgPDC = avgPDC/100
by group sched_mon: egen PDC80 = mean(PDCge80)
by group sched_mon: egen PDC95 = mean(PDCge95)
by group sched_mon: keep if _n==1
gen group_no=0
replace group_no=1 if group=="Intervention"

drop if sched_mon<1 | sched_mon>21

keep group group_no interv sched_mon sched_yr sched_mo post_its post_its2 avgPDC PDC80 PDC95
order group group_no interv sched_mon sched_yr sched_mo post_its post_its2 avgPDC PDC80 PDC95

save temp_PDC_bygroup.dta, replace

gen diff_avgPDC = avgPDC-avgPDC[_n-21] if _n>21
gen diff_PDC80 = PDC80-PDC80[_n-21] if _n>21
gen diff_PDC95 = PDC95-PDC95[_n-21] if _n>21
drop if group=="Control"
replace group="Diff"
replace group_no=2
replace interv=.
drop avgPDC PDC80 PDC95
rename diff_avgPDC avgPDC
rename diff_PDC80 PDC80
rename diff_PDC95 PDC95
save temp_PDC_diff.dta, replace

use temp_PDC_bygroup.dta, clear
append using temp_PDC_diff.dta
append using temp_PDC_byfacility.dta

save "temp_ITS_monthly_PDC_all.dta", replace

*****************************************************************************************
* COMBINE MISSED VISIT AND PDC DATASETS FOR ITS ANALYSES
*****************************************************************************************
use "temp_ITS_monthly_missed_visits_all.dta", clear

merge 1:1 group_no sched_mon using "temp_ITS_monthly_PDC_all.dta"
save "existing pts\3ie_ITS_analysis_all.dta", replace

******************************************************************************
* TIME SERIES DISPLAY OF INTERVENTION, CONTROL, AND DIFFERENCE
******************************************************************************
use "existing pts\3ie_ITS_analysis_all.dta", clear

* restrict sample
drop if sched_mon>20

* missed visits
#d ;
twoway 
	(connected miss_1 sched_mon if group_no==1, msymbol(none)) 
	|| connected miss_1 sched_mon if group_no==0, msymbol(none) lcolor(blue)
	|| connected miss_1 sched_mon if group_no==2, msymbol(none) lcolor(black) lwidth(thin)
	scheme(s1color) graphregion(fcolor(ltbluishgray8)) plotregion(fcolor(white))
	title("Monthly visits missed") 
	subtitle("Intervention, control, monthly differences - all patients")
	ytitle("% visits missed") 
	ylabel(-.1 "-10%" 0 "0%" .1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%", labsize(medium) angle(horizontal) grid) 
	yline(0, lwidth(thin) lpattern(dash) lcolor(black)) 
	xtitle("Study month")
	xline(13.5, lwidth(thick) lpattern(solid) lcolor(black)) 
	legend(rows (1) lab(1 "intervention") lab(2 "control") lab(3 "I-C difference"))
	saving(c:\3ie\analysis\ITS_missed_all, replace)
	xsize(2.97) ysize(2) scale(1.0);
#d cr

* missed visits by 3 days
#d ;
twoway 
	(connected miss_3 sched_mon if group_no==1, msymbol(none)) 
	|| connected miss_3 sched_mon if group_no==0, msymbol(none) lcolor(blue)
	|| connected miss_3 sched_mon if group_no==2, msymbol(none) lcolor(black) lwidth(thin)
	scheme(s1color) graphregion(fcolor(ltbluishgray8)) plotregion(fcolor(white))
	title("Monthly visits missed by 3+ days") 
	subtitle("Intervention, control, monthly differences - all patients")
	ytitle("% visits missed") 
	ylabel(-.1 "-10%" 0 "0%" .1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%", labsize(medium) angle(horizontal) grid) 
	yline(0, lwidth(thin) lpattern(dash) lcolor(black)) 
	xtitle("Study month")
	xline(13.5, lwidth(thick) lpattern(solid) lcolor(black)) 
	legend(rows (1) lab(1 "intervention") lab(2 "control") lab(3 "I-C difference"))
	saving(c:\3ie\analysis\ITS_missed3_all, replace) 
	xsize(2.97) ysize(2) scale(1.0);
#d cr

* missed visits by 7 days
#d ;
twoway 
	(connected miss_7 sched_mon if group_no==1, msymbol(none)) 
	|| connected miss_7 sched_mon if group_no==0, msymbol(none) lcolor(blue)
	|| connected miss_7 sched_mon if group_no==2, msymbol(none) lcolor(black) lwidth(thin)
	scheme(s1color) graphregion(fcolor(ltbluishgray8)) plotregion(fcolor(white))
	title("Monthly visits missed by 7+ days") 
	subtitle("Intervention, control, monthly differences - all patients")
	ytitle("% visits missed") 
	ylabel(-.1 "-10%" 0 "0%" .1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%", labsize(medium) angle(horizontal) grid) 
	yline(0, lwidth(thin) lpattern(dash) lcolor(black)) 
	xtitle("Study month")
	xline(13.5, lwidth(thick) lpattern(solid) lcolor(black)) 
	legend(rows (1) lab(1 "intervention") lab(2 "control") lab(3 "I-C difference"))
	saving(c:\3ie\analysis\ITS_missed7_all, replace) 
	xsize(2.97) ysize(2) scale(1.0);
#d cr

* missed visits by 15 days
#d ;
twoway 
	(connected miss_15 sched_mon if group_no==1, msymbol(none)) 
	|| connected miss_15 sched_mon if group_no==0, msymbol(none) lcolor(blue)
	|| connected miss_15 sched_mon if group_no==2, msymbol(none) lcolor(black) lwidth(thin)
	scheme(s1color) graphregion(fcolor(ltbluishgray8)) plotregion(fcolor(white))
	title("Monthly visits missed by 15+ days") 
	subtitle("Intervention, control, monthly differences - all patients")
	ytitle("% visits missed") 
	ylabel(-.1 "-10%" 0 "0%" .1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%", labsize(medium) angle(horizontal) grid) 
	yline(0, lwidth(thin) lpattern(dash) lcolor(black)) 
	xtitle("Study month")
	xline(13.5, lwidth(thick) lpattern(solid) lcolor(black)) 
	legend(rows (1) lab(1 "intervention") lab(2 "control") lab(3 "I-C difference"))
	saving(c:\3ie\analysis\ITS_missed15_all, replace) 
	xsize(2.97) ysize(2) scale(1.0);
#d cr
  
* missed visits by 60 days
#d ;
twoway 
	(connected miss_60 sched_mon if group_no==1, msymbol(none)) 
	|| connected miss_60 sched_mon if group_no==0, msymbol(none) lcolor(blue)
	|| connected miss_60 sched_mon if group_no==2, msymbol(none) lcolor(black) lwidth(thin)
	scheme(s1color) graphregion(fcolor(ltbluishgray8)) plotregion(fcolor(white))
	title("Monthly visits missed by 60+ days") 
	subtitle("Intervention, control, monthly differences - all patients")
	ytitle("% visits missed") 
	ylabel(-.1 "-10%" 0 "0%" .1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%", labsize(medium) angle(horizontal) grid) 
	yline(0, lwidth(thin) lpattern(dash) lcolor(black)) 
	xtitle("Study month")
	xline(13.5, lwidth(thick) lpattern(solid) lcolor(black)) 
	legend(rows (1) lab(1 "intervention") lab(2 "control") lab(3 "I-C difference"))
	saving(c:\3ie\analysis\ITS_missed60_all, replace) 
	xsize(2.97) ysize(2) scale(1.0);
#d cr

* average PDC
#d ;
twoway 
	(connected avgPDC sched_mon if group_no==1, msymbol(none)) 
	|| connected avgPDC sched_mon if group_no==0, msymbol(none) lcolor(blue)
	|| connected avgPDC sched_mon if group_no==2, msymbol(none) lcolor(black) lwidth(thin)
	scheme(s1color) graphregion(fcolor(ltbluishgray8)) plotregion(fcolor(white))
	title("Average proportion of days covered (PDC)") 
	subtitle("Intervention, control, monthly differences - all patients")
	ytitle("Average PDC") 
	ylabel(-.20 "-20%" 0 "0%" .20 "20%" .40 "40%" .60 "60%" .80 "80%" 1.00 "100%", labsize(medium) angle(horizontal) grid) 
	yline(0, lwidth(thin) lpattern(dash) lcolor(black)) 
	xtitle("Study month")
	xline(13.5, lwidth(thick) lpattern(solid) lcolor(black)) 
	legend(rows (1) lab(1 "intervention") lab(2 "control") lab(3 "I-C difference"))
	saving(c:\3ie\analysis\ITS_avgPDC_all, replace) 
	xsize(2.97) ysize(2) scale(1.0);
#d cr

* Percent PDC 80% or more
#d ;
twoway 
	(connected PDC80 sched_mon if group_no==1, msymbol(none)) 
	|| connected PDC80 sched_mon if group_no==0, msymbol(none) lcolor(blue)
	|| connected PDC80 sched_mon if group_no==2, msymbol(none) lcolor(black) lwidth(thin)
	scheme(s1color) graphregion(fcolor(ltbluishgray8)) plotregion(fcolor(white))
	title("Percent of patients with PDC 80% or more") 
	subtitle("Intervention, control, monthly differences - all patients")
	ytitle("% PDC >= 80%") 
	ylabel(-.20 "-20%" 0 "0%" .20 "20%" .40 "40%" .60 "60%" .80 "80%" 1.00 "100%", labsize(medium) angle(horizontal) grid) 
	yline(0, lwidth(thin) lpattern(dash) lcolor(black)) 
	xtitle("Study month")
	xline(13.5, lwidth(thick) lpattern(solid) lcolor(black)) 
	legend(rows (1) lab(1 "intervention") lab(2 "control") lab(3 "I-C difference"))
	saving(c:\3ie\analysis\ITS_PDC80_all, replace) 
	xsize(2.97) ysize(2) scale(1.0);
#d cr

* Percent PDC 95% or more
#d ;
twoway 
	(connected PDC95 sched_mon if group_no==1, msymbol(none)) 
	|| connected PDC95 sched_mon if group_no==0, msymbol(none) lcolor(blue)
	|| connected PDC95 sched_mon if group_no==2, msymbol(none) lcolor(black) lwidth(thin)
	scheme(s1color) graphregion(fcolor(ltbluishgray8)) plotregion(fcolor(white))
	title("Percent of patients with PDC 95% or more") 
	subtitle("Intervention, control, monthly differences - all patients")
	ytitle("% PDC >= 95%") 
	ylabel(-.20 "-20%" 0 "0%" .20 "20%" .40 "40%" .60 "60%" .80 "80%" 1.00 "100%", labsize(medium) angle(horizontal) grid) 
	yline(0, lwidth(thin) lpattern(dash) lcolor(black)) 
	xtitle("Study month")
	xline(13.5, lwidth(thick) lpattern(solid) lcolor(black)) 
	legend(rows (1) lab(1 "intervention") lab(2 "control") lab(3 "I-C difference"))
	saving(c:\3ie\analysis\ITS_PDC95_all, replace) 
	xsize(2.97) ysize(2) scale(1.0);
#d cr

*****************************************************************************
* ITS MODEL USING NEWEY ESTIMATION
*****************************************************************************
use "existing pts\3ie_ITS_analysis_all.dta", clear

* restrict sample
drop if sched_mon>20

* select model with month 14 missing from pre (its2_post) or included in pre (its_post)
gen level = post_its
* to run model with Aug 2014 not included in pre
* gen level = post_its2
gen trend = (sched_mon-13)*level 
tsset group_no sched_mon

* MODEL INTERVENTION EFFECTS
* interv missed visits
newey miss_1 sched_mon level trend if group_no==1 , lag(12)
predict beta
estimates store I1_full_all
* outsheet using "Analysis\Interv miss_1 newey all.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* interv 3-day missed visits
newey miss_3 sched_mon level trend if group_no==1 , lag(12)
predict beta
estimates store I3_full_all
* outsheet using "Analysis\Interv miss_3 newey all.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* interv 7-day missed visits
newey miss_7 sched_mon level trend if group_no==1 , lag(12)
predict beta
estimates store I7_full_all
* outsheet using "Analysis\Interv miss_7 newey all.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* interv 15-day missed visits
newey miss_15 sched_mon level trend if group_no==1 & sched_mon<21, lag(12)
predict beta
estimates store I15_full_all
* outsheet using "Analysis\Interv miss_15 newey all.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* interv 60-day missed visits
newey miss_60 sched_mon level trend if group_no==1 & sched_mon<20, lag(12)
predict beta
estimates store I60_full_all
* outsheet using "Analysis\Interv miss_60 newey all.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* PDC models exclude first month which is high by definition

* interv avgPDC
newey avgPDC sched_mon level trend if group_no==1 & sched_mon>1 , lag(12)
predict beta
estimates store IavgPDC_full_all
* outsheet using "Analysis\Interv avgPDC newey all.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* interv PDC80
newey PDC80 sched_mon level trend if group_no==1  & sched_mon>1 , lag(12)
predict beta
estimates store IPDC80_full_all
* outsheet using "Analysis\Interv PDC80 newey all.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* interv PDC95
newey PDC95 sched_mon level trend if group_no==1  & sched_mon>1 , lag(12)
predict beta
estimates store IPDC95_full_all
* outsheet using "Analysis\Interv PDC95 newey all.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]


* MODEL DIFFERENCES
* diff in missed visits
newey miss_1 sched_mon level trend if group_no==2 , lag(12)
predict beta
estimates store D1_full_all
* outsheet using "Analysis\Diff miss_1 newey all.csv", replace comma
cap drop beta
* absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* diff in 3-day missed visits
newey miss_3 sched_mon level trend if group_no==2 , lag(12)
predict beta
estimates store D3_full_all
* outsheet using "Analysis\Diff miss_3 newey all.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* diff in 7-day missed visits
newey miss_7 sched_mon level trend if group_no==2 , lag(12)
predict beta
estimates store D7_full_all
* outsheet using "Analysis\Diff miss_7 newey all.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* diff 15-day missed visits
newey miss_15 sched_mon level trend if group_no==2 & sched_mon<21, lag(12)
predict beta
estimates store D15_full_all
* outsheet using "Analysis\Diff miss_15 newey all.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* diff 60-day missed visits
newey miss_60 sched_mon level trend if group_no==2 & sched_mon<20, lag(12)
predict beta
estimates store D60_full_all
* outsheet using "Analysis\Diff miss_60 newey all.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* PDC models exclude first month which is high by definition

* diff avgPDC
newey avgPDC sched_mon level trend if group_no==2  & sched_mon>1 , lag(12)
predict beta
estimates store DavgPDC_full_all
* outsheet using "Analysis\Diff avgPDC newey all.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* diff PDC80
newey PDC80 sched_mon level trend if group_no==2  & sched_mon>1 , lag(12)
predict beta
estimates store DPDC80_full_all
* outsheet using "Analysis\Diff PDC80 newey all.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* diff PDC95
newey PDC95 sched_mon level trend if group_no==2  & sched_mon>1 , lag(12)
predict beta
estimates store DPDC95_full_all
* outsheet using "Analysis\Diff PDC95 newey all.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]


***********************************************************************************************************
* TABLE ALL ESTIMATES FROM ITS MODELS FOR ALL PATIENTS
***********************************************************************************************************
esttab I1_full_all I3_full_all I7_full_all I15_full_all I60_full_all ///
		IavgPDC_full_all IPDC80_full_all IPDC95_full_all /// 
	using c:\3ie\analysis\ITS_all_full_model_interven.rtf, stats(N) b(%8.3f) ci(%8.2f) nogaps ///
	title("ITS effects full PDC models intervention group - all patients") replace

esttab D1_full_all D3_full_all D7_full_all D15_full_all D60_full_all ///
		DavgPDC_full_all DPDC80_full_all DPDC95_full_all ///
	using c:\3ie\analysis\ITS_all_full_model_diffs.rtf, stats(N) b(%8.3f) ci(%8.2f) nogaps ///
	title("ITS effects full PDC models differences - all patients") replace

log close

		
*********************************************************************************************
*********************************************************************************************
* SECTION 2: CREATE MONTHLY MISSED VISIT ESTIMATES FOR TIME SERIES - CONTINUOUS PATIENTS
*********************************************************************************************
*********************************************************************************************
log using "c:\3ie\analysis\ITS_analysis_existing_contin.log", replace
* log close
use "existing pts\3ie_exist_vis.dta", clear

* restrict sample
drop if out_of_range==1
drop if continuous==0

* create time series variables by facility
sort fac_id sched_mon
by fac_id sched_mon: egen miss_1 = mean(miss)
by fac_id sched_mon: egen miss_3 = mean(miss3)
by fac_id sched_mon: egen miss_7 = mean(miss7)
by fac_id sched_mon: egen miss_15 = mean(miss15)
by fac_id sched_mon: egen miss_60 = mean(miss60)
by fac_id sched_mon: keep if _n==1
gen group_no=fac_id+100
drop group
drop if out_of_range==1
rename fac_label group

keep group group_no interv post_its post_its2 sched_mon sched_yr sched_mo post_its miss_1 miss_3 miss_7 miss_15 miss_60 out_of_range
order group group_no interv sched_mon sched_yr sched_mo post_its miss_1 miss_3 miss_7 miss_15 miss_60
save temp_ITS_byfacility.dta, replace

use "existing pts\3ie_exist_vis.dta", clear

* restrict sample
drop if out_of_range==1
drop if continuous==0

* create time series variables by group
sort group sched_mon
by group sched_mon: egen miss_1 = mean(miss)
by group sched_mon: egen miss_3 = mean(miss3)
by group sched_mon: egen miss_7 = mean(miss7)
by group sched_mon: egen miss_15 = mean(miss15)
by group sched_mon: egen miss_60 = mean(miss60)
by group sched_mon: keep if _n==1
gen group_no=0
replace group_no=1 if group=="Intervention"
order group group_no interv sched_mon sched_yr sched_mo post_its miss_1 miss_3 miss_7 miss_15 miss_60 out_of_range

keep group group_no interv post_its post_its2 sched_mon sched_yr sched_mo post_its miss_1 miss_3 miss_7 miss_15 miss_60 out_of_range
save temp_ITS_bygroup.dta, replace

gen diff_1 = miss_1-miss_1[_n-21] if _n>21
gen diff_3 = miss_3-miss_3[_n-21] if _n>21
gen diff_7 = miss_7-miss_7[_n-21] if _n>21
gen diff_15 = miss_15-miss_15[_n-21] if _n>21
gen diff_60 = miss_60-miss_60[_n-21] if _n>21
drop if group=="Control"
replace group="Diff"
replace group_no=2
replace interv=.
drop miss_1 miss_3 miss_7 miss_15 miss_60
rename diff_1 miss_1
rename diff_3 miss_3
rename diff_7 miss_7
rename diff_15 miss_15
rename diff_60 miss_60
save temp_ITS_diff.dta, replace

use temp_ITS_bygroup.dta, clear
append using temp_ITS_diff.dta
append using temp_ITS_byfacility.dta

order group group_no interv sched_mon sched_yr sched_mo post_its post_its2 miss_1 miss_3 miss_7 miss_15 miss_60
keep group group_no interv sched_mon sched_yr sched_mo post_its post_its2 miss_1 miss_3 miss_7 miss_15 miss_60

save "temp_ITS_monthly_missed_visits_contin.dta", replace

**************************************************************************************
* CREATE MONTHLY ADHERENCE ESTIMATES - CONTINUOUS PATIENTS
**************************************************************************************
* create time series variables by facility
use "existing pts\3ie_exist_PDC.dta", clear

* restrict sample
drop if out_of_range==1
drop if continuous==0

sort fac_id sched_mon
by fac_id sched_mon: egen avgPDC = mean(PDC)
* divide PDC by 100 to put in percent scale
replace avgPDC = avgPDC/100
by fac_id sched_mon: egen PDC80 = mean(PDCge80)
by fac_id sched_mon: egen PDC95 = mean(PDCge95)
by fac_id sched_mon: keep if _n==1
gen group_no=fac_id+100
drop group
rename fac_label group

keep group group_no interv sched_mon sched_yr sched_mo post_its post_its2 avgPDC PDC80 PDC95
order group group_no interv sched_mon sched_yr sched_mo post_its post_its2 avgPDC PDC80 PDC95
save temp_PDC_byfacility.dta, replace

* create time series variables by group
use "existing pts\3ie_exist_PDC.dta", clear

* restrict sample
drop if out_of_range==1
drop if continuous==0

sort group sched_mon
tabulate group, missing

by group sched_mon: egen avgPDC = mean(PDC)
* divide PDC by 100 to put in percent scale
replace avgPDC = avgPDC/100
by group sched_mon: egen PDC80 = mean(PDCge80)
by group sched_mon: egen PDC95 = mean(PDCge95)
by group sched_mon: keep if _n==1
gen group_no=0
replace group_no=1 if group=="Intervention"

drop if sched_mon<1 | sched_mon>21

keep group group_no interv sched_mon sched_yr sched_mo post_its post_its2 avgPDC PDC80 PDC95
order group group_no interv sched_mon sched_yr sched_mo post_its post_its2 avgPDC PDC80 PDC95

save temp_PDC_bygroup.dta, replace

gen diff_avgPDC = avgPDC-avgPDC[_n-21] if _n>21
gen diff_PDC80 = PDC80-PDC80[_n-21] if _n>21
gen diff_PDC95 = PDC95-PDC95[_n-21] if _n>21
drop if group=="Control"
replace group="Diff"
replace group_no=2
replace interv=.
drop avgPDC PDC80 PDC95
rename diff_avgPDC avgPDC
rename diff_PDC80 PDC80
rename diff_PDC95 PDC95
save temp_PDC_diff.dta, replace

use temp_PDC_bygroup.dta, clear
append using temp_PDC_diff.dta
append using temp_PDC_byfacility.dta

save "temp_ITS_monthly_PDC_contin.dta", replace

*****************************************************************************************
* COMBINE MISSED VISIT AND PDC DATASETS FOR ITS ANALYSES
*****************************************************************************************
use "temp_ITS_monthly_missed_visits_contin.dta", clear

merge 1:1 group_no sched_mon using "temp_ITS_monthly_PDC_contin.dta"
save "existing pts\3ie_ITS_analysis_contin.dta", replace

*************************************************************************************
* TIME SERIES DISPLAY OF INTERVENTION, CONTROL, AND DIFFERENCE - CONTINUOUS PATIENTS
*************************************************************************************
use "existing pts\3ie_ITS_analysis_contin.dta", clear

* restrict sample
drop if sched_mon>20
table sched_mon

* missed visits
#d ;
twoway 
	(connected miss_1 sched_mon if group_no==1, msymbol(none)) 
	|| connected miss_1 sched_mon if group_no==0, msymbol(none) lcolor(blue)
	|| connected miss_1 sched_mon if group_no==2, msymbol(none) lcolor(black) lwidth(thin)
	scheme(s1color) graphregion(fcolor(ltbluishgray8)) plotregion(fcolor(white))
	title("Monthly visits missed") 
	subtitle("Intervention, control, monthly differences - continuous patients")
	ytitle("% visits missed") 
	ylabel(-.1 "-10%" 0 "0%" .1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%", labsize(medium) angle(horizontal) grid) 
	yline(0, lwidth(thin) lpattern(dash) lcolor(black)) 
	xtitle("Study month")
	xline(13.5, lwidth(thick) lpattern(solid) lcolor(black)) 
	legend(rows (1) lab(1 "intervention") lab(2 "control") lab(3 "I-C difference"))
	saving(c:\3ie\analysis\ITS_missed_contin, replace) 
	xsize(2.97) ysize(2) scale(1.0);
#d cr

* missed visits by 3 days
#d ;
twoway 
	(connected miss_3 sched_mon if group_no==1, msymbol(none)) 
	|| connected miss_3 sched_mon if group_no==0, msymbol(none) lcolor(blue)
	|| connected miss_3 sched_mon if group_no==2, msymbol(none) lcolor(black) lwidth(thin)
	scheme(s1color) graphregion(fcolor(ltbluishgray8)) plotregion(fcolor(white))
	title("Monthly visits missed by 3+ days") 
	subtitle("Intervention, control, monthly differences - continuous patients")
	ytitle("% visits missed") 
	ylabel(-.1 "-10%" 0 "0%" .1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%", labsize(medium) angle(horizontal) grid) 
	yline(0, lwidth(thin) lpattern(dash) lcolor(black)) 
	xtitle("Study month")
	xline(13.5, lwidth(thick) lpattern(solid) lcolor(black)) 
	legend(rows (1) lab(1 "intervention") lab(2 "control") lab(3 "I-C difference"))
	saving(c:\3ie\analysis\ITS_missed3_contin, replace) 
	xsize(2.97) ysize(2) scale(1.0);
#d cr

* missed visits by 7 days
#d ;
twoway 
	(connected miss_7 sched_mon if group_no==1, msymbol(none)) 
	|| connected miss_7 sched_mon if group_no==0, msymbol(none) lcolor(blue)
	|| connected miss_7 sched_mon if group_no==2, msymbol(none) lcolor(black) lwidth(thin)
	scheme(s1color) graphregion(fcolor(ltbluishgray8)) plotregion(fcolor(white))
	title("Monthly visits missed by 7+ days") 
	subtitle("Intervention, control, monthly differences - continuous patients")
	ytitle("% visits missed") 
	ylabel(-.1 "-10%" 0 "0%" .1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%", labsize(medium) angle(horizontal) grid) 
	yline(0, lwidth(thin) lpattern(dash) lcolor(black)) 
	xtitle("Study month")
	xline(13.5, lwidth(thick) lpattern(solid) lcolor(black)) 
	legend(rows (1) lab(1 "intervention") lab(2 "control") lab(3 "I-C difference"))
	saving(c:\3ie\analysis\ITS_missed7_contin, replace) 
	xsize(2.97) ysize(2) scale(1.0);
#d cr

* missed visits by 15 days
#d ;
twoway 
	(connected miss_15 sched_mon if group_no==1, msymbol(none)) 
	|| connected miss_15 sched_mon if group_no==0, msymbol(none) lcolor(blue)
	|| connected miss_15 sched_mon if group_no==2, msymbol(none) lcolor(black) lwidth(thin)
	scheme(s1color) graphregion(fcolor(ltbluishgray8)) plotregion(fcolor(white))
	title("Monthly visits missed by 15+ days") 
	subtitle("Intervention, control, monthly differences - continuous patients")
	ytitle("% visits missed") 
	ylabel(-.1 "-10%" 0 "0%" .1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%", labsize(medium) angle(horizontal) grid) 
	yline(0, lwidth(thin) lpattern(dash) lcolor(black)) 
	xtitle("Study month")
	xline(13.5, lwidth(thick) lpattern(solid) lcolor(black)) 
	legend(rows (1) lab(1 "intervention") lab(2 "control") lab(3 "I-C difference"))
	saving(c:\3ie\analysis\ITS_missed15_contin, replace) 
	xsize(2.97) ysize(2) scale(1.0);
#d cr
  
* missed visits by 60 days
#d ;
twoway 
	(connected miss_60 sched_mon if group_no==1, msymbol(none)) 
	|| connected miss_60 sched_mon if group_no==0, msymbol(none) lcolor(blue)
	|| connected miss_60 sched_mon if group_no==2, msymbol(none) lcolor(black) lwidth(thin)
	scheme(s1color) graphregion(fcolor(ltbluishgray8)) plotregion(fcolor(white))
	title("Monthly visits missed by 60+ days") 
	subtitle("Intervention, control, monthly differences - continuous patients")
	ytitle("% visits missed") 
	ylabel(-.1 "-10%" 0 "0%" .1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%", labsize(medium) angle(horizontal) grid) 
	yline(0, lwidth(thin) lpattern(dash) lcolor(black)) 
	xtitle("Study month")
	xline(13.5, lwidth(thick) lpattern(solid) lcolor(black)) 
	legend(rows (1) lab(1 "intervention") lab(2 "control") lab(3 "I-C difference"))
	saving(c:\3ie\analysis\ITS_missed60_contin, replace) 
	xsize(2.97) ysize(2) scale(1.0);
#d cr

* average PDC
#d ;
twoway 
	(connected avgPDC sched_mon if group_no==1, msymbol(none)) 
	|| connected avgPDC sched_mon if group_no==0, msymbol(none) lcolor(blue)
	|| connected avgPDC sched_mon if group_no==2, msymbol(none) lcolor(black) lwidth(thin)
	scheme(s1color) graphregion(fcolor(ltbluishgray8)) plotregion(fcolor(white))
	title("Average proportion of days covered (PDC)") 
	subtitle("Intervention, control, monthly differences - continuous patients")
	ytitle("Average PDC") 
	ylabel(-.20 "-20%" 0 "0%" .20 "20%" .40 "40%" .60 "60%" .80 "80%" 1.00 "100%", labsize(medium) angle(horizontal) grid) 
	yline(0, lwidth(thin) lpattern(dash) lcolor(black)) 
	xtitle("Study month")
	xline(13.5, lwidth(thick) lpattern(solid) lcolor(black)) 
	legend(rows (1) lab(1 "intervention") lab(2 "control") lab(3 "I-C difference"))
	saving(c:\3ie\analysis\ITS_avgPDC_contin, replace) 
	xsize(2.97) ysize(2) scale(1.0);
#d cr

* Percent PDC 80% or more
#d ;
twoway 
	(connected PDC80 sched_mon if group_no==1, msymbol(none)) 
	|| connected PDC80 sched_mon if group_no==0, msymbol(none) lcolor(blue)
	|| connected PDC80 sched_mon if group_no==2, msymbol(none) lcolor(black) lwidth(thin)
	scheme(s1color) graphregion(fcolor(ltbluishgray8)) plotregion(fcolor(white))
	title("Percent of patients with PDC 80% or more") 
	subtitle("Intervention, control, monthly differences - continuous patients")
	ytitle("% PDC >= 80%") 
	ylabel(-.20 "-20%" 0 "0%" .20 "20%" .40 "40%" .60 "60%" .80 "80%" 1.00 "100%", labsize(medium) angle(horizontal) grid) 
	yline(0, lwidth(thin) lpattern(dash) lcolor(black)) 
	xtitle("Study month")
	xline(13.5, lwidth(thick) lpattern(solid) lcolor(black)) 
	legend(rows (1) lab(1 "intervention") lab(2 "control") lab(3 "I-C difference"))
	saving(c:\3ie\analysis\ITS_PDC80_contin, replace) 
	xsize(2.97) ysize(2) scale(1.0);
#d cr

* Percent PDC 95% or more
#d ;
twoway 
	(connected PDC95 sched_mon if group_no==1, msymbol(none)) 
	|| connected PDC95 sched_mon if group_no==0, msymbol(none) lcolor(blue)
	|| connected PDC95 sched_mon if group_no==2, msymbol(none) lcolor(black) lwidth(thin)
	scheme(s1color) graphregion(fcolor(ltbluishgray8)) plotregion(fcolor(white))
	title("Percent of patients with PDC 95% or more") 
	subtitle("Intervention, control, monthly differences - continuous patients")
	ytitle("% PDC >= 95%") 
	ylabel(-.20 "-20%" 0 "0%" .20 "20%" .40 "40%" .60 "60%" .80 "80%" 1.00 "100%", labsize(medium) angle(horizontal) grid) 
	yline(0, lwidth(thin) lpattern(dash) lcolor(black)) 
	xtitle("Study month")
	xline(13.5, lwidth(thick) lpattern(solid) lcolor(black)) 
	legend(rows (1) lab(1 "intervention") lab(2 "control") lab(3 "I-C difference"))
	saving(c:\3ie\analysis\ITS_PDC95_contin, replace) 
	xsize(2.97) ysize(2) scale(1.0);
#d cr


*****************************************************************************
* ITS MODEL USING NEWEY ESTIMATION - CONTINUOUS PATIENTS
*****************************************************************************
use "existing pts\3ie_ITS_analysis_contin.dta", clear

* restrict sample
drop if sched_mon>20

* select model with month 14 missing from pre (its2_post) or included in pre (its_post)
gen level = post_its
* to run model with Aug 2014 not included in pre
* gen level = post_its2
gen trend = (sched_mon-14)*level 
tsset group_no sched_mon

* MODEL INTERVENTION EFFECTS
* interv missed visits
newey miss_1 sched_mon level trend if group_no==1 , lag(12)
predict beta
estimates store I1_full_contin
* outsheet using "Analysis\Interv miss_1 newey contin.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* interv 3-day missed visits
newey miss_3 sched_mon level trend if group_no==1 , lag(12)
predict beta
estimates store I3_full_contin
* outsheet using "Analysis\Interv miss_3 newey contin.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* interv 7-day missed visits
newey miss_7 sched_mon level trend if group_no==1 , lag(12)
predict beta
estimates store I7_full_contin
* outsheet using "Analysis\Interv miss_7 newey contin.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* interv 15-day missed visits
newey miss_15 sched_mon level trend if group_no==1 & sched_mon<21, lag(12)
predict beta
estimates store I15_full_contin
* outsheet using "Analysis\Interv miss_15 newey contin.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* interv 60-day missed visits
newey miss_60 sched_mon level trend if group_no==1 & sched_mon<20, lag(12)
predict beta
estimates store I60_full_contin
* outsheet using "Analysis\Interv miss_60 newey contin.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* PDC models exclude first month which is high by definition

* interv avgPDC
newey avgPDC sched_mon level trend if group_no==1 & sched_mon>1 , lag(12)
predict beta
estimates store IavgPDC_full_contin
* outsheet using "Analysis\Interv avgPDC newey contin.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* interv PDC80
newey PDC80 sched_mon level trend if group_no==1  & sched_mon>1 , lag(12)
predict beta
estimates store IPDC80_full_contin
* outsheet using "Analysis\Interv PDC80 newey contin.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* interv PDC95
newey PDC95 sched_mon level trend if group_no==1  & sched_mon>1 , lag(12)
predict beta
estimates store IPDC95_full_contin
* outsheet using "Analysis\Interv PDC95 newey contin.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* MODEL DIFFERENCES
* diff in missed visits
newey miss_1 sched_mon level trend if group_no==2 , lag(12)
predict beta
estimates store D1_full_contin
* outsheet using "Analysis\Diff miss_1 newey contin.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* diff in 3-day missed visits
newey miss_3 sched_mon level trend if group_no==2 , lag(12)
predict beta
estimates store D3_full_contin
* outsheet using "Analysis\Diff miss_3 newey contin.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* diff in 7-day missed visits
newey miss_7 sched_mon level trend if group_no==2 , lag(12)
predict beta
estimates store D7_full_contin
* outsheet using "Analysis\Diff miss_7 newey contin.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* diff 15-day missed visits
newey miss_15 sched_mon level trend if group_no==2 & sched_mon<21, lag(12)
predict beta
estimates store D15_full_contin
* outsheet using "Analysis\Diff miss_15 newey contin.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* diff 60-day missed visits
newey miss_60 sched_mon level trend if group_no==2 & sched_mon<20, lag(12)
predict beta
estimates store D60_full_contin
* outsheet using "Analysis\Diff miss_60 newey contin.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* PDC models exclude first month which is high by definition

* diff avgPDC
newey avgPDC sched_mon level trend if group_no==2  & sched_mon>1 , lag(12)
predict beta
estimates store DavgPDC_full_contin
* outsheet using "Analysis\Diff avgPDC newey contin.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* diff PDC80
newey PDC80 sched_mon level trend if group_no==2  & sched_mon>1 , lag(12)
predict beta
estimates store DPDC80_full_contin
* outsheet using "Analysis\Diff PDC80 newey contin.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]

* diff PDC95
newey PDC95 sched_mon level trend if group_no==2  & sched_mon>1 , lag(12)
predict beta
estimates store DPDC95_full_contin
* outsheet using "Analysis\Diff PDC95 newey contin.csv", replace comma
cap drop beta
*absolute change at 6 months after intervention
lincom _b[level]+6*_b[trend]


***********************************************************************************************************
* TABLE ALL ESTIMATES FROM CONTINUOUS ITS MODELS
***********************************************************************************************************
esttab I1_full_contin I3_full_contin I7_full_contin I15_full_contin I60_full_contin ///
		IavgPDC_full_contin IPDC80_full_contin IPDC95_full_contin /// 
	using c:\3ie\analysis\ITS_contin_full_model_interven.rtf, stats(N) b(%8.3f) ci(%8.2f) nogaps ///
	title("ITS effects full models intervention group - with 2016 visit") replace

esttab D1_full_contin D3_full_contin D7_full_contin D15_full_contin D60_full_contin ///
		DavgPDC_full_contin DPDC80_full_contin DPDC95_full_contin ///
	using c:\3ie\analysis\ITS_contin_full_model_diffs.rtf, stats(N) b(%8.3f) ci(%8.2f) nogaps ///
	title("ITS effects full models differences - with 2016 visit") replace

log close

erase temp_ITS_monthly_missed_visits_all.dta
erase temp_ITS_monthly_PDC_all.dta
erase temp_ITS_byfacility.dta
erase temp_ITS_bygroup.dta
erase temp_ITS_diff.dta
erase temp_ITS_monthly_missed_visits_contin.dta
erase temp_ITS_monthly_PDC_contin.dta
erase temp_PDC_byfacility.dta
erase temp_PDC_bygroup.dta
erase temp_PDC_diff.dta
