cd "c:\3ie\data"
log using "existing pts\3ie_prepare_existing_pts.log", replace

********************************************************************************************
********************************************************************************************
* SECTION 1: CREATE CONSOLIDATED PATIENT FILE (EXCEPT FOR CONTINUOUS VARIABLE ADDED LATER)
********************************************************************************************
********************************************************************************************
use "endline\all_endline_pts.dta", clear 
duplicates tag (end_id), gen (tag)
list  base_id end_id fac_id datestartart if tag==1
*12 duplicates new/exist; keep them until merging with baseline data
drop tag

****************************************
* KEEP ONLY EXIST PATIENTS WITH A BASE_ID
*****************************************
table patienttype
/*
-----------------------------
differentiates   |
existing from    |
new pts          |      Freq.
-----------------+-----------
Existing Patient |      2,940
     New Patient |        673
-----------------------------
*/
drop if patienttype=="New Patient"

drop if base_id==.
* drops 5 patients
di _N
* n=2935

duplicates tag (base_id fac_id), gen (tag)
tab tag
duplicates drop (base_id fac_id), force
drop tag
di _N
* n=2898

duplicates tag (base_id ), gen (tag)
list base_id end_id fac_id if tag>0
drop if end_id==13003677
drop tag
di _N
* n=2897

keep  base_id end_id patientdelivery end visittype
save temp_pt_exist.dta, replace
di _N
*n=2897

*********************************************************************
*MERGE PATIENTS FROM ENDLINE TO THE CLEANED BASELINE PATIENT DATA SET
*FLAG PATIENTS WITH NO ENDLINE VISIT
*********************************************************************
use temp_pt_exist.dta, clear
merge 1:1 base_id using "baseline\3ie_base_pt.dta"
order group district fac_id fac_id
gen no_endline=0
replace no_endline=1 if _merge==2
label var no_endline "Patient with no endline record (dropout, transfer, lost record)"
replace end_id=base_id if no_endline==1
tabulate no_endline
/*
 no_endline |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |      2,897       91.94       91.94
          1 |        254        8.06      100.00
------------+-----------------------------------
      Total |      3,151      100.00
*/

**********************************************************************************
* IDENTIFY FIRST AND LAST VISIT DATES FOR PATIENTS WITH NO ENDLINE VISIT BELOW
***********************************************************************************
drop _merge
drop visittype art_start datestartart
gen art_year=year(c_art_start)
label var art_year "Year of ART initiation"

* create delivery year
gen delivery_year = year(patientdelivery)
label var delivery_year "Year of delivery"
gen delivery_month = mofd(patientdelivery)
format delivery_month %tm
label var delivery_month "Month of delivery"

* recode age category with first category <20
replace age_cat=2 if age_cat==1
label define agecat 2 "<20yo" 3 "21-30yo" 4 "31-40yo" 5 ">40yo"
label values age_cat agecat
label variable age_cat "Age category"

tabulate maritalstatus
/*
    Marital |
     Status |      Freq.     Percent        Cum.
------------+-----------------------------------
         CO |         13        0.41        0.41
          D |         62        1.97        2.38
          M |      1,846       58.58       60.96
          S |        282        8.95       69.91
          W |         72        2.28       72.20
       null |        876       27.80      100.00
------------+-----------------------------------
      Total |      3,151      100.00
*/
* recode marital status
gen marstat=.
replace marstat=1 if maritalstatus=="S"
replace marstat=2 if maritalstatus=="M" | maritalstatus=="CO"
replace marstat=3 if maritalstatus=="D" | maritalstatus=="W"
replace marstat=. if maritalstatus=="null"
label define marstat 1 "single" 2 "married/cohab" 3 "divor/widow"
label values marstat marstat
label variable marstat "Marital status"
tabulate marstat, missing

* add facility labels
gen fac_label=""
replace fac_label="Facil 1" if fac_id==1
replace fac_label="Facil 2" if fac_id==2
replace fac_label="Facil 3" if fac_id==3
replace fac_label="Facil 4" if fac_id==4
replace fac_label="Facil 5" if fac_id==5
replace fac_label="Facil 6" if fac_id==6
replace fac_label="Facil 7" if fac_id==7
replace fac_label="Facil 8" if fac_id==8
replace fac_label="Facil 9" if fac_id==9
replace fac_label="Facil 10" if fac_id==10
replace fac_label="Facil 11" if fac_id==11
replace fac_label="Facil 12" if fac_id==12
replace fac_label="Facil 13" if fac_id==13
replace fac_label="Facil 14" if fac_id==14
replace fac_label="Facil 15" if fac_id==15
replace fac_label="Facil 16" if fac_id==16
replace fac_label="Facil 17" if fac_id==17
replace fac_label="Facil 18" if fac_id==18
replace fac_label="Facil 19" if fac_id==19
replace fac_label="Facil 20" if fac_id==20
replace fac_label="Facil 21" if fac_id==21
replace fac_label="Facil 22" if fac_id==22
replace fac_label="Facil 23" if fac_id==23
replace fac_label="Facil 24" if fac_id==24
label var fac_label "Facility name"

order group district fac_label fac_id base_id end_id patientdelivery c_art_start art_year maritalstatus who_stage ///
	age_cat cd4_cat no_endline
* save as temp patient file

tabulate group, missing
/*       Group |      Freq.     Percent        Cum.
-------------+-----------------------------------
     Control |      1,226       38.91       38.91
Intervention |      1,925       61.09      100.00
-------------+-----------------------------------
       Total |      3,151      100.00
*/

save "temp_3ie_exist_pts_without_continuous_variable.dta", replace


********************************************************************************************
********************************************************************************************
* SECTION 2: CLEAN VISIT DATA AND CREATE EXISTING PATIENT VISIT FILE
********************************************************************************************
********************************************************************************************
use "endline\all_endline_visits.dta", clear

gen visittype="Endline" 
rename arvadheherence arvadherence
label var arvadherence "ARV Adherence"
di _N
*28751

* drop visits from new patients
merge m:1 end_id using "new pts\3ie_new_pts.dta", keepusing( end_id )
drop if _merge==3
*n=3635
drop _merge

*incorporate base_id variable
merge m:1 end_id using "temp_3ie_exist_pts_without_continuous_variable", keepusing (base_id fac_id end)
order base_id end_id fac_id end

* drop pts who were not identified at baseline (_merge==1)
drop if _merge==1
*n=319

* drop patients who had no visit recorded at endline (_merge==2)
drop if _merge==2
*n=0

***********************************************************************************
* NOTE: PATIENTS WITH NO ENDLINE VISITS WILL STAY IN ANALYSIS
***********************************************************************************
di _N
*N=25116

keep base_id end_id visittype visitdate nextvisitdate fac_id arvdaysdispensed end

* create cleaning variables
gen c_visitdate=visitdate
format c_visitdate %td
gen c_nextvisitdate=nextvisitdate
format c_nextvisitdate %td
gen double vis=dofd( visitdate)
gen c_mo=mofd(visitdate)
gen c_yr=yofd(visitdate)
gen c_next_yr=yofd(nextvisitdate)
label var c_visitdate "Cleaned visit date"
label var c_nextvisitdate "Cleaned next visit date"
save temp_endvistoclean.dta, replace

****************************************************
* CLEAN ENDLINE VISITS FOR EXISTING PATIENTS
****************************************************
use temp_endvistoclean.dta, clear

*check no leftover duplicate endline visits
duplicates drop (end_id c_visitdate c_nextvisitdate), force
*n=0

* correct month typos
sort base_id c_visitdate
replace c_visitdate= c_visitdate[_n-1] + 30 ///
 if base_id==base_id[_n-1] & base_id==base_id[_n+1] & c_visitdate-c_visitdate[_n-1]<7 & c_visitdate[_n+1]-c_visitdate[_n-1]>59 
*n=35

replace c_nextvisitdate=c_visitdate[_n+1] if base_id==2101028323 & vis==20296 
*n=1

* correct year for visits scheduled in Jan 2016 and written as Jan2015
replace c_nextvisitdate=c_visitdate+31 if  c_mo==671 & c_next_yr==2015 
* n=167

***************************************************************************************************************
* FLAG ENDLINE VISITS BEFORE BASELINE DATE AND UNDUPLICATE LATER
***************************************************************************************************************
count if c_visitdate<20179 & c_nextvisitdate<20179 
* n=122
gen early_visit=0
replace early_visit=1 if c_visitdate<td(01Apr2015) & c_nextvisitdate<td(01Apr2015)
label var early_visit "Visit recorded at endline with date prior to baseline"

*clean logical problems in visit dates
replace c_visitdate=c_nextvisitdate-30 if arvdaysdispensed==30 & vis<19000
*n=0 
replace c_nextvisitdate=c_visitdate+30 if arvdaysdispensed==30 & c_nextvisitdate<19000 
*n=2
replace c_visitdate=c_visitdate -365 if c_visitdate>end  & c_visitdate~=. & c_next_yr==2015 
*n=110
replace c_visitdate=c_visitdate -365 if c_visitdate>end  & c_visitdate>c_nextvisitdate & c_next_yr==2015 
*n=2
replace c_nextvisitdate=c_nextvisitdate-365 if c_next_yr==2016 & c_nextvisitdate>end & c_visitdate>end
*n=20
replace c_visitdate=c_visitdate-365 if  c_next_yr==2016 & c_visitdate>end
*n=49
replace c_visitdate=td(01jun2015) if end_id==901154704 & vis==33389
*n=1
replace c_visitdate=td(26may2015) if end_id==1201662104 & vis==21330
*n=1
replace c_visitdate=td(29jan2016) if end_id==1800013704 & vis==21578
*n=1

* cannot clean if two dates are beyond datacollection
drop if c_visitdate>end & c_nextvisitdate>end 
*n=2

* assume scheduled visit 30 days after visit if visit= end and 30 pills dispensed
replace c_nextvisitdate=c_visitdate + 30 if vis==end & c_visitdate~=. & c_nextvisitdate>end & arvdaysdispensed==30 
*n=10
replace c_visitdate=c_visitdate-365 if c_nextvisitdate< c_visitdate & c_yr~=c_next_yr  
*n=64

* drop records that do not make sense and cannot logically be cleaned
* this leads to small increase in rate of missed visits
drop if c_nextvisitdate< c_visitdate 
*n=83
drop if c_visitdate==c_nextvisitdate 
*n=53

sort base_id c_visitdate c_nextvisitdate
drop if base_id~=base_id[_n-1] & base_id==base_id[_n+1]& c_visitdate[_n+1]-c_visitdate>150 
*n=69
drop if c_nextvisitdate -c_visitdate>365 & c_visitdate~=.
* n=170

*based on field observations, assume that  pills are given at each visit 
replace arvdaysdispensed=30 if (c_nextvisitdate-c_visitdate>15) & (c_nextvisitdate-c_visitdate)<45 & arvdaysdispensed==.
replace arvdaysdispensed=60 if (c_nextvisitdate-c_visitdate>44) & (c_nextvisitdate-c_visitdate)<62 & arvdaysdispensed==.
di _N
*n=24739

sort base_id c_visitdate c_nextvisitdate
count if (base_id==base_id[_n-1] & c_visitdate==c_visitdate[_n-1]) | ///
	(base_id==base_id[_n+1] & c_visitdate==c_visitdate[_n+1])
*n=307
drop if (base_id==base_id[_n-1] & c_visitdate==c_visitdate[_n-1]) 
*n=177
drop vis c_mo c_yr c_next_yr visitdate nextvisitdate
di _N
*n=24562

save temp_cleanedvisitendline.dta, replace

************************************************************
*APPEND VISITS FROM ENDLINE TO THE CLEANED BASELINE DATA SET
************************************************************
use "baseline\3ie_base_visit.dta", clear
gen visittype="Baseline"
keep fac_id visitdate nextvisitdate ///
arvdaysdispensed base_id visittype c_visitdate c_nextvisitdate
di _N
*n=26,644

* merge with temp patient file
merge m:1 base_id using "temp_3ie_exist_pts_without_continuous_variable.dta", keepusing(end_id  )
*all merge correctly
drop _merge
append using temp_cleanedvisitendline.dta
gen patienttype="Existing patient" 
replace early_visit=0 if early_visit==. 
table early_visit
* n=117 early visits that might be duplicates

* drop record with only 1 visit in 2013
drop if end_id==100797722
count
* 51,205

duplicates drop ( c_visitdate c_nextvisitdate base_id end_id ), force
* drops 540 visits
count if early_visit==1
* n=64

 *drop duplicates and near duplicate visits (i.e., window<7d )
sort base_id c_visitdate
drop if base_id==base_id[_n-1] & c_visitdate-c_visitdate[_n-1]<7 
* n=419
di _N
*N=50,246

sort end_id c_visitdate visitdate
tab  arvdaysdispensed, m 
*no missing arvdaysdispensed

 * check no leftover duplicate visits
duplicates drop (base_id c_visitdate ) , force
label var visittype "Visit recorded at baseline/endline survey"
label var patienttype "Existing/newly treated patient"
tab patienttype visittype, m
/*
                 |   Visit recorded at
                 |   baseline/endline
  Existing/newly |        survey
 treated patient |  Baseline    Endline |     Total
-----------------+----------------------+----------
Existing patient |    26,577     23,669 |    50,246 
-----------------+----------------------+----------
           Total |    26,577     23,669 |    50,246 
*/

* drop visits recorded before defined beginning of study (July 1, 2014)
drop if c_visitdate < td(01Jul2014)
*n=2332 dropped


**************************
*CREATE VISIT VARIABLES
**************************
*assign sequence number to visits
sort base_id c_visitdate
by base_id:gen vis_id = _n
label var vis_id "Sequence number of visit"
by base_id: egen num_vis=max(vis_id)
label var num_vis "Total number of visits"

sort base_id vis_id 
by base_id: egen first_date=min(c_visitdate)
by base_id: egen last_date=max(c_visitdate)
label var first_date "Date of first visit"
label var last_date "Date of last visit"
format first_date last_date %td

gen  first_vis=0
by base_id: replace first_vis=1 if _n==1
gen  last_vis=0
replace last_vis=1 if vis_id==num_vis
label var first_vis "Flag for first visit"
label var last_vis "Flag for last visit"

gen visit_mon= mofd(c_visitdate)-mofd(td(01Jul2014))
gen sched_mon= mofd(c_nextvisitdate)-mofd(td(01Jul2014))
label var visit_mon "Study month of visit"
label var sched_mon "Study month of next scheduled visit"

sort end_id c_visitdate
gen next_actual = c_visitdate[_n+1] if end_id==end_id[_n+1]
format next_actual %td
gen days_to_next = next_actual-c_visitdate
label var next_actual "Next actual visit date"
label var days_to_next "Number of days to next actual visit"
gen days_to_sched= c_nextvisitdate-c_visitdate
label var days_to_sched "Number of days to scheduled visit"

sort end_id c_visitdate
gen days_to_end=td(31Mar2016)-last_date
label var days_to_end "Number of days from last visit to end of study"

* merge with temp patient file instead of final file
merge m:1 base_id using "temp_3ie_exist_pts_without_continuous_variable.dta"
* 9 not matched
keep if _merge==3
drop _merge
sort end_id c_visitdate
count
*n=47,906

*************************************************************************************************************
*VISIT CALCULATIONS FOR TS ANALSYSES 
*MISSED VISIT ON LAST VISIT IF NEXT SCHEDULED VISIT > # OF DAYS BEFORE MAR 31, 2016
*************************************************************************************************************
gen miss=0 if days_to_next~=.
replace miss=1 if days_to_next>days_to_sched & days_to_next~=.
replace miss=1 if last_vis==1 & days_to_end>0

gen miss3=0 if days_to_next~=.
replace miss3=1 if days_to_next-days_to_sched >2 & days_to_next~=.
replace miss3=1 if last_vis==1 & days_to_end >2

gen miss7=0 if days_to_next~=.
replace miss7=1 if days_to_next-days_to_sched >6 & days_to_next~=.
replace miss7=1 if last_vis==1 & days_to_end >6

gen miss15=0 if days_to_next~=.
replace miss15=1 if days_to_next-days_to_sched >14 & days_to_next~=.
replace miss15=1 if last_vis==1 & days_to_end >14

gen miss60=0 if days_to_next~=.
replace miss60=1 if days_to_next-days_to_sched >59 & days_to_next~=. 
replace miss60=1 if last_vis==1 & days_to_end >59

label var miss "delay between cleaned scheduled and next visits"
label var miss3 "delay of 3+d between cleaned scheduled and next visits"
label var miss7 "delay of 7+ between cleaned scheduled and next visits"
label var miss15 "delay of 15+d between cleaned scheduled and next visitss"
label var miss60 "delay of 60+d between cleaned scheduled and next visits"

* determine number of visits pre and post and if patient has a visit in both periods
gen pre_post=0
replace pre_post=1 if c_visitdate > td(23jul2015)
by end_id: egen pre_first_date = min(c_visitdate) if pre_post==0
by end_id: egen post_first_date = min(c_visitdate) if pre_post==1
format pre_first_date post_first_date %td
gen first_pre=0
replace first_pre=1 if pre_first_date == c_visitdate
gen first_post=0
replace first_post=1 if post_first_date == c_visitdate
label var first_pre "Flag for first pre visit"
label var first_post "Flag for first post visit"
by end_id: egen num_pre = sum(1) if pre_first_date !=.
by end_id: egen num_post = sum(1) if post_first_date !=.
replace num_pre = 0 if num_pre==.
replace num_post = 0 if num_post==.
label var num_pre "Total number of visits pre"
label var num_post "Total number of visits post"
drop pre_first_date post_first_date
gen qual_pre_post = first_pre + first_post
label var qual_pre_post "Flag for first visit pre and post"

*define continuous pts as those having a visit after January 15th, 2016 (20468) 
gen temp=0
replace temp=1 if c_visitdate > td(31Dec2015)
by end_id: egen continuous= max (temp)
drop temp
label var continuous "Flags pts with visit after 31Dec2015"

* flag visits after March 31 2016
gen  vis_apr_2016=0
replace vis_apr_2016=1 if c_visitdate>td(31Mar2016) & c_visitdate~=.
label var vis_apr_2016 "Flags visits after March 31, 2016"
sort end_id c_visitdate 

replace end=td(31Mar2016) if end==.
rename end endline_date

* create interv, prepost variable, and last dates
gen interv=0
replace interv=1 if group=="Intervention"
label define interv 0 "Control" 1 "Interv"
label values interv interv
label var interv "Intervention/control (0/1)"

* create post_its delivery variable
gen post_delivery = .
replace post_delivery=1 if c_visitdate >= patientdelivery & patientdelivery !=.
replace post_delivery=0 if c_visitdate < patientdelivery  & patientdelivery !=.
label var post_delivery "Visit is before/after delivery"
tabulate post_delivery, missing
/*
   Visit is |
before/afte |
 r delivery |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |     10,943       22.84       22.84
          1 |     31,606       65.98       88.82
          . |      5,357       11.18      100.00
------------+-----------------------------------
      Total |     47,906      100.00
*/


tabulate group interv, missing
/*
             | Intervention/control
             |         (0/1)
       Group |   Control     Interv |     Total
-------------+----------------------+----------
     Control |    19,115          0 |    19,115 
Intervention |         0     28,791 |    28,791 
-------------+----------------------+----------
       Total |    19,115     28,791 |    47,906 
*/

* add annual dates and periods for time series
gen sched_yr=year(c_nextvisitdate)
gen sched_mo=month(c_nextvisitdate)
label var sched_yr "Calendar year of visit"
label var sched_mo "Calendar month of visit"

* identify visits out of study range
gen out_of_range=0
replace out_of_range=1 if sched_mon<1 | sched_mon>21
label var out_of_range "Scheduled visit date out of range"
tabulate out_of_range group, missing
/*
 Scheduled |
visit date |
    out of |         Group
     range |   Control  Intervent |     Total
-----------+----------------------+----------
         0 |    18,835     28,262 |    47,097 
         1 |       280        529 |       809 
-----------+----------------------+----------
     Total |    19,115     28,791 |    47,906 
*/

gen post_its=0
replace post_its=1 if sched_mon > 13
replace post_its=. if out_of_range==1
label var post_its "Month is before/after 01Sep2015 for ITS analyses"
tabulate post_its group, missing
/*
  Month is |
before/aft |
        er |
 01Sep2015 |
   for ITS |         Group
  analyses |   Control  Intervent |     Total
-----------+----------------------+----------
         0 |    12,529     18,331 |    30,860 
         1 |     6,306      9,931 |    16,237 
         . |       280        529 |       809 
-----------+----------------------+----------
     Total |    19,115     28,791 |    47,906 
*/

* post visits for ITS are those with scheduled dates after Sep 1 2015
* pre visits for ITS are those with scheduled dates through Jul 31 2015
* this version leaves Aug visits out of the pre period
gen post_its2=.
replace post_its2=0 if sched_mon < 13 
replace post_its2=1 if sched_mon > 13
replace post_its2=. if out_of_range==1
label var post_its2 "Visit occurs before 31Jul2015/after 01Sep2015 for ITS analyses"

tabulate group post_its, summarize(miss) nostandard missing
tabulate group post_its2, summarize(miss) nostandard missing

* create variables to identify pre and post periods for survival models
* flag pre and post visits
gen post_surv=0
replace post_surv=1 if c_nextvisitdate > td(23Jul2015)
replace post_surv=. if out_of_range==1
label var post_surv "Visit occurs before or after 23Jul2015 used for survival models"

* pre period for survival models starts with first visit 
* pre period runs through last visit before 23Jul2015 (or through 23Jul2015 if patient has a visit after that date)
* post period starts on Jul 24 2015 for patients still present
* post follow-up runs through last visit date before intervention
gen temp=c_visitdate if post_surv==0
gen pre_surv_start=first_date
by end_id: egen pre_surv_end=max(temp)
replace temp=.
replace temp=c_visitdate if post_surv==1
by end_id: egen post_surv_start=min(temp)
replace pre_surv_end = td(23Jul2015) if post_surv_start !=.
replace post_surv_start = td(24Jul2015) if post_surv_start !=.
by end_id: egen post_surv_end=max(temp)
format pre_surv_start pre_surv_end post_surv_start post_surv_end %td
label define prepost 0 "Pre" 1 "Post"
label values post_surv post_its prepost
drop temp
label var pre_surv_start "Date of first visit for pre survival models"
label var pre_surv_end "Date of last visit (if no post visit) or 23Jul2015 for pre survival models"
label var post_surv_start "24Jul2015 if any post visits or missing for post survival models"
label var post_surv_end "Date of last visit for post survival models"

* create month of last visit as offset from July 2014 (654)
gen last_month= mofd(last_date)-653

* drop original date variables
drop visitdate nextvisitdate

order interv base_id end_id num_vis vis_id post_its post_its2 post_surv first_date last_date first_vis ///
		last_vis qual_pre_post continuous c_visitdate c_nextvisitdate visit_mon sched_mon sched_yr next_actual ///
		miss miss3 miss7 miss15 miss60 days_to_sched days_to_next days_to_end arvdaysdispensed ///
		c_art_start age_cat cd4_cat who_stage maritalstatus patientdelivery group district ///
		fac_id fac_label patienttype visittype pre_surv_start pre_surv_end post_surv_start ///
		post_surv_end early_visit no_endline vis_apr_2016 endline_date first_pre first_post num_pre num_post

save "existing pts\3ie_exist_vis.dta", replace


******************************************************************************************
* USE THE PRECEDING DATASET FOR ITS AND SURVIVAL ANALYSIS
******************************************************************************************


******************************************************************************************
******************************************************************************************
* SECTION 3: ADD FIRST AND LAST VISIT DATES AND CONTINUOUS VARIABLE TO PATIENT FILE
******************************************************************************************
******************************************************************************************
use "existing pts\3ie_exist_vis.dta", clear
keep if first_vis==1
keep end_id first_date last_date qual_pre_post continuous no_endline
order end_id first_date last_date qual_pre_post continuous no_endline
merge 1:1 end_id using temp_3ie_exist_pts_without_continuous_variable.dta
*n=3150	merged
keep if _merge==3
table continuous
* n=2402 out of 3150
drop _merge

save "existing pts\3ie_exist_pts.dta", replace

 
******************************************************************************************
******************************************************************************************
* SECTION 4: CREATE PDC DATA
******************************************************************************************
******************************************************************************************
*CALCULATE EXPOSURE DAYS BY CALENDAR MONTH
*FIRST VISIT TO NUMBER OF DAYS DISPENSED FOLLOWING LAST VISIT
use "existing pts\3ie_exist_vis.dta", clear
sort end_id first_date
rename first_date vis1
rename last_date vis2
order end_id vis1 vis2 arvdaysdispensed
* add number of days dispensed to last visit to allow runout
replace vis2=vis2+arvdaysdispensed
keep if last_vis==1
keep end_id vis1 vis2
gen seq=_n
save temp_it, replace
reshape long vis, i( seq)
tsset seq  vis
tsfill
gen mon = mofd(vis)
format mon %tm
rename vis day_at_risk
replace end_id=end_id[_n-1] if _j==.
drop seq _j
order end_id mon day_at_risk
save temp_days_at_risk_exp, replace

*CALCULATE DAYS DISPENSED DURING MONTH
use "existing pts\3ie_exist_vis.dta", clear
di _N
*n=47906
expand  (arvdaysdispensed) 
sort end_id c_visitdate
by end_id c_visitdate: gen covered_day = c_visitdate if _n==1
format covered_day %td
replace covered_day=covered_day[_n-1]+1 if covered_day==. 
sort end_id covered_day
by end_id covered_day: egen pills_available = count(covered_day)
tabulate pills_available

/*
pills_avail |
       able |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |  1,373,959       92.64       92.64
          2 |    108,234        7.30       99.93
          3 |        978        0.07      100.00
------------+-----------------------------------
      Total |  1,483,171      100.00 
*/

keep end_id covered_day pills_available
gen day_at_risk = covered_day
format day_at_risk %td
duplicates drop
merge 1:1 end_id day_at_risk using temp_days_at_risk_exp
sort end_id day_at_risk
drop _merge
replace pills_available=0 if pills_available==.
gen extra_pills=0 
by end_id: replace extra_pills=extra_pills[_n-1]+(pills_available-1) if _n>1 & extra_pills[_n-1]+(pills_available-1)>=0
by end_id: gen covered_day_spread = day_at_risk if covered_day!=. | extra_pills[_n-1]>0 
format covered_day_spread %td
collapse (count) days_at_risk=day_at_risk covered_days=covered_day_spread, by(end_id mon)
label var mon "Study month"
format days_at_risk covered_days %4.0g
gen PDC = covered_days/days_at_risk*100
label var PDC "Proportion of days covered in month"
gen PDCge95 = 0
replace PDCge95 = 1 if PDC>=95
label var PDCge95 "PDC >= 95% during month month"
gen PDCge80 = 0
replace PDCge80 = 1 if PDC>=80
label var PDCge80 "PDC >= 80% during month month"
format PDC PDCge95 PDCge80 %6.1f
save temp_PDC, replace

* MERGE PDC DATA WITH PATIENT AND DESIGN DATA
use "existing pts\3ie_exist_pts.dta", clear
tabulate no_endline
merge 1:m end_id using temp_PDC
* all merge 59,858
drop _merge

* create interv, prepost variable, and last dates
gen sched_mon= mon - tm(2014m6)
label var sched_mon "Study month"
sort end_id sched_mon
tabulate group, missing
/*
       Group |      Freq.     Percent        Cum.
-------------+-----------------------------------
     Control |     23,599       39.42       39.42
Intervention |     36,259       60.58      100.00
-------------+-----------------------------------
       Total |     59,858      100.00
*/

* create post delivery variable
gen post_delivery = .
replace post_delivery=0 if mon < delivery_month & delivery_month !=.
replace post_delivery=1 if mon >= delivery_month & delivery_month !=.
label var post_delivery "Visit is before/after delivery"
tabulate post_delivery, missing
/*
   Visit is |
before/afte |
 r delivery |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |     12,535       20.94       20.94
          1 |     40,373       67.45       88.39
          . |      6,950       11.61      100.00
------------+-----------------------------------
      Total |     59,858      100.00
*/

* identify visits out of study range
gen out_of_range=0
replace out_of_range=1 if sched_mon<1 | sched_mon>21
label var out_of_range "Month out of range"
tabulate out_of_range group, missing
/*
 Month out |         Group
  of range |   Control  Intervent |     Total
-----------+----------------------+----------
         0 |    22,627     34,518 |    57,145 
         1 |       972      1,741 |     2,713 
-----------+----------------------+----------
     Total |    23,599     36,259 |    59,858 
*/

gen interv=0
replace interv=1 if group=="Intervention"
label define interv 0 "Control" 1 "Interv"
label values interv interv
label var interv "Intervention/control (0/1)"

gen sched_yr=2015
replace sched_yr=2014 if sched_mon<7
replace sched_yr=2016 if sched_mon>18
gen sched_mo=sched_mon
replace sched_mo=sched_mon+6 if sched_mon<7
replace sched_mo=sched_mon-6 if sched_mon>6 & sched_mon<19
replace sched_mo=sched_mon-18 if sched_mon>18
label var sched_yr "Calendar year of visit"
label var sched_mo "Calendar month of visit"

* post visits for ITS are those with scheduled dates after Sep 1 2015
* pre visits for ITS are those with scheduled dates through Aug 31 2015
gen post_its=0
replace post_its=1 if sched_mon > 13
replace post_its=. if out_of_range==1
label var post_its "Month is before/after 01Sep2015 for ITS analyses"
tabulate post_its group, missing
/*
  Month is |
before/aft |
        er |
 01Sep2015 |
   for ITS |         Group
  analyses |   Control  Intervent |     Total
-----------+----------------------+----------
         0 |    14,519     22,416 |    36,935 
         1 |     8,108     12,102 |    20,210 
         . |       972      1,741 |     2,713 
-----------+----------------------+----------
     Total |    23,599     36,259 |    59,858 
*/

* post visits for ITS are those with scheduled dates after Sep 1 2015
* pre visits for ITS are those with scheduled dates through Jul 31 2015
* this version leaves Aug visits out of the pre period
gen post_its2=.
replace post_its2=0 if sched_mon < 13 
replace post_its2=1 if sched_mon > 13
replace post_its2=. if out_of_range==1
label var post_its2 "Visit occurs before 31Jul2015/after 01Sep2015 for ITS analyses"

tabulate group post_its, summarize(PDC) nostandard missing
tabulate group post_its2, summarize(PDC) nostandard missing

order interv base_id end_id post_its post_its2 first_date last_date ///
		continuous sched_mon sched_yr sched_mo PDC PDCge80 PDCge95 ///
		c_art_start art_year age_cat cd4_cat who_stage maritalstatus post_delivery delivery_year ///
		group district fac_id fac_label no_endline
		
save "existing pts\3ie_exist_PDC.dta", replace

erase temp_PDC.dta
erase temp_it.dta
erase temp_cleanedvisitendline.dta
erase temp_days_at_risk_exp.dta
erase temp_endvistoclean.dta
erase temp_3ie_exist_pts_without_continuous_variable.dta
erase temp_pt_exist.dta

log close

