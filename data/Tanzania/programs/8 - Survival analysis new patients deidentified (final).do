set more off
cd "c:\3ie\"
* log close
log using "c:\3ie\analysis\Survival_new_pts.log", replace

*********************************************************************************
* conduct survival analyses
*********************************************************************************
use "data\new pts\3ie_new_vis.dta", clear

* 1-day miss
stset censor1_180 , failure(miss1_180)
stsum, by(pre_post group)
sts list, by(pre_post group) compare
sts test group if pre_post==0
sts test group if pre_post==1
#d ;
sts graph if pre_post==0, title("Time until missed visits among newly treated patients")
		subtitle ("Pre-intervention period") 	xtitle("Days of follow-up")  ytitle("Proportion without missed visit")
		ylabel (1 "100%" .75 "75%" .5 "50%" .25 "25%" 0 "0%",angle(horizontal)) by(group)
		xlabel (0 30 60 90 120 150 180) xsize(2.97) ysize(2) scale(1.0) 
		saving(c:\3ie\analysis\new_pre_bygroup_1day, replace);
#d cr		
#d ;
sts graph if pre_post==1, title("Time until missed visits among newly treated patients")
		subtitle ("Post-intervention period") 	xtitle("Days of follow-up")  ytitle("Proportion without missed visit")
		ylabel (1 "100%" .75 "75%" .5 "50%" .25 "25%" 0 "0%",angle(horizontal)) by(group)
		xlabel (0 30 60 90 120 150 180) xsize(2.97) ysize(2) scale(1.0) 
		saving(c:\3ie\analysis\new_post_bygroup_1day, replace);
#d cr		
stcox interv i.age_cat i.who_stage i.post_delivery if pre_post==0, hr
estimates store cox_miss_pre
stcox interv i.age_cat i.who_stage i.post_delivery if pre_post==1, hr
estimates store cox_miss_post

* test PH assumption
/*
sts gen cumhg = na, by(pre_post group)
gen lch = log(cumhg)
separate lch if pre_post==0, by(group)
twoway connect lch1 lch2 _t, ytitle("log(cumulative hazard)") ///
	title("Proportional hazard check surival pre") ///
	xtitle("survival time") xtick(1(1)39) sort saving(PHtest3, replace)
drop lch1 lch2
separate lch if pre_post==1, by(group)
twoway connect lch1 lch2 _t, ytitle("log(cumulative hazard)") ///
	title("Proportional hazard check surival pre_post") ///
	xtitle("survival time") xtick(1(1)39) sort saving(PHtest3, replace)
drop cumhg lch lch1 lch2
*/
	
* 3-day miss
stset censor3_180 , failure(miss3_180)
stsum, by(pre_post group)
sts list, by(pre_post group) compare
sts test group if pre_post==0
sts test group if pre_post==1
#d ;
sts graph if pre_post==0, title("Time until 3-day missed visits among newly treated patients")
		subtitle ("Pre-intervention period") 	xtitle("Days of follow-up")  ytitle("Proportion without missed visit")
		ylabel (1 "100%" .75 "75%" .5 "50%" .25 "25%" 0 "0%",angle(horizontal)) by(group)
		xlabel (0 30 60 90 120 150 180) xsize(2.97) ysize(2) scale(1.0) 
		saving(c:\3ie\analysis\new_pre_bygroup_3day, replace);
#d cr		
#d ;
sts graph if pre_post==1, title("Time until 3-day missed visits among newly treated patients")
		subtitle ("Post-intervention period") 	xtitle("Days of follow-up")  ytitle("Proportion without missed visit")
		ylabel (1 "100%" .75 "75%" .5 "50%" .25 "25%" 0 "0%",angle(horizontal)) by(group)
		xlabel (0 30 60 90 120 150 180) xsize(2.97) ysize(2) scale(1.0) 
		saving(c:\3ie\analysis\new_post_bygroup_3day, replace);
#d cr		
stcox interv i.age_cat i.who_stage i.post_delivery if pre_post==0, hr
estimates store cox_miss3_pre
stcox interv i.age_cat i.who_stage i.post_delivery if pre_post==1, hr
estimates store cox_miss3_post

* 7-day miss
stset censor7_180 , failure(miss7_180)
stsum, by(pre_post group)
sts list, by(pre_post group) compare
sts test group if pre_post==0
sts test group if pre_post==1
#d ;
sts graph if pre_post==0, title("Time until 7-day missed visits among newly treated patients")
		subtitle ("Pre-intervention period") 	xtitle("Days of follow-up")  ytitle("Proportion without missed visit")
		ylabel (1 "100%" .75 "75%" .5 "50%" .25 "25%" 0 "0%",angle(horizontal)) by(group)
		xlabel (0 30 60 90 120 150 180) xsize(2.97) ysize(2) scale(1.0) 
		saving(c:\3ie\analysis\new_pre_bygroup_7day, replace);
#d cr		
#d ;
sts graph if pre_post==1, title("Time until 7-day missed visits among newly treated patients")
		subtitle ("Post-intervention period") 	xtitle("Days of follow-up")  ytitle("Proportion without missed visit")
		ylabel (1 "100%" .75 "75%" .5 "50%" .25 "25%" 0 "0%",angle(horizontal)) by(group)
		xlabel (0 30 60 90 120 150 180) xsize(2.97) ysize(2) scale(1.0) 
		saving(c:\3ie\analysis\new_post_bygroup_7day, replace);
#d cr		
stcox interv i.age_cat i.who_stage i.post_delivery if pre_post==0, hr
estimates store cox_miss7_pre
stcox interv i.age_cat i.who_stage i.post_delivery if pre_post==1, hr
estimates store cox_miss7_post

* 15-day miss
stset censor15_180 , failure(miss15_180)
stsum, by(pre_post group)
sts list, by(pre_post group) compare
sts test group if pre_post==0
sts test group if pre_post==1
#d ;
sts graph if pre_post==0, title("Time until 15-day missed visits among newly treated patients")
		subtitle ("Pre-intervention period") 	xtitle("Days of follow-up")  ytitle("Proportion without missed visit")
		ylabel (1 "100%" .75 "75%" .5 "50%" .25 "25%" 0 "0%",angle(horizontal)) by(group)
		xlabel (0 30 60 90 120 150 180) xsize(2.97) ysize(2) scale(1.0) 
		saving(c:\3ie\analysis\new_pre_bygroup_15day, replace);
#d cr		
#d ;
sts graph if pre_post==1, title("Time until 15-day missed visits among newly treated patients")
		subtitle ("Post-intervention period") 	xtitle("Days of follow-up")  ytitle("Proportion without missed visit")
		ylabel (1 "100%" .75 "75%" .5 "50%" .25 "25%" 0 "0%",angle(horizontal)) by(group)
		xlabel (0 30 60 90 120 150 180) xsize(2.97) ysize(2) scale(1.0) 
		saving(c:\3ie\analysis\new_post_bygroup_15day, replace);
#d cr		
stcox interv i.age_cat i.who_stage i.post_delivery if pre_post==0, hr
estimates store cox_miss15_pre
stcox interv i.age_cat i.who_stage i.post_delivery if pre_post==1, hr
estimates store cox_miss15_post

* 60-day miss
stset censor60_180 , failure(miss60_180)
stsum, by(pre_post group)
sts list, by(pre_post group) compare
sts test group if pre_post==0
sts test group if pre_post==1
#d ;
sts graph if pre_post==0, title("Time until 60-day missed visits among newly treated patients")
		subtitle ("Pre-intervention period") 	xtitle("Days of follow-up")  ytitle("Proportion without missed visit")
		ylabel (1 "100%" .75 "75%" .5 "50%" .25 "25%" 0 "0%",angle(horizontal)) by(group)
		xlabel (0 30 60 90 120 150 180) xsize(2.97) ysize(2) scale(1.0) 
		saving(c:\3ie\analysis\new_pre_bygroup_60day, replace);
#d cr		
#d ;
sts graph if pre_post==1, title("Time until 60-day missed visits among newly treated patients")
		subtitle ("Post-intervention period") 	xtitle("Days of follow-up")  ytitle("Proportion without missed visit")
		ylabel (1 "100%" .75 "75%" .5 "50%" .25 "25%" 0 "0%",angle(horizontal)) by(group)
		xlabel (0 30 60 90 120 150 180) xsize(2.97) ysize(2) scale(1.0) 
		saving(c:\3ie\analysis\new_post_bygroup_60day, replace);
#d cr		
stcox interv i.age_cat i.who_stage i.post_delivery if pre_post==0, hr
estimates store cox_miss60_pre
stcox interv i.age_cat i.who_stage i.post_delivery if pre_post==1, hr
estimates store cox_miss60_post

esttab  cox_miss_pre cox_miss_post cox_miss3_pre cox_miss3_post cox_miss7_pre cox_miss7_post ///
	cox_miss15_pre cox_miss15_post cox_miss60_pre cox_miss60_post ///
	using c:\3ie\analysis\Cox_miss_models_pre_post.rtf, ///
	stats(N) b(%8.2f) ci(%8.2f) nogaps ///
	title("Cox PH models of effects on missed visits in new patients") replace

log close
