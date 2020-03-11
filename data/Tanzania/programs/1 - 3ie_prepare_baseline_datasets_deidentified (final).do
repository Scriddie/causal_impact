*******************************************************
*PREPARE AND MERGE BASELINE (APRIL-MAY 2015) DATASETS
*********************************************************
cd "c:\3ie\data\baseline"
log using "3ie_prepare_baseline_datasets.log", replace

*******************************
* 1 - prepare facility dataset
*******************************
clear
import excel "Facility_Records-baseline deidentified", ///
	sheet("Group assignment")  firstrow case(lower)
order group district facilitycode 
rename facilitycode fac_id
save "3ie_fac.dta", replace

*****************************
* 2 - prepare patient dataset
*****************************
clear
import excel "Patient Data Profile-baseline deidentified", ///
sheet("Patient Records Reformatted") firstrow case(lower)
describe
rename studyid base_id
rename facilitycode fac_id
format base_id %16.0f
duplicates drop (fac_id base_id), force

gen art_start=mofd(datestartart)
label variable art_start "Date started ART"
format art_start %tm

replace age="." if age=="null"
destring age, replace
gen age_cat=.
replace age_cat=1 if age<15
replace age_cat=2 if age<21 & age>14
replace age_cat=3 if age<31 & age>20
replace age_cat=4 if age<41 & age>30
replace age_cat=5 if age>40 & age~=.
label define age 1 "<15yo"2 "15-20yo" 3 "21-30yo"4"31-40yo"5 ">40yo"
label values age_cat age
label variable age_cat "Age category"

replace cd4countatstart="." if cd4countatstart=="null"
destring cd4countatstart, replace
gen cd4_cat=.
replace cd4_cat=1 if cd4countatstart<200
replace cd4_cat=2 if cd4countatstart<501 & cd4countatstart>199
replace cd4_cat=3 if cd4countatstart>500 & cd4countatstart~=.
label define  cd4 1 "<200"2 "200-500" 3 ">500"
label values cd4_cat cd4
label variable cd4_cat  "cd4 count category when started ART"

replace whostageatstart="." if whostageatstart=="null"
destring whostageatstart, replace
rename whostageatstart who_stage
label variable who_stage "WHO stage when started ART"
drop   age cd4countatstart datacollectorcomments ///
referredfrom birthdate

***************************************************
* keep base_id as the unique pt identifier and drop duplicates
***************************************************
sort base_id
duplicates tag (fac_id base_id), gen (tag)
tab tag
/* 

        tag |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |      3,177      100.00      100.00
------------+-----------------------------------
      Total |      3,177      100.00
*/

duplicates tag (base_id), gen (tog)
list fac_id base_id tog if tog==1

di _N
*3177

* insert facility variables
merge m:1 fac_id using 3ie_fac.dta
drop _merge
save "pt.dta", replace

****************************
* 3 - prepare visit dataset
****************************
clear
import excel "Patient Visit-baseline deidentified", ///
sheet("Patient Visits Reformatted") firstrow case(lower)
rename studyid base_id
format base_id %16.0f
describe
duplicates drop
drop followupstatus mostrecentlydateswhereadheren k ///
mostrecentlydateswhereappoint m
order base_id
sort base_id visitdate
save toclean, replace
di _N
* n=27,768

**************
*CLEAN VISITS
**************
use toclean, clear
* create clean (c_) variables
gen c_visitdate=visitdate
format c_visitdate %td
gen c_nextvisitdate=nextvisitdate
format c_nextvisitdate %td
gen double vis=dofd( visitdate)
gen c_mo=mofd(visitdate)
gen c_yr=yofd(visitdate)
gen c_next_yr=yofd(nextvisitdate)
order base_id visitdate nextvisitdate vis c_visitdate c_nextvisitdate c_mo c_yr c_next_yr

*drop duplicate visits
duplicates drop (base_id visitdate nextvisitdate), force
* n=9

* correct month typos on visit date
sort base_id c_visitdate
replace c_visitdate= c_visitdate[_n-1] + 30 ///
 if base_id==base_id[_n-1] & base_id==base_id[_n+1] & c_visitdate-c_visitdate[_n-1]<7 & c_visitdate[_n+1]-c_visitdate[_n-1]>59

 * correct year typos on visit date and nextvisitdate
sort base_id c_visitdate
replace c_visitdate=c_nextvisitdate -30 if base_id==base_id[_n+1] & c_visitdate[_n+1]-c_nextvisitdate<7 & vis<0
replace c_nextvisitdate=c_visitdate +30 if nextvisitdate<19000

* add one year:
replace c_nextvisitdate=c_nextvisitdate +365 if c_mo==659 & c_visitdate>c_nextvisitdate
replace c_nextvisitdate=c_nextvisitdate +365 if c_next_yr==2014 &  c_yr==2015 & c_visitdate>c_nextvisitdate & c_visitdate<20224

*assume vis occurred 30d before scheduled if 30days dispensed and vis<19000
replace c_visitdate=c_nextvisitdate-30 if arvdaysdispensed==30 & c_visitdate<19000

*assume scheduled visit 30d after visit if visit= 5/15/2015(20223)
*and 30 pills dispensed
sort base_id visitdate
replace c_nextvisitdate=c_visitdate + 30 if visitdate==20223 & arvdaysdispensed==30

* change scheduled if it is = May15, 2015 (20223) and visit is in 2014
replace c_nextvisitdate=c_visitdate + 30 if c_nextvisitdate==20223 &  c_yr==2014

* cannot clean if two dates are beyond 5/15/2015 or before  June2012
drop if c_visitdate>20223 & c_nextvisitdate>20223
drop if c_visitdate<19146 & c_nextvisitdate<19146

* drop what does not make sense and cannot be cleaned
drop if c_nextvisitdate< c_visitdate
drop if c_visitdate==c_nextvisitdate
sort base_id visitdate
drop if base_id~=base_id[_n-1] & base_id==base_id[_n+1]& c_visitdate[_n+1]-c_visitdate>150
drop if c_nextvisitdate -c_visitdate>365

*visits before August 2013 (643) do not make sense: drop them
drop if c_mo<643

*drop duplicates and near duplicate visits <7d 
sort base_id c_visitdate
drop if base_id==base_id[_n-1] & c_visitdate-c_visitdate[_n-1]<7 

*assume that  pills are given at each visit 
replace arvdaysdispensed=30 if (c_nextvisitdate-c_visitdate>15) & (c_nextvisitdate-c_visitdate)<45 & arvdaysdispensed==.
replace arvdaysdispensed=60 if (c_nextvisitdate-c_visitdate>44) & (c_nextvisitdate-c_visitdate)<62 & arvdaysdispensed==.
di _N
* n=26,797

tab arvdaysdispensed,m
/*
   ARV days |
  Dispensed |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |          2        0.01        0.01
          3 |         12        0.04        0.05
          4 |          1        0.00        0.06
          5 |          2        0.01        0.06
          7 |          2        0.01        0.07
         14 |         45        0.17        0.24
         15 |          1        0.00        0.24
         21 |          1        0.00        0.25
         30 |     25,921       96.73       96.98
         38 |          5        0.02       97.00
         40 |          2        0.01       97.00
         60 |        518        1.93       98.94
          . |        285        1.06      100.00
------------+-----------------------------------
      Total |     26,797      100.00
*/
replace arvdaysdispensed=30 if arvdaysdispensed==.
* 285 changes

**************************
*CREATE VISIT VARIABLES
**************************
drop vis c_mo c_yr c_next_yr
gen double vis=dofd( c_visitdate)
gen double sched=dofd( c_nextvisitdate)
*number visits per patient
sort base_id c_visitdate
by base_id:gen vis_id = _n
sort base_id vis_id 
by base_id: egen first=min(vis)
by base_id: egen last=max(vis)
by base_id: egen num_vis=max(vis_id)
gen  first_vis=0
replace first_vis=1 if first==vis
gen  last_vis=0
replace last_vis=1 if last==vis
*set first month of study as July 2014 (654) (first visitdate)  
global first_visit "653"
* create time variables in relation to the recorded visit  
gen xyear=yofd(c_visitdate)
gen xmonth=mofd(c_visitdate)
format xmonth %tm 
gen vis_month=xmonth - ${first_visit}
gen c_month=dofm(xmonth)
format c_month %td

sort base_id vis
gen next= vis[_n+1] if base_id==base_id[_n+1] 
gen sched_month= mofd(c_nextvisitdate)-${first_visit}
gen it= mofd(c_nextvisitdate)
format it %tm 
gen s_month=dofm(it) 
format s_month %td
drop it
order base_id vis sched next c_visitdate c_nextvisitdate ///
xyear xmonth vis_month sched_month vis_id first_vis last_vis
di _N
*26797
save visit, replace

*******************************************
*CLEAN ART_START
******************************************
use visit, clear
keep base_id c_visitdate c_nextvisitdate first_vis xmonth
keep if  first_vis ==1
merge 1:1 base_id using pt.dta,keepusing (art_start)
* drop visits that have no patients and pts who have no visits
keep if _merge==3
drop _merge

gen ort=art_start
gen c_mo=xmonth
gen it=xmonth-ort
sum it, d
/*
                            it
-------------------------------------------------------------
      Percentiles      Smallest
 1%          -11            -71
 5%           -5            -47
10%            0            -36       Obs                3151
25%            0            -34       Sum of Wgt.        3151

50%            5                      Mean           14.62107
                        Largest       Std. Dev.      57.93328
75%           15           1366
90%           44           1368       Variance       3356.265
95%           62           1368       Skewness       20.27224
99%           87           1369       Kurtosis       471.1177
-->assume all art_start that are >24 months before first visit should be
5 months before
*/

sort ort
replace art_start=c_mo if c_mo<ort
replace art_start=c_mo -5 if c_mo-ort>24
gen n=dofm(art_start)
format n % td
rename n c_art_start
label variable c_art_start "cleaned ART start for excel"
label variable art_start "cleaned ART start"
keep base_id art_start c_art_start
save it, replace
use pt.dta, clear
drop art_start
merge 1:1 base_id using  it

* drop pts who have no visits
keep if _merge==3
* n=3151
drop _merge
order group district fac_id ///
 base_id art_start c_art_start maritalstatus ///
 who_stage age_cat cd4_cat datestartart
save "3ie_base_pt.dta", replace

**************************************************
use visit, clear
merge m:1 base_id using 3ie_base_pt.dta

*drop visits that have no pts
keep if _merge==3
drop _merge 
label var vis "c_visit date"
label var first "c_first visit date"
label var last "c_last visit date"
label var first_vis "c_check for first visit"
label var last_vis "c_check for last visit"
label var next "c_next actual visit date"
label var num_vis "c_number of visits"  
label var sched "scheduled visit date"
label var sched_month "c_month # of scheduled visit (first month is July 2014)"
label var vis_month "c_month #of visit (first month is July 2014)"
label var c_month "c_month of actual visit"
label var s_month "c_month of scheduled visit"
label var xmonth "c_year and month of visit"
label var xyear "c_year of visit"
label var c_visitdate "visit date corrected with stata"
label var c_nextvisitdate "next visit date corrected with stata"
label var vis_id "visit number"
describe
order group district fac_id base_id ///
 c_visitdate c_nextvisitdate vis_id first_vis last_vis vis sched next ///
 xyear xmonth c_month s_month vis_month sched_month arvregimen anyotherregimen arvdaysdispensed ///
 arvreason arvadherence arvadherencepoorreason visitdate nextvisitdate
di _N
* n=26,645

save "3ie_base_visit.dta", replace

***********************
*remove temp files
***********************
erase pt.dta
erase visit.dta
erase it.dta
erase toclean.dta
log close
