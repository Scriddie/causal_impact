cd "c:\3ie\data\"

	
***********************************************************************************************
***********************************************************************************************
* SECTION 1: PREDICTORS OF BASELINE ADHERENCE
***********************************************************************************************
***********************************************************************************************
log using "c:\3ie\analysis\GEE_baseline_existing.log", replace
	
use "existing pts\3ie_exist_vis.dta", clear
duplicates drop base_id c_nextvisitdate , force
* drops 101 visits with duplicate scheduled date

* restrict to baseline measures
keep if post_its2==0

iis base_id
tis c_nextvisitdate

* models one at at time
xi: xtgee miss i.interv, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
	estimates store miss_all_bl_group

xi: xtgee miss i.who_stage, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
	estimates store miss_all_bl_stage

xi: xtgee miss i.post_delivery, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
	estimates store miss_all_bl_postdel

xi: xtgee miss i.age_cat, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
	estimates store miss_all_bl_agecat

xi: xtgee miss i.marstat, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
	estimates store miss_all_bl_marstat
	
xi: xtgee miss i.art_year, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
	estimates store miss_all_bl_artyear

xi: xtgee miss i.fac_id, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
	estimates store miss_all_bl_facid
	
* fully specified model with facility indicators
xi: xtgee miss i.interv i.who_stage i.post_delivery ///
	i.age_cat i.marstat i.art_year i.fac_id, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
	estimates store miss_all_bl_all

esttab miss_all_bl_group miss_all_bl_stage miss_all_bl_postdel miss_all_bl_agecat ///
	miss_all_bl_marstat miss_all_bl_artyear miss_all_bl_facid  miss_all_bl_all ///
	using c:\3ie\analysis\GEE_all_BL_predictors.rtf, ///
	stats(N) b(%8.2f) ci(%8.2f) eform nogaps ///
	title("GEE BL predictors of missed visits - all existing patients") replace
		
log close


***********************************************************************************************
***********************************************************************************************
* SECTION 2: MONTHLY RATES OF POSSIBLE CONFOUNDERS OVER TIME
***********************************************************************************************
***********************************************************************************************
log using "c:\3ie\analysis\ITS_confounder_TS_existing.log", replace
	
use "existing pts\3ie_exist_vis.dta", clear
duplicates drop base_id c_nextvisitdate , force
* drops 101 visits with duplicate scheduled date

*create binary predictors
* age > 30
gen age_gt30=.
replace age_gt30 =0 if age_cat==2 | age_cat==3
replace age_gt30 =1 if age_cat==4 | age_cat==5
label var age_gt30 "Age >30 years (0/1)"

* married
gen married=.
replace married=0 if marstat==1 | marstat==3
replace married=1 if marstat==2
label var married "Married (0/1)"

* WHO stage > 1
gen who_gt1=.
replace who_gt1=1 if who_stage==2 | who_stage==3 | who_stage==4
replace who_gt1=0 if who_stage==1
label var who_gt1 "WHO stage >1 (0/1)"

* create time series variables by group
sort group visit_mon
by group visit_mon: egen pct_age_gt30 = mean(age_gt30)
by group visit_mon: egen pct_married = mean(married)
by group visit_mon: egen pct_who_gt1 = mean(who_gt1)
by group visit_mon: egen pct_post_deliv = mean(post_delivery)

by group visit_mon: keep if _n==1

drop if visit_mon<1 | visit_mon>20
 
#d ;
twoway 
	(connected pct_age_gt30 visit_mon if group=="Control", msymbol(none)) 
	|| connected pct_age_gt30 visit_mon if group=="Intervention", msymbol(none) lcolor(blue)
	lwidth(thin)
	scheme(s1color) graphregion(fcolor(ltbluishgray8)) plotregion(fcolor(white))
	title("Percent over age 30") 
	subtitle("Intervention, control - all patients with visits in month")
	ytitle("% age>30") 
	ylabel(0 "0%" .1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%" .6 "60%" .7 "70%" .8 "80%" .9 "90%" 1.0 "100%", 
	labsize(medium) angle(horizontal) grid) 
	xtitle("Study month")
	xline(13.5, lwidth(thick) lpattern(solid) lcolor(black)) 
	legend(rows (1) lab(1 "intervention") lab(2 "control") )
	saving(c:\3ie\Analysis\ITS_age_gt30, replace)
	xsize(2.97) ysize(2) scale(1.0);
#d cr

#d ;
twoway 
	(connected pct_married visit_mon if group=="Control", msymbol(none)) 
	|| connected pct_married visit_mon if group=="Intervention", msymbol(none) lcolor(blue)
	lwidth(thin)
	scheme(s1color) graphregion(fcolor(ltbluishgray8)) plotregion(fcolor(white))
	title("Percent married") 
	subtitle("Intervention, control - all patients with visits in month")
	ytitle("% married") 
	ylabel(0 "0%" .1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%" .6 "60%" .7 "70%" .8 "80%" .9 "90%" 1.0 "100%", 
	labsize(medium) angle(horizontal) grid) 
	xtitle("Study month")
	xline(13.5, lwidth(thick) lpattern(solid) lcolor(black)) 
	legend(rows (1) lab(1 "intervention") lab(2 "control") )
	saving(c:\3ie\Analysis\ITS_married, replace)
	xsize(2.97) ysize(2) scale(1.0);
#d cr

#d ;
twoway 
	(connected pct_who_gt1 visit_mon if group=="Control", msymbol(none)) 
	|| connected pct_who_gt1 visit_mon if group=="Intervention", msymbol(none) lcolor(blue)
	lwidth(thin)
	scheme(s1color) graphregion(fcolor(ltbluishgray8)) plotregion(fcolor(white))
	title("Percent initial WHO status>1") 
	subtitle("Intervention, control - all patients with visits in month")
	ytitle("% WHO status>1") 
	ylabel(0 "0%" .1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%" .6 "60%" .7 "70%" .8 "80%" .9 "90%" 1.0 "100%", 
	labsize(medium) angle(horizontal) grid) 
	xtitle("Study month")
	xline(13.5, lwidth(thick) lpattern(solid) lcolor(black)) 
	legend(rows (1) lab(1 "intervention") lab(2 "control") )
	saving(c:\3ie\Analysis\ITS_who_gt1, replace)
	xsize(2.97) ysize(2) scale(1.0);
#d cr

#d ;
twoway 
	(connected pct_post_deliv visit_mon if group=="Control", msymbol(none)) 
	|| connected pct_post_deliv visit_mon if group=="Intervention", msymbol(none) lcolor(blue)
	lwidth(thin)
	scheme(s1color) graphregion(fcolor(ltbluishgray8)) plotregion(fcolor(white))
	title("Percent post-delivery") 
	subtitle("Intervention, control - all patients with visits in month")
	ytitle("% post-delivery") 
	ylabel(0 "0%" .1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%" .6 "60%" .7 "70%" .8 "80%" .9 "90%" 1.0 "100%", 
	labsize(medium) angle(horizontal) grid) 
	xtitle("Study month")
	xline(13.5, lwidth(thick) lpattern(solid) lcolor(black)) 
	legend(rows (1) lab(1 "intervention") lab(2 "control") )
	saving(c:\3ie\Analysis\ITS_post_deliv, replace)
	xsize(2.97) ysize(2) scale(1.0);
#d cr

log close

***********************************************************************************************
***********************************************************************************************
* SECTION 3: GEE DIFFERENCE IN DIFFERENCE MODELS TESTING CHANGES IN MISSED VISITS BY GROUP
***********************************************************************************************
***********************************************************************************************
log using "c:\3ie\analysis\GEE_analysis_existing_all.log", replace

use "existing pts\3ie_exist_vis.dta", clear

duplicates drop base_id c_nextvisitdate , force
* drops 112 visits with duplicate scheduled date
iis base_id
tis c_nextvisitdate
* xtdes

* building up the model for prepost changes in missed visits by group
xi: xtgee miss i.post_its2 i.interv i.post_its2*i.interv, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted 
estimates store miss_all_model1
xi: xtgee miss i.post_its2 i.interv i.post_its2*i.interv i.who_stage, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted 
estimates store miss_all_model2
xi: xtgee miss i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted 
estimates store miss_all_model3
xi: xtgee miss i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.age_cat, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted 
estimates store miss_all_model4
xi: xtgee miss i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.age_cat i.art_year, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted 
estimates store miss_all_model5

* all visit models fully specified with facility indicators
xi: xtgee miss i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.age_cat i.art_year i.fac_id, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store miss_all_model6
xi: xtgee miss3 i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.age_cat i.art_year i.fac_id, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store miss3_all_model6
xi: xtgee miss7 i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.age_cat i.art_year i.fac_id, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store miss7_all_model6
xi: xtgee miss15 i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.age_cat i.art_year i.fac_id, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store miss15_all_model6
xi: xtgee miss60 i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.age_cat i.art_year i.fac_id, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store miss60_all_model6

estimates table miss_all_model1, ///
	stats(N) star(.05 .01 .001) b(%8.2f) eform varwidth(15) style(oneline) noemptycells ///
	title("Table of GEE DiD effects building models - all patients")
estimates table miss_all_model2, ///
	stats(N) star(.05 .01 .001) b(%8.2f) eform varwidth(15) style(oneline) noemptycells ///
	title("Table of GEE DiD effects building models - all patients")
estimates table miss_all_model3, ///
	stats(N) star(.05 .01 .001) b(%8.2f) eform varwidth(15) style(oneline) noemptycells ///
	title("Table of GEE DiD effects building models - all patients")
estimates table miss_all_model4, ///
	stats(N) star(.05 .01 .001) b(%8.2f) eform varwidth(15) style(oneline) noemptycells ///
	title("Table of GEE DiD effects building models - all patients")
estimates table miss_all_model5, ///
	stats(N) star(.05 .01 .001) b(%8.2f) eform varwidth(15) style(oneline) noemptycells ///
	title("Table of GEE DiD effects building models - all patients")
estimates table miss_all_model6, ///
	stats(N) star(.05 .01 .001) b(%8.2f) eform varwidth(15) style(oneline) noemptycells ///
	title("Table of GEE DiD effects full models - all patients")

esttab miss_all_model6 miss3_all_model6 miss7_all_model6 miss15_all_model6 miss60_all_model6 ///
	using c:\3ie\analysis\GEE_all_miss_model6.rtf, ///
	stats(N) b(%8.2f) ci(%8.2f) eform nogaps drop(_cons) ///
	title("GEE DiD effects full models miss - all patients") replace
	
***********************************************************************************************
* PRE-POST GEE MODELS EXAMINING SUBGROUP STRATIFICATIONS
***********************************************************************************************
xi: xtgee miss i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.age_cat i.art_year i.fac_id, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store miss_all_model6

* age groups
xi: xtgee miss i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.art_year i.fac_id i.post_its2*i.interv if age_cat>3, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store miss_all_model6_agehigh
xi: xtgee miss i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.art_year i.fac_id i.post_its2*i.interv if age_cat<4, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store miss_all_model6_agelow

* WHO stage
xi: xtgee miss i.post_its2 i.interv i.post_its2*i.interv i.post_delivery ///
	i.age_cat i.art_year i.fac_id if who_stage>2, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store miss_all_model6_whohigh
xi: xtgee miss i.post_its2 i.interv i.post_its2*i.interv i.post_delivery ///
	i.age_cat i.art_year i.fac_id if who_stage<3, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store miss_all_model6_wholow

* ART year
xi: xtgee miss i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.age_cat i.fac_id if art_year>2014, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store miss_all_model6_artnew
xi: xtgee miss i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.age_cat i.fac_id if art_year<2015, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store miss_all_model6_artold

* pre and post delivery
xi: xtgee miss i.post_its2 i.interv i.post_its2*i.interv i.who_stage ///
	i.age_cat i.art_year i.fac_id if post_delivery==1, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store miss_all_model6_postdel
xi: xtgee miss i.post_its2 i.interv i.post_its2*i.interv i.who_stage ///
	i.age_cat i.art_year i.fac_id if post_delivery==0, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store miss_all_model6_predel


***********************************************************************************************
* PRE-POST GEE MODELS TESTING CHANGES IN MISSED VISITS BY INTERVENTION FACILITY
***********************************************************************************************
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 1", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac1_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 2", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac2_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 3", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac3_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 4", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac4_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 5", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac5_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 6", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac6_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 7", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac7_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 8", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac8_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 9", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac9_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 10", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac10_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 11", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac11_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 12", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac12_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 13", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac13_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 14", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac14_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 15", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac15_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 16", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac16_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 17", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac17_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 18", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac18_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 19", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac19_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 20", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac20_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 21", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac21_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 22", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac22_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 23", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac23_model5
xi: xtgee miss i.post_its2 i.who_stage i.post_delivery ///
	i.age_cat i.art_year if fac_label=="Facil 24", ///
	family(binomial) link(logit) corr(exch) robust
estimates store miss_fac24_model5

esttab miss_fac1_model5 miss_fac2_model5 miss_fac3_model5 miss_fac4_model5 miss_fac5_model5 ///
	miss_fac6_model5 using c:\3ie\analysis\GEE_all_facil1.rtf, ///
	stats(N) b(%8.2f) ci(%8.2f) eform nogaps ///
	title("GEE prepost facility full miss models - all patients") replace
esttab miss_fac7_model5 miss_fac8_model5 miss_fac9_model5 miss_fac10_model5 miss_fac11_model5 /// 
	miss_fac12_model5 using c:\3ie\analysis\GEE_all_facil2.rtf, ///
	stats(N) b(%8.2f) ci(%8.2f) eform nogaps ///
	title("GEE prepost facility full miss models - all patients") replace
esttab miss_fac13_model5 miss_fac14_model5 miss_fac15_model5 miss_fac16_model5 miss_fac17_model5 ///
	miss_fac18_model5 using c:\3ie\analysis\GEE_all_facil3.rtf, ///
	stats(N) b(%8.2f) ci(%8.2f) eform nogaps ///
	title("GEE prepost facility full miss models - all patients") replace
esttab miss_fac19_model5 miss_fac20_model5 miss_fac21_model5 miss_fac22_model5 miss_fac23_model5 ///
	miss_fac24_model5 using c:\3ie\analysis\GEE_all_facil4.rtf, ///
	stats(N) b(%8.2f) ci(%8.2f) eform nogaps ///
	title("GEE prepost facility full miss models - all patients") replace


***********************************************************************************************
* GEE DiD MODELS TESTING CHANGES IN COVERAGE (PDC) BY GROUP 
***********************************************************************************************
use "existing pts\3ie_exist_PDC.dta", clear
* sort fac_id
* by fac_id: prtest miss , by(post_its2)
iis end_id
tis sched_mon
* xtdes

* replace average PDC with a proportional value to model as a rate
replace PDC = PDC/100

* prepost change in avgPDC, PDCge80 and PDCge95 by group fully specified
xi: xtgee PDC i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.age_cat i.art_year i.fac_id, ///
	family(gaussian) robust noomitted
estimates store PDC_all_model6
xi: xtgee PDCge80 i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.age_cat i.art_year i.fac_id, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store PDCge80_all_model6
xi: xtgee PDCge95 i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.age_cat i.art_year i.fac_id, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store PDCge95_all_model6

esttab PDC_all_model6 ///
	using c:\3ie\analysis\GEE_all_PDC_model6_avgPDC.rtf, ///
	stats(N) b(%8.2f) ci(%8.2f) nogaps ///
	title("GEE DiD effects full PDC models - 2016 patients") replace
esttab PDCge80_all_model6 PDCge95_all_model6 ///
	using c:\3ie\analysis\GEE_all_PDC_model6_pctPDC.rtf, ///
	stats(N) b(%8.2f) ci(%8.2f) eform nogaps  ///
	title("GEE DiD effects full PDC models - 2016 patients") replace

log close
	
	
***********************************************************************************************
***********************************************************************************************
* SECTION 2: GEE DIFFERENCE IN DIFFERENCE MODELS TESTING CHANGES IN MISSED VISITS BY GROUP
* AMONG CONTINUOUS PATIENTS STILL PRESENT IN 2016
***********************************************************************************************
***********************************************************************************************
log using "c:\3ie\analysis\GEE_analysis_existing_contin.log", replace
	
use "existing pts\3ie_exist_vis.dta", clear
duplicates drop base_id c_nextvisitdate , force
* drops 112 visits with duplicate scheduled date

* restrict to continuous patients
keep if continuous==1

iis base_id
tis c_nextvisitdate

* all visit models fully specified - CONTINUOUS PATIENTS
xi: xtgee miss i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.age_cat i.art_year i.fac_id, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store miss_contin_model6
xi: xtgee miss3 i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.age_cat i.art_year i.fac_id, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store miss3_contin_model6
xi: xtgee miss7 i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.age_cat i.art_year i.fac_id, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store miss7_contin_model6
xi: xtgee miss15 i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.age_cat i.art_year i.fac_id, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store miss15_contin_model6
xi: xtgee miss60 i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.age_cat i.art_year i.fac_id, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store miss60_contin_model6

esttab miss_contin_model6 miss3_contin_model6 miss7_contin_model6 miss15_contin_model6 miss60_contin_model6 ///
	using c:\3ie\analysis\GEE_contin_miss_model6.rtf, ///
	stats(N) b(%8.2f) ci(%8.2f) eform nogaps drop(_cons) ///
	title("GEE DiD effects full models miss - 2016 patients") replace

***********************************************************************************************
* GEE DiD MODELS TESTING CHANGES IN PDC BY GROUP AMONG CONTINUOUS PATIENTS
***********************************************************************************************
use "existing pts\3ie_exist_PDC.dta", clear

keep if continuous==1

* sort fac_id
* by fac_id: prtest miss , by(post_its2)
iis end_id
tis sched_mon
* xtdes

* replace average PDC with a proportional value to model as a rate
replace PDC = PDC/100

* prepost change in avgPDC, PDCge80 and PDCge95 by group fully specified
xi: xtgee PDC i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.age_cat i.art_year i.fac_id, ///
	family(gaussian) robust noomitted
estimates store PDC_contin_model6
xi: xtgee PDCge80 i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.age_cat i.art_year i.fac_id, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store PDCge80_contin_model6
xi: xtgee PDCge95 i.post_its2 i.interv i.post_its2*i.interv i.who_stage i.post_delivery ///
	i.age_cat i.art_year i.fac_id, ///
	family(binomial) link(logit) corr(exch) robust eform noomitted
estimates store PDCge95_contin_model6

esttab PDC_contin_model6 ///
	using c:\3ie\analysis\GEE_contin_PDC_model6_avgPDC.rtf, ///
	stats(N) b(%8.2f) ci(%8.2f) nogaps ///
	title("GEE DiD effects full PDC models - 2016 patients") replace
esttab PDCge80_contin_model6 PDCge95_contin_model6 ///
	using c:\3ie\analysis\GEE_contin_PDC_model6_pctPDC.rtf, ///
	stats(N) b(%8.2f) ci(%8.2f) eform nogaps  ///
	title("GEE DiD effects full PDC models - 2016 patients") replace

log close
	
