set more off

cd "c:\3ie\data"
log using "c:\3ie\analysis\Table1_existing_pts.log", replace

*********************************************************************************************** 
*********************************************************************************************** 
* SECTION 1: CREATE TABLE 1 FOR EXISTING PATIENTS
*********************************************************************************************** 
*********************************************************************************************** 

************************************************************************************************
* TABLE 1 FOR ALL EXISTING PATIENTS
************************************************************************************************
use "existing pts\3ie_exist_pts.dta", clear
* drop record with only 1 visit in 2013
drop if end_id==100797722
* create month of last visit as offset from July 2014 (654)
gen last_month= mofd(last_date)
format last_month %tm

tabulate group, missing
tabulate age_cat group, missing col nofreq chi2
tabulate marstat group, missing col nofreq chi2
tabulate who_stage group, missing col nofreq chi2
tabulate cd4_cat group, missing col nofreq chi2
tabulate art_year group, missing col nofreq chi2
tabulate delivery_year group, missing col nofreq chi2
tabulate last_month group, missing col nofreq chi2

************************************************************************************************
* TABLE 1 FOR CONTINUOUS EXISTING PATIENTS
************************************************************************************************
use "existing pts\3ie_exist_pts.dta", clear
* drop record with only 1 visit in 2013
drop if end_id==100797722
* create month of last visit as offset from July 2014 (654)
gen last_month= mofd(last_date)
format last_month %tm
keep if continuous==1

tabulate group, missing
tabulate age_cat group, missing col nofreq chi2
tabulate marstat group, missing col nofreq chi2
tabulate who_stage group, missing col nofreq chi2
tabulate cd4_cat group, missing col nofreq chi2
tabulate art_year group, missing col nofreq chi2
tabulate delivery_year group, missing col nofreq chi2
tabulate last_month group, missing col nofreq chi2

************************************************************************************************
* TABLE 1 FOR NON-CONTINUOUS EXISTING PATIENTS
************************************************************************************************
use "existing pts\3ie_exist_pts.dta", clear
* drop record with only 1 visit in 2013
drop if end_id==100797722
* create month of last visit as offset from July 2014 (654)
gen last_month= mofd(last_date)
format last_month %tm
keep if continuous==0

tabulate group, missing
tabulate age_cat group, missing col nofreq chi2
tabulate marstat group, missing col nofreq chi2
tabulate who_stage group, missing col nofreq chi2
tabulate cd4_cat group, missing col nofreq chi2
tabulate art_year group, missing col nofreq chi2
tabulate delivery_year group, missing col nofreq chi2
tabulate last_month group, missing col nofreq chi2


************************************************************************************************
* TABLE 1 CONTRASTING CONTINUOUS VS. NON-CONTINUOUS FOR CONTROL PATIENTS 
************************************************************************************************
use "existing pts\3ie_exist_pts.dta", clear
* drop record with only 1 visit in 2013
drop if end_id==100797722
* create month of last visit as offset from July 2014 (654)
gen last_month= mofd(last_date)
format last_month %tm
keep if group=="Control"

tabulate continuous, missing
tabulate age_cat continuous, missing col nofreq chi2
tabulate marstat continuous, missing col nofreq chi2
tabulate who_stage continuous, missing col nofreq chi2
tabulate cd4_cat continuous, missing col nofreq chi2
tabulate art_year continuous, missing col nofreq chi2
tabulate delivery_year continuous, missing col nofreq chi2
tabulate last_month continuous, missing col nofreq chi2

************************************************************************************************
* TABLE 1 CONTRASTING CONTINUOUS VS. NON-CONTINUOUS FOR INTERVENTION PATIENTS 
************************************************************************************************
use "existing pts\3ie_exist_pts.dta", clear
* drop record with only 1 visit in 2013
drop if end_id==100797722
* create month of last visit as offset from July 2014 (654)
gen last_month= mofd(last_date)
format last_month %tm
keep if group=="Intervention"

tabulate continuous, missing
tabulate age_cat continuous, missing col nofreq chi2
tabulate marstat continuous, missing col nofreq chi2
tabulate who_stage continuous, missing col nofreq chi2
tabulate cd4_cat continuous, missing col nofreq chi2
tabulate art_year continuous, missing col nofreq chi2
tabulate delivery_year continuous, missing col nofreq chi2
tabulate delivery_year continuous, col nofreq chi2
tabulate last_month continuous, missing col nofreq chi2


************************************************************************************************
*********************************************************************************************** 
* SECTION 2: CREATE TABLE 1 FOR VISITS AMONG ALL EXISTING PATIENTS
*********************************************************************************************** 
************************************************************************************************

*********************************************************************************************** 
* TABLE 1 VISITS FOR ALL EXISTING PATIENTS
*********************************************************************************************** 
use "existing pts\3ie_exist_vis.dta", clear
* drop record with only 1 visit in 2013
drop if end_id==100797722

tabulate post_its, missing
tabulate fac_id post_its, row nofreq missing chi2
keep if post_its==0
keep if miss !=.

tabulate fac_id post_its, missing nofreq row chi2
tabulate num_vis group, missing chi2 nofreq col

tabulate group, missing
tabulate post_delivery group , missing chi2 nofreq col
tabulate miss group , missing chi2 nofreq col
tabulate miss3 group , missing chi2 nofreq col
tabulate miss7 group , missing chi2 nofreq col
tabulate miss15 group , missing chi2 nofreq col
tabulate miss60 group , missing chi2 nofreq col

use "existing pts\3ie_exist_PDC.dta", clear
* drop record with only 1 visit in 2013
drop if end_id==100797722
keep if post_its==0

tabulate group, missing
ttest PDC , by(group)
tabulate PDCge80 group , missing col nofreq chi2
tabulate PDCge95 group , missing col nofreq chi2

*********************************************************************************************** 
* TABLE 1 VISITS FOR CONTINUOUS EXISTING PATIENTS
*********************************************************************************************** 
use "existing pts\3ie_exist_vis.dta", clear
* drop record with only 1 visit in 2013
drop if end_id==100797722
keep if continuous==1

tabulate post_its, missing
tabulate fac_id post_its, row nofreq missing chi2
keep if post_its==0
keep if miss !=.

tabulate fac_id post_its, missing nofreq row chi2
tabulate num_vis group, missing chi2 nofreq col

tabulate group, missing
tabulate post_delivery group , missing chi2 nofreq col
tabulate miss group , missing chi2 nofreq col
tabulate miss3 group , missing chi2 nofreq col
tabulate miss7 group , missing chi2 nofreq col
tabulate miss15 group , missing chi2 nofreq col
tabulate miss60 group , missing chi2 nofreq col

use "existing pts\3ie_exist_PDC.dta", clear
* drop record with only 1 visit in 2013
drop if end_id==100797722
keep if post_its==0 & group !=""
keep if continuous==1

tabulate group, missing
ttest PDC , by(group)
tabulate PDCge80 group , missing col nofreq chi2
tabulate PDCge95 group , missing col nofreq chi2

*********************************************************************************************** 
* TABLE 1 FOR NON-CONTINUOUS EXISTING PATIENTS
*********************************************************************************************** 
use "existing pts\3ie_exist_vis.dta", clear
* drop record with only 1 visit in 2013
drop if end_id==100797722
keep if continuous==0

tabulate post_its, missing
tabulate fac_id post_its, row nofreq missing chi2
keep if post_its==0
keep if miss !=.

tabulate fac_id post_its, missing nofreq row chi2
tabulate num_vis group, missing chi2 nofreq col

tabulate group, missing
tabulate post_delivery group , missing chi2 nofreq col
tabulate miss group , missing chi2 nofreq col
tabulate miss3 group , missing chi2 nofreq col
tabulate miss7 group , missing chi2 nofreq col
tabulate miss15 group , missing chi2 nofreq col
tabulate miss60 group , missing chi2 nofreq col

use "existing pts\3ie_exist_PDC.dta", clear
* drop record with only 1 visit in 2013
drop if end_id==100797722
keep if post_its==0 & group !=""
keep if continuous==0

tabulate group, missing
ttest PDC , by(group)
tabulate PDCge80 group , missing col nofreq chi2
tabulate PDCge95 group , missing col nofreq chi2

*********************************************************************************************** 
* TABLE 1 CONTRASTING CONTINUOUS VS. NON-CONTINUOUS FOR EXISTING CONTROL PATIENTS
*********************************************************************************************** 
use "existing pts\3ie_exist_vis.dta", clear
* drop record with only 1 visit in 2013
drop if end_id==100797722
keep if group=="Control"
keep if post_its==0
keep if miss !=.

tabulate fac_id post_its, missing nofreq row chi2

tabulate continuous, missing
tabulate post_delivery continuous , missing chi2 nofreq col
tabulate miss continuous , missing chi2 nofreq col
tabulate miss3 continuous , missing chi2 nofreq col
tabulate miss7 continuous , missing chi2 nofreq col
tabulate miss15 continuous , missing chi2 nofreq col
tabulate miss60 continuous , missing chi2 nofreq col

use "existing pts\3ie_exist_PDC.dta", clear
* drop record with only 1 visit in 2013
drop if end_id==100797722
keep if group=="Control"
keep if post_its==0

tabulate continuous, missing
ttest PDC , by(continuous)
tabulate PDCge80 continuous , missing col nofreq chi2
tabulate PDCge95 continuous , missing col nofreq chi2

*********************************************************************************************** 
* TABLE 1 CONTRASTING CONTINUOUS VS. NON-CONTINUOUS FOR EXISTING INTERVENTION PATIENTS
*********************************************************************************************** 
use "existing pts\3ie_exist_vis.dta", clear
* drop record with only 1 visit in 2013
drop if end_id==100797722
keep if group=="Intervention"
keep if post_its==0
keep if miss !=.

tabulate fac_id post_its, missing nofreq row chi2

tabulate continuous, missing
tabulate post_delivery continuous , missing chi2 nofreq col
tabulate miss continuous , missing chi2 nofreq col
tabulate miss3 continuous , missing chi2 nofreq col
tabulate miss7 continuous , missing chi2 nofreq col
tabulate miss15 continuous , missing chi2 nofreq col
tabulate miss60 continuous , missing chi2 nofreq col

use "existing pts\3ie_exist_PDC.dta", clear
* drop record with only 1 visit in 2013
drop if end_id==100797722
keep if group=="Intervention"
keep if post_its==0

tabulate continuous, missing
ttest PDC , by(continuous)
tabulate PDCge80 continuous , missing col nofreq chi2
tabulate PDCge95 continuous , missing col nofreq chi2

log close


************************************************************************************************
************************************************************************************************
* SECTION 3: TABLE 1 FOR ALL NEW PATIENTS
************************************************************************************************
************************************************************************************************

************************************************************************************************
* TABLE 2 FOR ALL NEW PATIENTS
************************************************************************************************
log using "c:\3ie\analysis\Table2_new_pts.log", replace
use "new pts\3ie_new_pts.dta", clear
count
*n=673

* limit new patients: 
* pre start before July 01, 2015 with follow-up ending July 31 2015
* post start after Aug 1, 2015

tabulate pre_post group, missing
tabulate age_cat group if pre_post==0, missing chi2 nofreq col
tabulate marstat group if pre_post==0, missing chi2 nofreq col
tabulate who_stage group if pre_post==0, missing chi2 nofreq col
tabulate c_art_year group if pre_post==0, missing chi2 nofreq col
tabulate delivery_year group if pre_post==0, missing chi2 nofreq col
tabulate first_month group if pre_post==0, missing chi2 nofreq col

tabulate age_cat group if pre_post==1, missing chi2 nofreq col
tabulate marstat group if pre_post==1, missing chi2 nofreq col
tabulate who_stage group if pre_post==1, missing chi2 nofreq col
tabulate c_art_year group if pre_post==1, missing chi2 nofreq col
tabulate delivery_year group if pre_post==1, missing chi2 nofreq col
tabulate first_month group if pre_post==1, missing chi2 nofreq col

*********************************************************************************************** 
* TABLE 1 VISITS FOR ALL NEW PATIENTS
*********************************************************************************************** 
use "new pts\3ie_new_vis.dta", clear

tabulate first_month pre_post, missing
/*
           |   Patient started before/after
first_mont |           intervention
         h |       Pre       Post          . |     Total
-----------+---------------------------------+----------
    2014m7 |         6          0          0 |         6 
    2014m8 |       207          0          0 |       207 
    2014m9 |       188          0          0 |       188 
   2014m10 |       201          0          0 |       201 
   2014m11 |       242          0          0 |       242 
   2014m12 |       202          0          0 |       202 
    2015m1 |       226          0          0 |       226 
    2015m2 |        48          0          0 |        48 
    2015m3 |        32          0          0 |        32 
    2015m4 |        13          0          0 |        13 
    2015m6 |        10          0          0 |        10 
    2015m7 |         0          0        357 |       357 
    2015m8 |         0        317          0 |       317 
    2015m9 |         0        400          0 |       400 
   2015m10 |         0        385          0 |       385 
   2015m11 |         0        357          0 |       357 
   2015m12 |         0        322          0 |       322 
    2016m1 |         0         50          0 |        50 
    2016m2 |         0         37          0 |        37 
    2016m3 |         0          2          0 |         2 
-----------+---------------------------------+----------
     Total |     1,375      1,870        357 |     3,602 
*/

tabulate fac_id post_its, missing

tabulate pre_post group, missing
tabulate num_vis group if pre_post==0, missing chi2 nofreq col
tabulate post_delivery group if pre_post==0, missing chi2 nofreq col
tabulate miss group if pre_post==0, missing chi2 nofreq col
tabulate miss3 group if pre_post==0, missing chi2 nofreq col
tabulate miss7 group if pre_post==0, missing chi2 nofreq col
tabulate miss15 group if pre_post==0, missing chi2 nofreq col
tabulate miss60 group if pre_post==0, missing chi2 nofreq col

tabulate num_vis group if pre_post==1, missing chi2 nofreq col
tabulate post_delivery group if pre_post==1, missing chi2 nofreq col
tabulate miss group if pre_post==1, missing chi2 nofreq col
tabulate miss3 group if pre_post==1, missing chi2 nofreq col
tabulate miss7 group if pre_post==1, missing chi2 nofreq col
tabulate miss15 group if pre_post==1, missing chi2 nofreq col
tabulate miss60 group if pre_post==1, missing chi2 nofreq col

use "new pts\3ie_new_PDC.dta", clear

ttest PDC if pre_post==0, by(group)
tabulate PDCge80 group if pre_post==0, missing chi2 nofreq col
tabulate PDCge95 group if pre_post==0, missing chi2 nofreq col

ttest PDC if pre_post==1, by(group)
tabulate PDCge80 group if pre_post==1, missing chi2 nofreq col
tabulate PDCge95 group if pre_post==1, missing chi2 nofreq col

log close
set more on

