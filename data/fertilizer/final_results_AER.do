*10/4/2010;
*revised do file for final fertilizer results;

#delimit;
set more off;
clear;

*set directory in which to store the results;
global directory="results/AER_final";

********************;
*Table 1: percentage of farmers buying early;
********************;
use time_buying_fert_AER, clear;
sum used_tdfert_LR09;
sum bought_td_immed_postharv_LR09;
sum bought_td_immed_postharv_LR09 if used_tdfert_LR09==1;
sum always_used_TD;
sum always_bought_td_early;

************;
*Table 3;
************;
use SAFI_main_dataset_AER, clear;

gen incomeK_04=income_04/1000;

*Panel A: Season 1 treatments;
local depvars=8;
for var incomeK_04 educ_04 house_ever_anyfert_04 mud_walls_04 mud_floor_04 thatch_roof_04 bought_anyfert_LR04 anyfert_plus1_05 \ num 1/`depvars':
 global depvarY="X";

local i 1;
while `i' <= 8 {;

	local append_replace="append";
	if `i'==1 {;
		local append_replace="replace";
		};

	local restriction1="& (anyfert_plus1_05!=. | anyfert_plus2_05!=. | anyfert_plus3_05!=.)";
	local restriction2="if (anyfert_plus1_05!=. | anyfert_plus2_05!=. | anyfert_plus3_05!=.)";
	if "${depvar`i'}"=="bought_anyfert_LR04" {;
		local restriction1=" ";
		local restriction2=" ";
		};

	sum ${depvar`i'} if safi_lr04==1 `restriction1';
	local mean_safi_lr04=r(mean);
	local sd_safi_lr04=r(sd);
	local N_safi_lr04=r(N);

	sum ${depvar`i'} if safi_lr04==0 `restriction1';
	local mean_control=r(mean);
	local sd_control=r(sd);
	local N_control=r(N);

	if r(N)==0 {;
		local mean_control=999;
		local sd_control=999;
		local N_control=999;
		};

	reg ${depvar`i'} safi_lr04 `restriction2';

	outreg using ${directory}\\table3_panelA, se sigsymb(***,**,*) 10pct nolabel adec(3)
	 `append_replace' nonote bdec(3) addstat("mean for SAFI LR04", `mean_safi_lr04', "sd for SAFI LR04", `sd_safi_lr04', "obs for SAFI LR04", `N_safi_lr04',
	 "mean for control", `mean_control', "sd for control", `sd_control', "obs for control", `N_control');
	
	local i = `i' + 1;
	};

*Panel B: Season 2 treatments;
local depvars=8;
for var incomeK_04 educ_04 house_ever_anyfert_04 mud_walls_04 mud_floor_04 thatch_roof_04 bought_anyfert_SR04 anyfert_plus2_05 \ num 1/`depvars':
 global depvarY="X";

local i 1;
while `i' <= 8 {;

	local append_replace="append";
	if `i'==1 {;
		local append_replace="replace";
		};

	local restriction1="& (anyfert_plus1_05!=. | anyfert_plus2_05!=. | anyfert_plus3_05!=.)";
	local restriction2="if (anyfert_plus1_05!=. | anyfert_plus2_05!=. | anyfert_plus3_05!=.)";
	if "${depvar`i'}"=="bought_anyfert_SR04" {;
		local restriction1=" ";
		local restriction2=" ";
		};

	sum ${depvar`i'} if safi_sr04==1 `restriction1';
	local mean_safi_sr04=r(mean);
	local sd_safi_sr04=r(sd);
	local N_safi_sr04=r(N);

	sum ${depvar`i'} if choice==1 `restriction1';
	local mean_choice=r(mean);
	local sd_choice=r(sd);
	local N_choice=r(N);

	sum ${depvar`i'} if subsidy==1 `restriction1';
	local mean_subsidy=r(mean);
	local sd_subsidy=r(sd);
	local N_subsidy=r(N);

	sum ${depvar`i'} if fullprice==1 `restriction1';
	local mean_fullprice=r(mean);
	local sd_fullprice=r(sd);
	local N_fullprice=r(N);

	sum ${depvar`i'} if safi_sr04==0 & choice==0 & subsidy==0 & fullprice==0 `restriction1';
	local mean_control=r(mean);
	local sd_control=r(sd);
	local N_control=r(N);

	if r(N)==0 {;
		local mean_control=999;
		local sd_control=999;
		local N_control=999;
		};

	for any safi_sr04 choice subsidy fullprice \ num 1/4:
	 reg ${depvar`i'} X if (X==1 | (safi_sr04==0 & choice==0 & subsidy==0 & fullprice==0)) `restriction1' \

	outreg using "${directory}\\table3_panelB_Y", se sigsymb(***,**,*) 10pct nolabel adec(3)
	 `append_replace' nonote bdec(3) 
	 addstat("mean for SAFI SR04", `mean_safi_sr04', "sd for SAFI SR04", `sd_safi_sr04', "obs for SAFI SR04", `N_safi_sr04',
	 "mean for choice", `mean_choice', "sd for choice", `sd_choice', "obs for choice", `N_choice',
	 "mean for subsidy", `mean_subsidy', "sd for subsidy", `sd_subsidy', "obs for subsidy", `N_subsidy',
	 "mean for fullprice", `mean_fullprice', "sd for fullprice", `sd_fullprice', "obs for fullprice", `N_fullprice',
	 "mean for control", `mean_control', "sd for control", `sd_control', "obs for control", `N_control');
	
	local i = `i' + 1;
	};

****;
*p-values;
****;
reg bought_anyfert_SR04 safi_sr04 choice subsidy school1-school16;
*/;


************;
*Table 4;
************;
use SAFI_main_dataset_AER, clear;

gen incomeK_04=income_04/1000;

gen pure_comp=1 if safi_lr04==0 & safi_sr04==0 & choice==0 & fullprice==0 & subsidy==0 & buy==0 & buy_safi_sr04==0 & sbsk1==0 & sbsk1_demo==0 & demo==0;
egen has_full_controls=robs(house_ever_anyfert_05 gender_05 mud_walls_04 educ_04 incomeK_04 thatch_roof_04 mud_floor_04 thatch_roof_04 std5parent);
replace has_full_controls=0 if has_full_controls!=9;
replace has_full_controls=1 if has_full_controls==9;

gen comp_LR04=1 if sbsk1==0 & demo==0 & safi_lr04==0;
gen comp_SR04=1 if safi_sr04==0 & choice==0 & subsidy==0 & fullprice==0 & buy==0;

****;
*Panel A (Long Rains 2004);
****;

local i 1;
while `i' <= 3 {;

	local append_replace="append";
	if `i'==1 {;
		local append_replace="replace";
		};

	*no controls;
	sum anyfert_plus`i'_05 if comp_LR04==1 & house_ever_anyfert_05!=.;
	local season_control_mean=r(mean);
	local season_control_obs=r(N);
	sum anyfert_plus`i'_05 if pure_comp==1 & house_ever_anyfert_05!=.;
	local pure_control_mean=r(mean);
	local pure_control_obs=r(N);
	reg anyfert_plus`i'_05 safi_lr04 sbsk1 sbsk1_demo demo house_ever_anyfert_05 school1-school16;
	outreg safi_lr04 sbsk1 sbsk1_demo demo house_ever_anyfert_05 using "${directory}\\table4_panelA", se sigsymb(***,**,*) 10pct nolabel adec(3)
	 `append_replace' nonote bdec(3) addstat("pure control mean", `pure_control_mean', "pure control obs", `pure_control_obs',
	 "seasonal control mean", `season_control_mean', "seasonal control obs", `season_control_obs');


	*controls;
	sum anyfert_plus`i'_05 if comp_LR04==1 & house_ever_anyfert_05!=. & has_full_controls==1;
	local season_control_mean=r(mean);
	local season_control_obs=r(N);
	sum anyfert_plus`i'_05 if pure_comp==1 & house_ever_anyfert_05!=. & has_full_controls==1;
	local pure_control_mean=r(mean);
	local pure_control_obs=r(N);
	reg anyfert_plus`i'_05 safi_lr04 sbsk1 sbsk1_demo demo house_ever_anyfert_05 gender_05 mud_walls_04 educ_04 incomeK_04 thatch_roof_04 
	 mud_floor_04 thatch_roof_04 std5parent school1-school16;
	outreg safi_lr04 sbsk1 sbsk1_demo demo house_ever_anyfert_05 gender_05 mud_walls_04 educ_04 incomeK_04 thatch_roof_04 
	 mud_floor_04 thatch_roof_04 std5parent using "${directory}\\table4_panelA", se sigsymb(***,**,*) 10pct nolabel adec(3)
	 append nonote bdec(3) addstat("pure control mean", `pure_control_mean', "pure control obs", `pure_control_obs',
	 "seasonal control mean", `season_control_mean', "seasonal control obs", `season_control_obs');

	local i = `i' + 1;
	};

****;
*Panel B (Short Rains 2004);
****;

local i 1;
while `i' <= 3 {;

	local append_replace="append";
	if `i'==1 {;
		local append_replace="replace";
		};

	*no controls;
	sum anyfert_plus`i'_05 if pure_comp==1 & house_ever_anyfert_05!=.;
	local pure_control_mean=r(mean);
	local pure_control_obs=r(N);
	sum anyfert_plus`i'_05 if comp_SR04==1 & house_ever_anyfert_05!=.;
	local season_control_mean=r(mean);
	local season_control_obs=r(N);
	reg anyfert_plus`i'_05 safi_sr04 choice subsidy fullprice buy buy_safi_sr04 house_ever_anyfert_05 
	 safi_lr04 sbsk1 sbsk1_demo demo school1-school16;
	outreg safi_sr04 choice subsidy fullprice buy buy_safi_sr04 house_ever_anyfert_05 
	 using "${directory}\\table4_panelB", se sigsymb(***,**,*) 10pct nolabel adec(3)
	 `append_replace' nonote bdec(3) addstat("pure control mean", `pure_control_mean', "pure control obs", `pure_control_obs',
	 "seasonal control mean", `season_control_mean', "seasonal control obs", `season_control_obs');

	*controls;
	sum anyfert_plus`i'_05 if pure_comp==1 & house_ever_anyfert_05!=. & has_full_controls==1;
	local pure_control_mean=r(mean);
	local pure_control_obs=r(N);
	sum anyfert_plus`i'_05 if comp_SR04==1 & house_ever_anyfert_05!=. & has_full_controls==1;
	local season_control_mean=r(mean);
	local season_control_obs=r(N);
	reg anyfert_plus`i'_05 safi_sr04 choice subsidy fullprice buy buy_safi_sr04 house_ever_anyfert_05 
 	 gender_05 mud_walls_04 educ_04 incomeK_04 thatch_roof_04 mud_floor_04 thatch_roof_04 std5parent 
	 sbsk1 sbsk1_demo demo safi_lr04 school1-school16;
	outreg safi_sr04 choice subsidy fullprice buy buy_safi_sr04 house_ever_anyfert_05 
	 gender_05 mud_walls_04 educ_04 incomeK_04 thatch_roof_04 mud_floor_04 thatch_roof_04 std5parent
	 using "${directory}\\table4_panelB", se sigsymb(***,**,*) 10pct nolabel adec(3)
	 append nonote bdec(3) addstat("pure control mean", `pure_control_mean', "pure control obs", `pure_control_obs',
	 "seasonal control mean", `season_control_mean', "seasonal control obs", `season_control_obs');

	local i = `i' + 1;
	};

****;
*p-values;
****;
reg anyfert_plus2_05 safi_sr04 choice subsidy fullprice buy buy_safi_sr04 house_ever_anyfert_05 
 gender_05 mud_walls_04 educ_04 incomeK_04 thatch_roof_04 mud_floor_04 thatch_roof_04 std5parent 
 sbsk1 sbsk1_demo demo safi_lr04 school1-school16;
test fullprice=safi_sr04;
test fullprice=choice, accum;

reg anyfert_plus2_05 safi_sr04 choice subsidy fullprice buy buy_safi_sr04 house_ever_anyfert_05 
 std5parent 
 sbsk1 sbsk1_demo demo safi_lr04 school1-school16;
test fullprice=safi_sr04;
test fullprice=choice, accum;

****;
*Numbers for Calibration;
****;

*proportion using in all 3 seasons;
count if pure_comp==1 & anyfert_plus1_05!=. & anyfert_plus2_05!=. & anyfert_plus3_05!=.;
count if pure_comp==1 & anyfert_plus1_05==1 & anyfert_plus2_05==1 & anyfert_plus3_05==1;
count if pure_comp==1 & anyfert_plus1_05==0 & anyfert_plus2_05==0 & anyfert_plus3_05==0;

gen modified_comp=1 if safi_lr04==0 & safi_sr04==0 & sbsk1==0 & choice==0 & subsidy==0 & fullprice==0 & buy==0;
count if modified_comp==1 & anyfert_plus1_05!=. & anyfert_plus2_05!=. & anyfert_plus3_05!=.;
count if modified_comp==1 & anyfert_plus1_05==1 & anyfert_plus2_05==1 & anyfert_plus3_05==1;
count if modified_comp==1 & anyfert_plus1_05==0 & anyfert_plus2_05==0 & anyfert_plus3_05==0;

*all 3;
di 3/21;

*none of the 3;
di 12/21;
*/;


************;
*Table 6;
************;
use pilot_SAFI_AER, clear;
gen incomeK=income/1000;

for any 2 3 4 4b 5 6: 
 cap rename safiX_offer safi_offer_X \
  cap rename safiX_paid safi_paid_X \ 
  cap rename safiX_sample safi_sample_X \
  cap rename safiX_accept safi_accept_X;

reshape long safi_offer safi_paid safi_sample safi_accept, i(hid) j(year) string;
for any 2 3 4 4b 5 6: replace year="X" if year=="_X";
drop if safi_offer==0 | (safi_sample==0 & safi_offer==.);
drop safi3_eligible safi6*;
egen sum=robs( safi_sample safi_offer safi_accept safi_paid);
drop if sum==0;
drop sum;

*now or later: 3, 4, 5 (option 1), 6;
gen now_or_later_offer=safi_offer if year=="3" | year=="4" | (year=="5" & safi_offer==1) | year=="6";
gen now_or_later_accept=safi_accept if year=="3" | year=="4" | (year=="5" & safi_offer==1) | year=="6";
gen now_or_later_paid=safi_paid if year=="3" | year=="4" | (year=="5" & safi_offer==1) | year=="6";
gen take_it_or_leave_it=1 if year=="3" | year=="4" | (year=="5" & safi_offer==1) | year=="6";

*few days: 4b, 5 (option 2);
gen few_days_offer=safi_offer if year=="4b" | (year=="5" & safi_offer==2); 
gen few_days_accept=safi_accept if year=="4b" | (year=="5" & safi_offer==2); 
gen few_days_paid=safi_paid if year=="4b" | (year=="5" & safi_offer==2); 
gen few_days=1 if year=="4b" | (year=="5" & safi_offer==2); 

*few months: 2, 5 (option 3);
gen few_months_offer=safi_offer if year=="2" | (year=="5" & safi_offer==3); 
gen few_months_accept=safi_accept if year=="2" | (year=="5" & safi_offer==3); 
gen few_months_paid=safi_paid if year=="2" | (year=="5" & safi_offer==3); 
gen few_months=1 if year=="2" | (year=="5" & safi_offer==3); 

egen sum=rsum(take_it_or_leave_it few_days few_months);
for var take_it_or_leave_it few_days few_months: replace X=0 if X==. & sum==1;
drop sum;

*column 1 (accepted) - everybody, no controls;
reg safi_accept take_it_or_leave_it few_days few_months, nocons;
test take_it_or_leave_it=few_days;
local p12=r(p);
test take_it_or_leave_it=few_months;
local p13=r(p);
test few_days=few_months;
local p23=r(p);
outreg take_it_or_leave_it few_days few_months
 using "${directory}\\table6", se sigsymb(***,**,*) 10pct nolabel adec(3) replace nonote bdec(3) 
 addstat("test take it or leave it = few days", `p12', "test take it or leave it = few months", `p13', "test few days = few months", `p23');

*column 2 (accepted) - everybody, controls;
reg safi_accept take_it_or_leave_it few_days few_months house_ever_anyfert educ, nocons;
test take_it_or_leave_it=few_days;
local p12=r(p);
test take_it_or_leave_it=few_months;
local p13=r(p);
test few_days=few_months;
local p23=r(p);
outreg take_it_or_leave_it few_days few_months house_ever_anyfert educ
 using "${directory}\\table6", se sigsymb(***,**,*) 10pct nolabel adec(3) append nonote bdec(3) 
 addstat("test take it or leave it = few days", `p12', "test take it or leave it = few months", `p13', "test few days = few months", `p23');

*column 3 (bought) - everybody, no controls;
reg safi_paid take_it_or_leave_it few_days few_months, nocons;
test take_it_or_leave_it=few_days;
local p12=r(p);
test take_it_or_leave_it=few_months;
local p13=r(p);
test few_days=few_months;
local p23=r(p);
outreg take_it_or_leave_it few_days few_months
 using "${directory}\\table6", se sigsymb(***,**,*) 10pct nolabel adec(3) append nonote bdec(3) 
 addstat("test take it or leave it = few days", `p12', "test take it or leave it = few months", `p13', "test few days = few months", `p23');

*column 4 (bought) - everybody, controls;
reg safi_paid take_it_or_leave_it few_days few_months house_ever_anyfert educ, nocons;
test take_it_or_leave_it=few_days;
local p12=r(p);
test take_it_or_leave_it=few_months;
local p13=r(p);
test few_days=few_months;
local p23=r(p);
outreg take_it_or_leave_it few_days few_months house_ever_anyfert educ
 using "${directory}\\table6", se sigsymb(***,**,*) 10pct nolabel adec(3) append nonote bdec(3) 
 addstat("test take it or leave it = few days", `p12', "test take it or leave it = few months", `p13', "test few days = few months", `p23');

*column 5 (accepted) - pilot 5, no controls;
reg safi_accept take_it_or_leave_it few_days few_months if year=="5", nocons;
test take_it_or_leave_it=few_days;
local p12=r(p);
test take_it_or_leave_it=few_months;
local p13=r(p);
test few_days=few_months;
local p23=r(p);
outreg take_it_or_leave_it few_days few_months
 using "${directory}\\table6", se sigsymb(***,**,*) 10pct nolabel adec(3) append nonote bdec(3) 
 addstat("test take it or leave it = few days", `p12', "test take it or leave it = few months", `p13', "test few days = few months", `p23');

*column 6 (accepted) - pilot 5, controls;
reg safi_accept take_it_or_leave_it few_days few_months house_ever_anyfert educ if year=="5", nocons;
test take_it_or_leave_it=few_days;
local p12=r(p);
test take_it_or_leave_it=few_months;
local p13=r(p);
test few_days=few_months;
local p23=r(p);
outreg take_it_or_leave_it few_days few_months house_ever_anyfert educ
 using "${directory}\\table6", se sigsymb(***,**,*) 10pct nolabel adec(3) append nonote bdec(3) 
 addstat("test take it or leave it = few days", `p12', "test take it or leave it = few months", `p13', "test few days = few months", `p23');

*column 7 (bought) - pilot 5, no controls;
reg safi_paid take_it_or_leave_it few_days few_months if year=="5", nocons;
test take_it_or_leave_it=few_days;
local p12=r(p);
test take_it_or_leave_it=few_months;
local p13=r(p);
test few_days=few_months;
local p23=r(p);
outreg take_it_or_leave_it few_days few_months
 using "${directory}\\table6", se sigsymb(***,**,*) 10pct nolabel adec(3) append nonote bdec(3) 
 addstat("test take it or leave it = few days", `p12', "test take it or leave it = few months", `p13', "test few days = few months", `p23');

*column 8 (bought) - pilot 5, controls;
reg safi_paid take_it_or_leave_it few_days few_months house_ever_anyfert educ if year=="5", nocons;
test take_it_or_leave_it=few_days;
local p12=r(p);
test take_it_or_leave_it=few_months;
local p13=r(p);
test few_days=few_months;
local p23=r(p);
outreg take_it_or_leave_it few_days few_months house_ever_anyfert educ
 using "${directory}\\table6", se sigsymb(***,**,*) 10pct nolabel adec(3) append nonote bdec(3) 
 addstat("test take it or leave it = few days", `p12', "test take it or leave it = few months", `p13', "test few days = few months", `p23');

************;
*Table A4 - checking randomization for pilot SAFI;
************;

for var house_ever_anyfert educ mud_walls mud_floor thatch_roof incomeK kids land_main \ num 1/8: global depvarY="X";

local i 1;
while `i' <= 8 {;

	local append_replace="append";
	if `i'==1 {;
		local append_replace="replace";
		};

	reg ${depvar`i'} take_it_or_leave_it few_days few_months school1-school20, nocons;
	test take_it_or_leave_it=few_days;
	local p12=r(p);
	test take_it_or_leave_it=few_months;
	local p13=r(p);
	test few_days=few_months;
	local p23=r(p);

	sum ${depvar`i'} if take_it_or_leave_it==1;
	local mean1=r(mean);
	local sd1=r(sd);
	sum ${depvar`i'} if few_days==1;
	local mean2=r(mean);
	local sd2=r(sd);
	sum ${depvar`i'} if few_months==1;
	local mean3=r(mean);
	local sd3=r(sd);

	outreg take_it_or_leave_it few_days few_months 
	 using "${directory}\\tableA4", se sigsymb(" ", " ", " ") nolabel adec(3) `append_replace' nonote bdec(3) 
	 addstat("test take it or leave it = few days", `p12', "test take it or leave it = few months", `p13', "test few days = few months", `p23',
 	 "mean take it or leave it", `mean1', "sd take it or leave it", `sd1', 
	 "mean few days", `mean2', "sd few days", `sd2', 
	 "mean few months", `mean3', "sd few months", `sd3');
	local i = `i' + 1;	
	}; 
*/;


************;
*Table 7;
************;
use SAFI_main_dataset_AER, clear;

gen incomeK_04=income_04/1000;

local depvars=3;
for any remind_bought_ftd remind_plan_ftd remind_planorbuy_ftd \ num 1/`depvars':
 global depvarY="X";

local i 1;
while `i' <= 3 {;

	local append_replace="append";
	if `i'==1 {;
		local append_replace="replace";
		};

	*no controls;
	sum ${depvar`i'} if reminder==0;
	local mean=r(mean);
	local N=r(N);
	reg ${depvar`i'} reminder safi_lr04 safi_sr04 subsidy fullprice choice buy buy_safi_sr04 sbsk1 sbsk1_demo demo school1-school16;
	outreg reminder 
	 using "${directory}\\table7", se sigsymb(***,**,*) 10pct nolabel adec(3) `append_replace' nonote bdec(3) 
	 addstat("mean usage among reminder control group", `mean', "N among reminder control group", `N');

	*control for previous usage;
	sum ${depvar`i'} if reminder==0 & house_ever_anyfert_05!=.;
	local mean=r(mean);
	local N=r(N);
	reg ${depvar`i'} reminder house_ever_anyfert_05 safi_lr04 safi_sr04 subsidy fullprice choice buy buy_safi_sr04 sbsk1 sbsk1_demo demo school1-school16;
	outreg reminder house_ever_anyfert_05
	 using "${directory}\\table7", se sigsymb(***,**,*) 10pct nolabel adec(3) append nonote bdec(3) 
	 addstat("mean usage among reminder control group", `mean', "N among reminder control group", `N');

	*control for other things;
	sum ${depvar`i'} if reminder==0 & house_ever_anyfert_05!=. & gender_05!=. & mud_walls_04!=. & educ_04!=. & incomeK_04!=.;
	local mean=r(mean);
	local N=r(N);
	reg ${depvar`i'} reminder house_ever_anyfert_05 gender_05 mud_walls_04 educ_04 incomeK_04
 	 safi_lr04 safi_sr04 subsidy fullprice choice buy buy_safi_sr04 sbsk1 sbsk1_demo demo school1-school16;
	outreg reminder house_ever_anyfert_05 gender_05 mud_walls_04 educ_04 incomeK_04
	 using "${directory}\\table7", se sigsymb(***,**,*) 10pct nolabel adec(3) append nonote bdec(3) 
	 addstat("mean usage among reminder control group", `mean', "N among reminder control group", `N');


	local i = `i' + 1;

	};
*/;

********************;
*numbers for Figure 1;
********************;

egen in04=robs(income_04 educ_04 house_ever_anyfert_04 thatch_roof_04	mud_walls_04 mud_floor_04 own_land_04 wives_04 father_wives_04 sibs_04);
replace in04=1 if in04>0 & in04!=.;

count if safi_sr04==1 & buy==1 & in04==1;
count if safi_sr04==1 & buy==0 & in04==1;

count if choice==1 & buy==1 & in04==1;
count if choice==1 & buy==0 & in04==1;

count if subsidy==1 & buy==1 & in04==1;
count if subsidy==1 & buy==0 & in04==1;

count if fullprice==1 & buy==1 & in04==1;
count if fullprice==1 & buy==0 & in04==1;

count if (safi_sr04==0 & choice==0 & subsidy==0 & fullprice==0) & buy==1 & in04==1;
count if (safi_sr04==0 & choice==0 & subsidy==0 & fullprice==0) & buy==0 & in04==1;

********************;
*Table A3: attrition from sbsk1;
********************;

*never appeared in the dataset from sample list;
use SAFI_main_dataset_AER, clear;

*drop friends;
drop if strpos(hid, "-");

egen has_quest_04=robs(educ_04-gender_04 father_wives_04-kids_04);
replace has_quest_04=1 if has_quest_04>1 & has_quest_04!=.;

gen has_quest_05=1 if anyfert_plus1_05!=. | anyfert_plus2_05!=. | anyfert_plus3_05!=.;
replace has_quest_05=0 if anyfert_plus1_05==. & anyfert_plus2_05==. & anyfert_plus3_05==.;

gen has_quest_05_in_04=has_quest_05 if has_quest_04==1;

*include interactions between the demonstration plot and the treatments, since the farmers in the demo plot schools knew us so takeup;
*could be different between the demo and non-demo schools;
for var safi_lr04 safi_sr04 choice subsidy fullprice: gen demo_X=demo*X;

for any has_quest_04 has_quest_05 has_quest_05_in_04 \ num 1/3:
 global depvarY="X";

local i 1;
while `i' <= 3 {;

	local append_replace="append";
	if `i'==1 {;
		local append_replace="replace";
		};

	sum ${depvar`i'};
	local mean=r(mean);
	reg ${depvar`i'} sbsk1 demo sbsk1_demo safi_lr04 safi_sr04 choice subsidy fullprice buy 
 	 demo_safi_lr04 demo_safi_sr04 demo_choice demo_subsidy demo_fullprice
 	 school1-school16;
	quietly outreg sbsk1 demo sbsk1_demo safi_lr04 safi_sr04 choice subsidy fullprice buy 
 	 demo_safi_lr04 demo_safi_sr04 demo_choice demo_subsidy demo_fullprice
 	 using "${directory}\\tableA3", se sigsymb(***,**,*) 10pct nolabel 
 	 `append_replace' nonote bdec(3) addstat("mean response rate", `mean') adec(3);

	local i = `i' + 1;
	};
*/;


*************;
*OTHER CALCULATIONS;
*************;

********************;
*what happened to fertilizer used through SAFI?;
********************;
use SAFI_main_dataset_AER, clear;

*codes:
1 - gave away, sold it
2 - lost it
3 - stolen
4 - spoiled
5 - used on different crop
6 - kept for another season
7 - used on another plot
8 - used on head of household's plot
9 - other;

tab safiLR04_what_05 if bought_anyfert_LR04==1 & safi_lr04==1;
tab safiSR04_what_05 if bought_anyfert_SR04==1 & safi_sr04==1; 

*used on own plot;
di (54+41)/(63+61);

*spoiled;
di (1+1)/(63+61);

*used on another plot;
di (3+6)/(63+61);

*used for another season;
di (1+9)/(63+61);

*used on different crop;
di (2+4)/(63+61);

*other;
di 2/(63+61);


********************;
*choice of date of return;
********************;
tab choice_return;
*1-harvest
*2-planting
*3-TD 
*4-refused;

*early;
tab bought_anyfert_SR04 if choice_return==1;
ci bought_anyfert_SR04 if choice_return==1;

*late;
tab bought_anyfert_SR04 if choice_return==2 | choice_return==3;
ci bought_anyfert_SR04 if choice_return==2 | choice_return==3;


********************;
*quantity bought through SAFI;
********************;
egen total_kg_bought_SR04=rsum(bought_DAP_kg_SR04 bought_CAN_kg_SR04);
egen total_kg_bought_LR04=rsum(bought_DAP_kg_LR04 bought_CAN_kg_LR04);
sum total_kg_bought_SR04 if (safi_sr04==1 | choice==1) & total_kg_bought_SR04!=0, detail;
sum total_kg_bought_LR04 if safi_lr04==1 & total_kg_bought_LR04!=0, detail;;
di (164*4.11+74*2.74)/(164+74);

sum bought_total_ksh_SR04 if (safi_sr04==1 | choice==1) & total_kg_bought_SR04!=0 & bought_total_ksh_SR04!=0;
sum bought_total_ksh_LR04  if safi_lr04==1 & total_kg_bought_LR04!=0 & bought_total_ksh_LR04!=0;
di (162*153.81+72*91.875)/(72+162)/70;

sum qtyfert_plus1 if qtyfert_plus1!=0;

********************;
*% sampled to sell maize who actually did;
********************;
sum sold_maize_harv_SR04 if buy==1;


********************;
*paying cash vs. maize;
********************;
count if bought_anyfert_LR04==1;
count if bought_anyfert_LR04==1 & 
 ((sold_maize_gg_LR04!=0 & sold_maize_ksh_LR04!=.) | (sold_maize_ksh_LR04!=0 & sold_maize_ksh_LR04!=.));

count if bought_anyfert_SR04==1;
count if bought_anyfert_SR04==1 & 
 ((sold_maize_gg_SR04!=0 & sold_maize_ksh_SR04!=.) | (sold_maize_ksh_SR04!=0 & sold_maize_ksh_SR04!=.));

di (19+106)/(74+260);


********************;
*plans and the percentage that followed through;
********************;
use pilot_SAFI_AER, clear;

sum plan_anyfert_plus1;
tab plan_anyfert_plus1 anyfert_plus1, cell;
sum anyfert_plus1 if plan_anyfert_plus1==1;


********************;
*self-reported reasons for not using fertilizer;
********************;
/*;
*codes:
A-don't know how to use it
B-Fertilizer doesn't work
C-It works, but isn't profitable
D-I won't have money
E-I will never have enough money
F-other
*/;

tab fert_why_not;


