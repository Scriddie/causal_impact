cd "c:\3ie\data\"
log using "new pts\3ie_prepare_new_pts.log", replace

*********************************************************
*STEP 1: CREATE NEW PATIENT FILE
*********************************************************
use "endline\all_endline_pts.dta", clear 
duplicates tag (end_id), gen (tag)
count if tag==1
*12 duplicates new/exist; keep them. 
drop tag

*************************
* KEEP ONLY NEW PATIENTS
*************************
keep if base_id==0
di _N
*n=673

* prepare pt variables
gen art_start_mon=mofd(datestartart)
label variable art_start_mon "Month started ART"
format art_start_mon %tm
gen art_year=yofd(datestartart)
label var art_year "Year started ART"

* create delivery year
gen delivery_year=yofd(patientdelivery)
label var delivery_year "Year of delivery"
gen delivery_month = mofd(patientdelivery)
format delivery_month %tm
label var delivery_month "Month of delivery"

* define age categories
replace age="." if age=="null"
destring age, replace
gen age_cat=.
replace age_cat=1 if age<15
replace age_cat=2 if age<21 & age>14
replace age_cat=3 if age<31 & age>20
replace age_cat=4 if age<41 & age>30
replace age_cat=5 if age>40 & age~=.
* reclassify patients <20
replace age_cat=2 if age_cat==1
label define agecat 2 "<20yo" 3 "21-30yo" 4 "31-40yo" 5 ">40yo"
label values age_cat agecat
label variable age_cat "Age category"
drop age

* recode marital status
replace maritalstatus="null" if maritalstatus=="MISSING"
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
gen marstat=.
replace marstat=1 if maritalstatus=="S"
replace marstat=2 if maritalstatus=="M" | maritalstatus=="CO"
replace marstat=3 if maritalstatus=="D" | maritalstatus=="W"
replace marstat=. if maritalstatus=="null"
label define marstat 1 "single" 2 "married/cohab" 3 "divor/widow"
label values marstat marstat
label variable marstat "Marital status"
tabulate marstat, missing

replace whostageatstart="." if whostageatstart=="null"
destring whostageatstart, replace
rename whostageatstart who_stage
label variable who_stage "WHO stage when started ART"

* add facility labels
gen fac_label=""
replace fac_label="Igawilo" if fac_id==1
replace fac_label="Kiwanja" if fac_id==2
replace fac_label="Mbeya" if fac_id==3
replace fac_label="Meta" if fac_id==4
replace fac_label="Ruanda" if fac_id==5
replace fac_label="Chunya" if fac_id==6
replace fac_label="Mwambani" if fac_id==7
replace fac_label="Ipinda" if fac_id==8
replace fac_label="Kyela" if fac_id==9
replace fac_label="Itaka" if fac_id==10
replace fac_label="Mlowo" if fac_id==11
replace fac_label="Vwawa" if fac_id==12
replace fac_label="Chimala" if fac_id==13
replace fac_label="Mbarali" if fac_id==14
replace fac_label="Small" if fac_id==15
replace fac_label="StBakita" if fac_id==16
replace fac_label="Madibira" if fac_id==17
replace fac_label="Kamsamba" if fac_id==18
replace fac_label="Tunduma" if fac_id==19
replace fac_label="Igogwe" if fac_id==20
replace fac_label="Tukuyu" if fac_id==21
replace fac_label="Katete" if fac_id==22
replace fac_label="MbaliziJWTZ" if fac_id==23
replace fac_label="MbaliziMission" if fac_id==24
label var fac_label "Abbreviated facility name"

drop start referredfrom datacollectorscomments

save "temp_new_pts_without_clean_artstart.dta", replace


************************************************************
* SECTION 2: CLEAN VISIT DATA AND CREATE VISIT FILE
************************************************************
use "endline\all_endline_visits.dta", clear 
merge m:1 end_id using "temp_new_pts_without_clean_artstart.dta", keepusing (base_id fac_id facilityname visittype)
tab base_id _merge,m
/*
  Baseline |        _merge
  Study ID | master on  matched ( |     Total
-----------+----------------------+----------
         0 |         0      3,635 |     3,635 
         . |    25,116          0 |    25,116 
-----------+----------------------+----------
     Total |    25,116      3,635 |    28,751 
*/
keep if _merge==3
gen patienttype="newly treated"

keep visittype patienttype end_id visitdate nextvisitdate fac_id arvdaysdispensed
order fac_id end_id visitdate patienttype nextvisitdate arvdaysdispensed

* create cleaning variables
gen c_visitdate=visitdate
format c_visitdate %td
gen c_nextvisitdate=nextvisitdate
format c_nextvisitdate %td
gen c_mo=mofd(visitdate)
gen c_yr=yofd(visitdate)
gen c_next_yr=yofd(nextvisitdate)

* add one year (Dec2014 is c_mo=659) if needed:
sort end_id visitdate
tab visitdate if c_mo==659
replace c_nextvisitdate=c_nextvisitdate +365 if c_mo==659 & c_visitdate>c_nextvisitdate
*n=6
replace c_nextvisitdate=c_nextvisitdate +365 if c_next_yr==2015 &  c_yr==2016 & c_visitdate>c_nextvisitdate & c_visitdate<end
*n=10

tab visitdate if c_mo==671
replace c_nextvisitdate=c_nextvisitdate +365 if c_mo==671 & c_visitdate>c_nextvisitdate
*n=12

*take care of visit typos beyond April2016
replace c_visitdate= visitdate-365 if c_mo>675 & c_next_yr==2015
*n=4
replace c_visitdate= visitdate-730 if c_mo>675 & c_next_yr==2014
*n=1

* correct one by one c_visitdate
replace c_visitdate=visitdate-365 if c_nextvisitdate< c_visitdate &  c_visitdate>end
*n=0
replace c_nextvisitdate=c_visitdate[_n+1] if end_id==800448805 & end_id==end_id[_n+1]& end_id~=end_id[_n-1]
*n=1

sort end_id c_visitdate
replace c_nextvisitdate=c_visitdate +30 if c_nextvisitdate-c_visitdate>364 & c_visitdate[_n+1] -c_visitdate<365 & end_id==end_id[_n+1]
*n=53
replace c_visitdate=c_visitdate +365 if c_nextvisitdate-c_visitdate>364 & end_id==1800104709
*n=1

sort end_id c_visitdate
replace c_nextvisitdate= c_visitdate[_n+1]  if c_visitdate>c_nextvisitdate & end_id==end_id[_n+1] & c_visitdate[_n+1]-c_visitdate<45
*n=10
replace c_nextvisitdate=c_nextvisitdate-365 if c_nextvisitdate -c_visitdate>364
*n=9
replace c_nextvisitdate=c_nextvisitdate+ 365 if c_visitdate>c_nextvisitdate & c_yr==2015 & c_next_yr==2014
*n=6

* drop c_visitdate values that do not make sense and cannot be cleaned
drop if c_visitdate==c_nextvisitdate 
*n=8
drop if c_visitdate>c_nextvisitdate
*n=10
drop if  c_visitdate>end & c_nextvisitdate>end
*n=0
drop if c_visitdate<td(01jun2014)
*n=9

* drop new duplicates
duplicates drop (end_id c_visitdate), force
*n=4

label var visittype "Visit recorded at baseline/endline survey"
label var patienttype "Existing/newly treated patient"
label var c_visitdate "Visit date cleaned with Stata"
label var c_nextvisitdate "Scheduled visit date cleaned with Stata"
drop c_mo c_yr c_next_yr 

**************************
*CREATE VISIT VARIABLES
**************************
*number visits per patient
sort end_id c_visitdate
by end_id:gen vis_id = _n
label var vis_id "Sequence number of visit"

sort end_id vis_id 
by end_id: egen first_date=min(c_visitdate)
by end_id: egen last_date=max(c_visitdate)
by end_id: egen num_vis=max(vis_id)
label var first_date "First visit date"
label var last_date "Last visit date"
label var num_vis "Total number of visits"

gen  first_vis=0
replace first_vis=1 if first_date==c_visitdate
gen  last_vis=0
replace last_vis=1 if last_date==c_visitdate
label var first_vis "Flag for first visit"
label var last_vis "Flag for last visit"

gen visit_mon= mofd(c_visitdate)-mofd(td(01Jul2014))
gen sched_mon= mofd(c_nextvisitdate)-mofd(td(01Jul2014))
label var visit_mon "Study month of visit"
label var sched_mon "Study month of next scheduled visit"

sort end_id c_visitdate

merge m:1 end_id using "temp_new_pts_without_clean_artstart.dta"
* all merged

drop _merge 
save temp_new_vis.dta, replace

******************************************
*CLEAN ART_START BASED ON FIRST VISIT DATE
******************************************
use temp_new_vis.dta, clear

* assume art started at first visit
gen c_art_mon=mofd(first_date)
format c_art_mon %tm
label var c_art_mon "month of art start (first visit)"
gen c_art_year=yofd(first_date)
label var c_art_year "year of art start (first visit)"

*****************************************
*VISIT CALCULATIONS FOR TS ANALSYSES 
*****************************************
sort end_id c_visitdate
gen next_actual = c_visitdate[_n+1] if end_id==end_id[_n+1]
format next_actual %td
gen days_to_next = next_actual-c_visitdate
label var next_actual "Next actual visit date"
label var days_to_next "Number of days to next actual visit"
gen days_to_sched= c_nextvisitdate-c_visitdate
label var days_to_sched "Number of days to scheduled visit"
format first_date last_date %td

gen miss=0 if days_to_next~=.
replace miss=1 if days_to_next>days_to_sched & days_to_next~=.
gen miss3=0 if days_to_next~=.
replace miss3=1 if days_to_next-days_to_sched >2 & days_to_next~=.
gen miss7=0 if days_to_next~=.
replace miss7=1 if days_to_next-days_to_sched >6 & days_to_next~=.
gen miss15=0 if days_to_next~=.
replace miss15=1 if days_to_next-days_to_sched >14 & days_to_next~=.
gen miss60=0 if days_to_next~=.
replace miss60=1 if days_to_next-days_to_sched >59 & days_to_next~=. 
  
order end_id first_date last_date c_visitdate c_nextvisitdate miss miss3 miss7 miss15 miss60

label var miss "delay between cleaned scheduled and next visits"
label var miss3 "delay of 3+d between cleaned scheduled and next visits"
label var miss7 "delay of 7+ between cleaned scheduled and next visits"
label var miss15 "delay of 15+d between cleaned scheduled and next visitss"
label var miss60 "delay of 60+d between cleaned scheduled and next visits" 
  
* flag visits after March 31 2016
gen  vis_apr_2016=0
replace vis_apr_2016=1 if c_visitdate>td(31Mar2016) & c_visitdate~=.
label var vis_apr_2016 "Flags visits after March 31, 2016"

sort end_id c_visitdate 

rename end endline_date
label var endline_date "Data of endline data collection"

* create interv, prepost variable, and last dates
gen interv=0
replace interv=1 if group=="Intervention"
label define interv 0 "Control" 1 "Interv"
label values interv interv
label var interv "Intervention/control (0/1)"

* create post_its delivery variable
gen post_delivery = 1
replace post_delivery=0 if c_visitdate < patientdelivery
label var post_delivery "Visit is before/after delivery"
table post_delivery, missing
/*
Visit is  |
before/af |
ter       |
delivery  |      Freq.
----------+-----------
        0 |      2,124
        1 |      1,480
----------------------
*/

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
         0 |     1,683      1,814 |     3,497 
         1 |        38         69 |       107 
-----------+----------------------+----------
     Total |     1,721      1,883 |     3,604 
*/

* drop one case starting in month 0 
drop if end_id==500312308
di _N
* n=3602 good visits

* create month of first visit
gen first_month=0
replace first_month= mofd(first_date)
format first_month %tm
tabulate first_month if first_vis==1
/*
first_month |      Freq.     Percent        Cum.
------------+-----------------------------------
     2014m7 |          2        0.30        0.30
     2014m8 |         36        5.36        5.65
     2014m9 |         28        4.17        9.82
    2014m10 |         36        5.36       15.18
    2014m11 |         38        5.65       20.83
    2014m12 |         33        4.91       25.74
     2015m1 |         37        5.51       31.25
     2015m2 |         10        1.49       32.74
     2015m3 |          4        0.60       33.33
     2015m4 |          2        0.30       33.63
     2015m5 |          1        0.15       33.78
     2015m6 |          2        0.30       34.08
     2015m7 |         59        8.78       42.86
     2015m8 |         57        8.48       51.34
     2015m9 |         69       10.27       61.61
    2015m10 |         71       10.57       72.17
    2015m11 |         76       11.31       83.48
    2015m12 |         81       12.05       95.54
     2016m1 |         14        2.08       97.62
     2016m2 |         15        2.23       99.85
     2016m3 |          1        0.15      100.00
------------+-----------------------------------
      Total |        672      100.00
*/

gen post_its=0
replace post_its=1 if sched_mon > 14
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
         0 |       667        738 |     1,405 
         1 |     1,016      1,075 |     2,091 
         . |        38         68 |       106 
-----------+----------------------+----------
     Total |     1,721      1,881 |     3,602 
*/

* create variables to identify pre and post periods for survival models
* flag pre and post visits
gen post_surv=0
replace post_surv=1 if first_date > td(23Jul2015)
label var post_surv "Visit occurs before or after 23Jul2015 used for survival models"

* pre start before July 01, 2015 with follow-up ending July 31 2015
* post start after Aug 1, 2015
* loses 59 patients starting in July
gen pre_post=.
replace pre_post=0 if first_date<td(01Jul2015)
replace pre_post=1 if first_date>td(31Jul2015)
tabulate group pre_post
label define prepost 0 "Pre" 1 "Post"
label values pre_post prepost
label var pre_post "Patient started before/after intervention"

gen end_of_followup=endline_date
format end_of_followup %td
replace end_of_followup=td(23Jul2015) if pre_post==0
gen censor=end_of_followup-first_date
label var end_of_followup "End of followup Jul 23 2015/endline date"
label var censor "# of days from initiation to end of followup"

* create dates of first misses and survival variables
* 1-day miss
gen temp=.
by end_id: replace temp=c_nextvisitdate-first_date if miss==1
by end_id: egen firstmiss1 = min(temp)
drop temp
gen miss1_180 = 0
replace miss1_180=1 if firstmiss1 <= censor 
gen censor1_180 = min(180,censor,firstmiss1)
* 3-day miss
gen temp=.
by end_id: replace temp=c_nextvisitdate-first_date if miss3==1
by end_id: egen firstmiss3 = min(temp)
drop temp
gen miss3_180 = 0
replace miss3_180=1 if firstmiss3 <= censor 
gen censor3_180 = min(180,censor,firstmiss3)
* 7-day miss
gen temp=.
by end_id: replace temp=c_nextvisitdate-first_date if miss7==1
by end_id: egen firstmiss7 = min(temp)
drop temp
gen miss7_180 = 0
replace miss7_180=1 if firstmiss7 <= censor 
gen censor7_180 = min(180,censor,firstmiss7)
* 15-day miss
gen temp=.
by end_id: replace temp=c_nextvisitdate-first_date if miss15==1
by end_id: egen firstmiss15 = min(temp)
drop temp
gen miss15_180 = 0
replace miss15_180=1 if firstmiss15 <= censor 
gen censor15_180 = min(180,censor,firstmiss15)
* 60-day miss
gen temp=.
by end_id: replace temp=c_nextvisitdate-first_date if miss60==1
by end_id: egen firstmiss60 = min(temp)
drop temp
gen miss60_180 = 0
replace miss60_180=1 if firstmiss60 <= censor 
gen censor60_180 = min(180,censor,firstmiss60)

tabulate pre_post group if first_vis==1, col
/*
   Patient |
   started |
before/aft |
        er |
interventi |         Group
        on |   Control  Intervent |     Total
-----------+----------------------+----------
       Pre |       108        120 |       228 
           |     37.37      37.04 |     37.19 
-----------+----------------------+----------
      Post |       181        204 |       385 
           |     62.63      62.96 |     62.81 
-----------+----------------------+----------
     Total |       289        324 |       613 
           |    100.00     100.00 |    100.00 
*/

* drop original date variables
drop visitdate nextvisitdate

order interv base_id end_id num_vis vis_id post_its post_surv first_date last_date first_vis ///
		last_vis c_visitdate c_nextvisitdate visit_mon sched_mon next_actual ///
		miss miss3 miss7 miss15 miss60 days_to_sched days_to_next arvdaysdispensed ///
		c_art_mon c_art_year age_cat who_stage maritalstatus patientdelivery group district ///
		fac_id facilityname fac_label patienttype visittype vis_apr_2016 endline_date
	  
save "new pts\3ie_new_vis.dta", replace  

******************************************************************************************
* ADD CLEAN ART START, PRE_POST AND FIRST_DATE TO PATIENT FILE
******************************************************************************************
use "new pts\3ie_new_vis.dta", clear  
keep if first_vis==1
keep end_id c_art_mon c_art_year first_month pre_post
merge 1:1 end_id using "temp_new_pts_without_clean_artstart.dta"
* 1 not merged
drop _merge

save "new pts\3ie_new_pts.dta", replace 


******************************************************************************************
* SECTION 3: CREATE PDC DATA
******************************************************************************************
*CALCULATE EXPOSURE DAYS BY CALENDAR MONTH
*FIRST VISIT TO NUMBER OF DAYS DISPENSED FOLLOWING LAST VISIT
use "new pts\3ie_new_vis.dta", clear
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
use "new pts\3ie_new_vis.dta", clear
di _N
*3602
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
          1 |    101,508       92.22       92.22
          2 |      8,440        7.67       99.88
          3 |        129        0.12      100.00
------------+-----------------------------------
      Total |    110,077      100.00
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
format days_at_risk covered_days %4.0g
gen PDC = covered_days/days_at_risk*100
gen PDCge95 = 0
replace PDCge95 = 1 if PDC>=95
gen PDCge80 = 0
replace PDCge80 = 1 if PDC>=80
format PDC PDCge95 PDCge80 %6.1f
save temp_PDC, replace

* MERGE PDC DATA WITH PATIENT AND DESIGN DATA
use "new pts\3ie_new_pts.dta", clear
merge 1:m end_id using temp_PDC
* 1 does not merge
drop _merge
table patienttype
* n=4901
sort end_id mon

* create interv, prepost variable, and last dates
gen sched_mon= mon - tm(2014m6)
label var sched_mon "Study month"
sort end_id sched_mon
tabulate group, missing
/*
       Group |      Freq.     Percent        Cum.
-------------+-----------------------------------
     Control |      2,352       47.99       47.99
Intervention |      2,549       52.01      100.00
-------------+-----------------------------------
       Total |      4,901      100.00
*/

* create post_its delivery variable
format patientdelivery %td
format delivery_month %tm
gen post_delivery = 1
replace post_delivery=0 if mon < delivery_month
table post_delivery
/*
----------------------
post_deli |
very      |      Freq.
----------+-----------
        0 |      2,348
        1 |      2,553
----------------------
*/
label var post_delivery "Month is after delivery month"

* identify visits out of study range
gen out_of_range=0
replace out_of_range=1 if sched_mon<1 | sched_mon>21
label var out_of_range "Month out of range"
tabulate out_of_range group, missing
/*
 Month out |         Group
  of range |   Control  Intervent |     Total
-----------+----------------------+----------
         0 |     2,180      2,320 |     4,500 
         1 |       172        229 |       401 
-----------+----------------------+----------
     Total |     2,352      2,549 |     4,901 
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

* create interv, prepost variable, and last dates
gen post_its=0
replace post_its=1 if sched_mon > 14
replace post_its=. if out_of_range==1
label var post_its "Month is before/after Sep2015"
tabulate post_its group, missing
table interv post_its, missing
/*
------------------------
          |   Month is  
          | before/after
Intervent |01Sep2015 for
ion/contr | ITS analyses
ol (0/1)  |     0      1
----------+-------------
  Control |   931  1,249
   Interv | 1,021  1,299
------------------------
*/

* post visits for ITS are those with scheduled dates after Sep 1 2015
* pre visits for ITS are those with scheduled dates through Jul 31 2015
* this version leaves Aug visits out of the pre period
gen post_its2=.
replace post_its2=0 if sched_mon < 14 
replace post_its2=1 if sched_mon > 14
replace post_its2=. if out_of_range==1
label var post_its2 "Visit occurs before 31Jul2015/after 01Sep2015 for ITS analyses"

order interv base_id end_id post_its post_its2 ///
		sched_mon sched_yr sched_mo PDC PDCge80 PDCge95 ///
		c_art_year age_cat who_stage maritalstatus post_delivery delivery_year ///
		group district fac_id facilityname fac_label 

save "new pts\3ie_new_PDC.dta", replace
 
erase temp_PDC.dta
erase temp_it.dta
erase temp_days_at_risk_exp.dta
erase temp_new_vis.dta
erase temp_new_pts_without_clean_artstart.dta
 
log close

