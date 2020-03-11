cd "c:\3ie\data\endline\"
log using "append two to one.log", replace

***************************************
*APPEND ENDLINE DELIVERY DATES 
****************************************
*use first batch delivery dates (separate file)
clear
import excel "batch1\endline-patient-delivery-batch1 deidentified.xlsx", ///
  sheet("endline-patient-delivery") firstrow case(lower)clear
rename patientdeliverydate patientdelivery
drop if patientdelivery==.
keep baselinestudyid endlinestudyid patientdelivery
describe
di _N
* n=863
save first_batch_delivery, replace

* use second batch pt (delivery date in the pt file)
clear
import excel "batch2\endline-patient-batch2 deidentified.xlsx", ///
  sheet("endline-patient") firstrow case(lower)
drop if patientdelivery==.
keep baselinestudyid endlinestudyid patientdelivery
describe
di _N
* n=2700
append using first_batch_delivery
di _N
* n=3563

replace baselinestudyid="0" if baselinestudyid=="NONE"
destring baselinestudyid, gen(base_id)
rename endlinestudyid end_id 
format end_id %16.0f
format base_id %16.0f
duplicates drop (end_id), force
*n=28
sort end_id
*clean values before Aug 1 2013
gen double i=.
replace i=td(01aug2013)
*i=19,571
drop i
gen it=patientdelivery
sort it
replace patientdelivery=. if it<19571
drop it
save all_endline_delivery.dta, replace

***********************
*APPEND ENDLINE PATIENT FILES
***********************
* use first batch
clear
import excel "batch1\endline-patient-batch1 deidentified.xlsx", ///
  sheet("endline-patient") firstrow case(lower)
describe
di _N
*n=932
gen visittype="Endline-first batch"
save first_batch_pt, replace
* use second batch
clear
import excel "batch2\endline-patient-batch2 deidentified.xlsx", ///
  sheet("endline-patient") firstrow case(lower)
drop patientdelivery
gen visittype="Endline-second batch"
describe
di _N
* n=2700

*append
append using first_batch_pt
di _N
tab visittype, m

* define start of intervention
gen double i=. 
replace i=td(24jul2015)
list  i in  1/1
*date=20293 |
gen double start= 20293
format start %td

 * define end of intervention
gen end=dofc(endlinevisitdate)
replace i=td(01jan2012)
list  i in  1/1
*18 data collection dates are 01jan2012 in the first batch 
*replace them with most probable date of data collection
* date=18993 

replace i=td(09apr2016)
list  i in  1/1
*date=20553 |
replace end=20553 if end==18993
format end %td
tab visittype end, m

replace baselinestudyid="0" if baselinestudyid=="NONE"
destring baselinestudyid, gen(base_id)
rename endlinestudyid end_id 
format end_id %16.0f
format base_id %16.0f
duplicates drop
sort end_id
merge m:1 end_id using all_endline_delivery.dta, keepusing(patientdelivery)
*drop delivery dates without pt
drop if _merge == 2
drop _merge no i

* add facility variables
rename facilitycode fac_id
rename datacollectorid coll_id
merge m:1 fac_id using "3ie_fac.dta"
drop _merge

* drop duplicates
duplicates drop (base_id end_id fac_id), force 
duplicates tag (end_id), gen (tag)
tab tag
list  base_id end_id fac_id coll_id datestartart if tag==1
*6 duplicates new/exist; keep them and see later if the exist merge with baseline
drop tag
label var patienttype "differentiates existing from new pts"
label var visittype "differentiates baseline and two endline batches"
label var start "July 24th, 2015 (start of intervention)"
label var end "end of data collection (uses original endlinevisitdate)" 
drop baselinevisitdate endlinevisitdate baselinestudyid
order start end  group district facilityname patienttype visittype fac_id coll_id base_id end_id  datestartart patientdelivery
describe
di _N
*n=3613
save all_endline_pts.dta, replace

***********************
*APPEND ENDLINE VISIT FILES
***********************
*use first batch visits
clear  
import excel "batch1\endline-patient-visit-batch1 deidentified.xlsx", ///
 sheet("endline-patient-visit") firstrow case(lower)
describe
di _N
*n=7357
save first_batch_visits, replace
clear
import excel "batch2\endline-patient-visit-batch2 deidentified.xlsx", ///
 sheet("endline-patient-visit") firstrow case(lower)
describe
di _N
*n=21,508
append using first_batch_visits
di _N
*n=28865
rename endlinestudyid end_id 
format end_id %16.0f
drop no
duplicates drop (end_id visitdate nextvisitdate), force
save all_endline_visits.dta, replace
*erase temp files 
erase first_batch_delivery.dta
erase first_batch_pt.dta
erase first_batch_visits.dta
log close
