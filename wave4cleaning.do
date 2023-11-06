
clear
global Nigeria_GHS_W4_raw_data			"C:\Users\obine\OneDrive\Documents\wave4stata"
*global Nigeria_GHS_W4_created_data 		"${directory}/Nigeria GHS/Nigeria GHS Wave 4/Final DTA Files/created_data"
*global Nigeria_GHS_W4_final_data  		"${directory}/Nigeria GHS/Nigeria GHS Wave 4/Final DTA Files/final_data"

//WHO iGrowUp file path
*global dofilefold "//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/335 - Ag Team Data Support/Various Requests/WHO Child Malnutrition Macro/igrowup_update-master"

*DYA.11.1.2020 Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global Nigeria_GHS_W4_pop_tot 198387623
global Nigeria_GHS_W4_pop_rur 98511358
global Nigeria_GHS_W4_pop_urb 99876265

global drop_unmeas_plots 1 //If not 0, this variable will result in all plots not measured by GPS to be dropped; the implied conversion rates between nonstandard units and hectares (based on households with both measured and reported areas) appear to have changed substantially since Wave 3 and have resulted in some large yield estimates because the plots are very small. Easiest fix is to remove them.
********************************************************************************
*EXCHANGE RATE AND INFLATION FOR CONVERSION IN USD
********************************************************************************
global Nigeria_GHS_W4_exchange_rate 199.04975		// https://www.bloomberg.com/quote/USDETB:CURR
global Nigeria_GHS_W4_gdp_ppp_dollar 115.9778	// https://data.worldbank.org/indicator/PA.NUS.PPP
global Nigeria_GHS_W4_cons_ppp_dollar 112.0983276		// https://data.worldbank.org/indicator/PA.NUS.PRVT.P
global Nigeria_GHS_W4_infl_adj = 1.249 //267.5/214.2
	
global Nigeria_GHS_W4_pound_exchange 476.5
global Nigeria_GHS_W4_euro_exchange 418.7
	
	
//Poverty threshold calculation - It's probably easier to do up here than at the end of the code for ease of transparency and adjustability
//Per W3, we convert WB's international poverty threshold to 2011$ using the PA.NUS.PRVT.PP WB info then inflate to the last year of the survey using CPI
global Nigeria_GHS_W4_poverty_threshold (1.90*79.531*(1+(267.512-110.84)/110.84)) //~365 N
global Nigeria_GHS_W4_poverty_nbs 376.52 //ALT 06.18.2020: Nigeria's NBS defines poverty as living below 376 N/day. Included for comparison purposes.
global Nigeria_GHS_W4_poverty_215 2.15*$Nigeria_GHS_W4_infl_adj * $Nigeria_GHS_W4_cons_ppp_dollar  //New 2023 WB poverty threshold, works out to 273 N - a substantial drop largely because inflation was about 100% between 2011 and 2017

//These values from Bai, Y., et al. (2021) Cost and affordability of nutritious diets at retail prices: Evidence from 177 countries. Food Policy 99. doi:https://doi.org/10.1016/j.foodpol.2020.101983
//CoCA is cost of a calorically adequate diet in PPP$ (minimum number of calories needed for survival); CoNA is cost of a nutritionally adequate diet, i.e., the minimum expenditure required to get RDIs of macro and micronutrients. 
global Nigeria_GHS_W4_CoCA_diet 134.21 * 0.63 //2019 PPP$ 
global Nigeria_GHS_W4_CoNA_diet 134.21 * 1.24
********************************************************************************
*THRESHOLDS FOR WINSORIZATION
********************************************************************************
global wins_lower_thres 1    						//  Threshold for winzorization at the bottom of the distribution of continous variables
global wins_upper_thres 99							//  Threshold for winzorization at the top of the distribution of continous variables


********************************************************************************
*GLOBALS OF PRIORITY CROPS //change these globals if you are interested in different crops
********************************************************************************
////Limit crop names in variables to 6 characters or the variable names will be too long! 
global topcropname_area "maize rice sorgum millet cowpea grdnt yam swtptt cassav banana cocoa soy" //no wheat or beans		
global topcrop_area     "1080, 1110, 1070, 1100, 1010, 1060, 1120, 2181, 1020, 2030, 3040, 2220" //ALT 12.09.19: As of W3, Yam was in categories 1120-1124 (yam, white yam, yellow yam, water yam, and three-leaved yam). For W4, yam is now only in categories 1121-1124, we have to decide how to collapse these. All four yams are in the genus Dioscorea and white yam and yellow yam are now considered different cultivars of the same species; another common species in cultivation (although less so in Nigeria) is Chinese yam, which doesn't have a category and may have historically wound up in 1120. Given this, I recode all 1121-1124 as 1120 (this will produce slightly different results than we did in W3)
global comma_topcrop_area "1080, 1110, 1070, 1100, 1010, 1060, 1120, 2181, 1020, 2030, 3040, 2220" 
global topcropname_area_full "maize rice sorghum millet cowpea grdnt yam swtptt cassav banana cocoa soy"
global nb_topcrops : list sizeof global(topcropname_area) // Gets the current length of the global macro list "topcropname_area" 
set obs $nb_topcrops 
egen rnum = seq(), f(1) t($nb_topcrops)
gen crop_code = .
gen crop_name = ""
forvalues k=1(1)$nb_topcrops {
	local c : word `k' of $topcrop_area
	local cn : word `k' of $topcropname_area	
	if rnum==`k' replace crop_code = `c' 
    if rnum==`k' replace crop_name = "`cn'"  
} 

forvalues k=2(2)$nb_topcrops {
	local c : word `k' of $topcrop_area
	local cn : word `k' of $topcropname_area	
	if rnum==`k' replace crop_code = `c' 
    if rnum==`k' replace crop_name = "`cn'"  
} 

drop rnum
save cropnametable, replace



















































*WEIGHT

use "C:\Users\obine\OneDrive\Documents\wave4stata\secta_plantingw4.dta" , clear
gen rural = (sector==2)
lab var rural "1= Rural"
keep hhid zone state lga ea wt_wave4 rural
ren wt_wave4 weight
*DYA.11.21.2020 household not survey will not have weights
drop if weight==.  //287 hh as expected
count // 4,976 obs as expected
save  weight, replace




*Households

use "C:\Users\obine\OneDrive\Documents\wave4stata\secta_plantingw4.dta" , clear
gen rural = (sector==2)
lab var rural "1= Rural"
keep hhid zone state lga ea wt_wave4 rural
ren wt_wave4 weight
duplicates report hhid
merge 1:1 hhid using  weight, keep(2 3) nogen  // keeping hh surveyed
save household, replace




*Individual

use "C:\Users\obine\OneDrive\Documents\wave4stata\sect1_plantingw4.dta" , clear
gen member = s1q4
replace member = 1 if s1q3 != .
keep hhid indiv s1q2 s1q6 
gen female= s1q2==2
la var female "1= individual is female"
ren s1q6 age
la var age "Individual age"
merge m:1 hhid using  household, keep(2 3) nogen  // keeping hh surveyed
save individual, replace


*Household size

use "C:\Users\obine\OneDrive\Documents\wave4stata\sect1_plantingw4.dta", clear
*drop if s1q4==2 // DYA 5.11.2023  drop individuals no longer in the households  
drop if s1q4==2 // DYA 5.11.2023  drop individuals no longer in the households. This variale s1q4 is only relevant for the panel hh
gen hh_members = 1 /*if s1q4==1*/
replace hh_members = 1 if s1q3 != .
keep if hh_members==1 //Drop individuals who've left household
ren s1q2 gender
gen fhh = s1q3==1 & gender==2
collapse (sum) hh_members (max) fhh, by (hhid)
lab var hh_members "Number of household members"
lab var fhh "1= Female-headed household"
*DYA.11.1.2020 Re-scaling survey weights to match population estimates
merge 1:1 hhid using household, nogen keep(2 3)
*Adjust to match total population
total hh_members [pweight=weight]
matrix temp =e(b)
gen weight_pop_tot=weight*${Nigeria_GHS_W4_pop_tot}/el(temp,1,1)
total hh_members [pweight=weight_pop_tot]
lab var weight_pop_tot "Survey weight - adjusted to match total population"
*Adjust to match total population but also rural and urban
total hh_members [pweight=weight] if rural==1
matrix temp =e(b)
gen weight_pop_rur=weight*${Nigeria_GHS_W4_pop_rur}/el(temp,1,1) if rural==1
total hh_members [pweight=weight_pop_tot]  if rural==1

total hh_members [pweight=weight] if rural==0
matrix temp =e(b)
gen weight_pop_urb=weight*${Nigeria_GHS_W4_pop_urb}/el(temp,1,1) if rural==0
total hh_members [pweight=weight_pop_urb]  if rural==0

egen weight_pop_rururb=rowtotal(weight_pop_rur weight_pop_urb)
total hh_members [pweight=weight_pop_rururb]  
lab var weight_pop_rururb "Survey weight - adjusted to match rural and urban population"
drop weight_pop_rur weight_pop_urb
save householdsize, replace

merge 1:1 hhid using weight, nogen
save weight, replace


********************************************************************************
*HEAD OF HOUSEHOLD *
********************************************************************************
*Creating HOH gender
use "C:\Users\obine\OneDrive\Documents\wave4stata\sect1_plantingw4.dta", clear
merge m:1 hhid using household, nogen keep(2 3)
gen male_head = 0
replace male_head =1 if s1q3 & s1q2==1
collapse (max) male_head, by(hhid)
la var male_head "HH is male headed, 1=yes"	
save malehead, replace

********************************************************************************
*GPS COORDINATES *
********************************************************************************
use "C:\Users\obine\OneDrive\Documents\wave4stata\nga_householdgeovars_y4.dta", clear
merge 1:1 hhid using household, nogen keep(3) 
ren lat_dd_mod latitude
ren lon_dd_mod longitude
keep lga ea latitude longitude
duplicates drop lga ea latitude longitude, force //ea+lga necessary to uniquely identify ea
gen GPS_level = "ea"
save gpscord, replace




********************************************************************************
* PLOT AREAS *
********************************************************************************
*starting with planting
//ALT IMPORTANT NOTE: As of W4, the implied area conversions for farmer estimated units (including hectares) are markedly different from previous waves. I recommend excluding plots that do not have GPS measured areas from any area-based productivity estimates.
use "C:\Users\obine\OneDrive\Documents\wave4stata\sect11a1_plantingw4.dta", clear
*merging in planting section to get cultivated status
merge 1:1 hhid plotid using "C:\Users\obine\OneDrive\Documents\wave4stata\sect11b1_plantingw4.dta", nogen
*merging in harvest section to get areas for new plots
merge 1:1 hhid plotid using "C:\Users\obine\OneDrive\Documents\wave4stata\secta1_harvestw4.dta", gen(plot_merge)
merge m:1 hhid using household, nogen keep( 3)
ren s11aq4aa area_size
ren s11aq4b area_unit
ren sa1q11 area_size2 //GPS measurement, no units in file
//ren sa1q9b area_unit2 //Not in file
ren s11aq4c area_meas_sqm
//ren sa1q9c area_meas_sqm2
gen cultivate = s11b1q27 ==1 
*assuming new plots are cultivated
//replace cultivate = 1 if sa1q1aa==1
//replace cultivate = 1 if sa1q3==1 //ALT: This has changed to respondent ID for w4
*using conversion factors from LSMS-ISA Nigeria Wave 2 Basic Information Document (Wave 3 unavailable, but Waves 1 & 2 are identical) 
*found at http://econ.worldbank.org/WBSITE/EXTERNAL/EXTDEC/EXTRESEARCH/EXTLSMS/0,,contentMDK:23635560~pagePK:64168445~piPK:64168309~theSitePK:3358997,00.html
*General Conversion Factors to Hectares
//		Zone   Unit         Conversion Factor
//		All    Plots        0.0667
//		All    Acres        0.4
//		All    Hectares     1
//		All    Sq Meters    0.0001

*Zone Specific Conversion Factors to Hectares
//		Zone           Conversion Factor
//				 Heaps      Ridges      Stands
//		1 		 0.00012 	0.0027 		0.00006
//		2 		 0.00016 	0.004 		0.00016
//		3 		 0.00011 	0.00494 	0.00004
//		4 		 0.00019 	0.0023 		0.00004
//		5 		 0.00021 	0.0023 		0.00013
//		6  		 0.00012 	0.00001 	0.00041

//ALT observed from the data
//		Zone           Conversion Factor
//				 Heaps      Ridges      Stands
//		1 		 0.00281 	0.0059 		0.00121
//		2 		 0.00748 	0.0052 		0.0006
//		3 		 0.00787 	0.0051	 	0.0002
//		4 		 0.00003 	0.0010 		0.0003
//		5 		 0.00076 	0.0008 		0.009
//		6  		 0.00437 	0.0005	 	0.002

*farmer reported field size for post-planting
gen field_size= area_size if area_unit==6
replace field_size = area_size*0.0667 if area_unit==4									//reported in plots
replace field_size = area_size*0.404686 if area_unit==5		    						//reported in acres
replace field_size = area_size*0.0001 if area_unit==7									//reported in square meters

replace field_size = area_size*0.00012 if area_unit==1 & zone==1						//reported in heaps
replace field_size = area_size*0.00016 if area_unit==1 & zone==2
replace field_size = area_size*0.00011 if area_unit==1 & zone==3
replace field_size = area_size*0.00019 if area_unit==1 & zone==4
replace field_size = area_size*0.00021 if area_unit==1 & zone==5
replace field_size = area_size*0.00012 if area_unit==1 & zone==6

replace field_size = area_size*0.0027 if area_unit==2 & zone==1							//reported in ridges
replace field_size = area_size*0.004 if area_unit==2 & zone==2
replace field_size = area_size*0.00494 if area_unit==2 & zone==3
replace field_size = area_size*0.0023 if area_unit==2 & zone==4
replace field_size = area_size*0.0023 if area_unit==2 & zone==5
replace field_size = area_size*0.00001 if area_unit==2 & zone==6

replace field_size = area_size*0.00006 if area_unit==3 & zone==1						//reported in stands
replace field_size = area_size*0.00016 if area_unit==3 & zone==2
replace field_size = area_size*0.00004 if area_unit==3 & zone==3
replace field_size = area_size*0.00004 if area_unit==3 & zone==4
replace field_size = area_size*0.00013 if area_unit==3 & zone==5
replace field_size = area_size*0.00041 if area_unit==3 & zone==6

/*ALT 02.23.23*/ gen area_est = field_size
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm*0.0001 if area_meas_sqm!=.               				
gen gps_meas = (area_meas_sqm!=.)
la var gps_meas "Plot was measured with GPS, 1=Yes"
ren plotid plot_id
if $drop_unmeas_plots !=0 {
	drop if gps_meas == 0
}
save plotarea, replace


********************************************************************************
* PLOT DECISION MAKERS *
********************************************************************************
*Creating gender variables for plot manager from post-planting
use "C:\Users\obine\OneDrive\Documents\wave4stata\sect1_plantingw4.dta", clear
merge m:1 hhid using household, nogen keep( 3)
gen female = s1q2==2 if s1q2!=.
gen age = s1q6
*dropping duplicates (data is at holder level so some individuals are listed multiple times, we only need one record for each) //ALT: No duplicates in this wave
duplicates drop hhid indiv, force
save gendermergetemp, replace

*adding in gender variables for plot manager from post-harvest
use "C:\Users\obine\OneDrive\Documents\wave4stata\sect1_harvestw4.dta", clear
merge m:1 hhid using household, nogen keep( 3)
gen female = s1q2==2 if s1q2!=.
gen age = s1q4
duplicates drop hhid indiv, force
merge 1:1 hhid indiv using gendermergetemp, nogen 		
keep hhid indiv female age
save gendermergetemp, replace

*Using planting data 	
use "C:\Users\obine\OneDrive\Documents\wave4stata\plotarea.dta", clear 	
//Post-Planting
*First manager 
gen indiv = s11aq6a
merge m:1 hhid indiv using gendermergetemp, gen(dm1_merge) keep(1 3) 
gen dm1_female = female if s11aq6a!=.
drop indiv 
*Second manager 
gen indiv = s11aq6b
merge m:1 hhid indiv using gendermergetemp, gen(dm2_merge) keep(1 3)			
gen dm2_female = female & s11aq6b!=.
drop indiv 
//Post-Harvest (only reported for "new" plot)
*First manager 
gen indiv = sa1q2 
merge m:1 hhid indiv using gendermergetemp, gen(dm4_merge) keep(1 3)			
gen dm3_female = female & sa1q2!=.
drop indiv 
*Second manager 
gen indiv = sa1q2c_1
merge m:1 hhid indiv using gendermergetemp, gen(dm5_merge) keep(1 3)			
gen dm4_female = female & sa1q2c_1!=.
drop indiv 
*Replace PP with PH if missing
replace dm1_female=dm3_female if dm1_female==.
replace dm2_female=dm4_female if dm1_female==.
*Constructing three-part gendered decision-maker variable; male only (=1) female only (=2) or mixed (=3)
gen dm_gender = 1 if (dm1_female==0 | dm1_female==.) & (dm2_female==0 | dm2_female==.) & !(dm1_female==. & dm2_female==.)
replace dm_gender = 2 if (dm1_female==1 | dm1_female==.) & (dm2_female==1 | dm2_female==.) & !(dm1_female==. & dm2_female==.)
replace dm_gender = 3 if dm_gender==. & !(dm1_female==. & dm2_female==.)
la def dm_gender 1 "Male only" 2 "Female only" 3 "Mixed gender"
*replacing observations without gender of plot manager with gender of HOH
merge m:1 hhid using householdsize, nogen keep(1 3)
replace dm_gender=1 if fhh ==0 & dm_gender==. //0 changes
replace dm_gender=2 if fhh ==1 & dm_gender==. //0 changes
gen dm_male = dm_gender==1
gen dm_female = dm_gender==2
gen dm_mixed = dm_gender==3
keep field_size plot_id hhid dm_* fhh 
save plotdecisionmakers, replace




********************************************************************************
*Formalized Land Rights*
********************************************************************************
use "C:\Users\obine\OneDrive\Documents\wave4stata\sect11b1_plantingw4.dta", clear
//gen formal_land_rights = s11b1q8>=1 & s11b1q8b!= "NO NEED"	//ALT: For W4, this question was broken out into a bunch of yes/no questions for each type of instrument going with 7, "do you have a title"
*gen formal_land_rights = s11b1q7==1

*DYA.11.21.2020 Seems like we should be able to use the variable s11b1q8_ in this wave like in the previouis to maintain the comparability
gen formal_land_rights = (s11b1q8_1==1 | s11b1q8_2==1 | s11b1q8_3==1 | s11b1q8_5==1) | s11b1q9a==1

//drop if formal_land_rights==. //ALT 03.20.2020: Drop empties?
//ALT: This q was in w4 with up to 32 possible title holders across 4 categories. I'm redoing it with reshape because otherwise we'd be here all day.
ren s11b1q8b4_1 indiv1
ren s11b1q8b4_2 indiv2
ren s11b1q8b4_3 indiv3
ren s11b1q8b4_4 indiv4
ren s11b1q8b4_5 indiv5
ren s11b1q8b4_6 indiv6
ren s11b1q8b4_7 indiv7
ren s11b1q8b2_1 indiv8
ren s11b1q8b2_2 indiv9
ren s11b1q8b2_3 indiv10
ren s11b1q8b2_4 indiv11
ren s11b1q8b2_5 indiv12
ren s11b1q8b2_6 indiv13
ren s11b1q8b3_1 indiv14
ren s11b1q8b3_2 indiv15
ren s11b1q8b3_3 indiv16
ren s11b1q8b3_4 indiv17
ren s11b1q8b3_5 indiv18
ren s11b1q8b3_6 indiv19
ren s11b1q8b1_1 indiv20
ren s11b1q8b1_2 indiv21
ren s11b1q8b1_3 indiv22
ren s11b1q8b1_4 indiv23
ren s11b1q8b1_5 indiv24
ren s11b1q8b1_6 indiv25
ren s11b1q8b1_7 indiv26
ren s11b1q8b1_8 indiv27
ren s11b1q8b1_9 indiv28
ren s11b1q8b1_10 indiv29
ren s11b1q8b1_11 indiv30
ren s11b1q8b1_12 indiv31
ren s11b1q8b1_13 indiv32
*other ownership documents
ren s11b1q10_1 indiv33
ren s11b1q10_2 indiv34
ren s11b1q10_3 indiv35
ren s11b1q10_4 indiv36
ren s11b1q10_5 indiv37
ren s11b1q10_6 indiv38
ren s11b1q10_7 indiv39
ren s11b1q10_8 indiv40


egen id = concat(hhid plotid)
reshape long indiv, i(id) j(indiv_no)
drop if indiv==. //Drop 350k empty entries so that the merge doesn't break the program.
merge m:1 hhid indiv using individual, nogen keep(3)
gen formal_land_rights_f = formal_land_rights==1 & female==1
preserve
collapse (max) formal_land_rights_f, by(hhid indiv)		
save landright, replace
restore	
collapse (max) formal_land_rights_hh=formal_land_rights, by(hhid)		// taking max at household level; equals one if they have official documentation for at least one plot
//merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhids.dta"
//recode formal_land_rights_hh (.=0) //ALT 03.20.2020: I think this gets screwed up later in the code if there isn't a value for this variable.
//ALT 09.16.20: doing it this way results in abnormally low values for formal land rights.
keep hhid formal_land_rights_hh
*DYA.11.21.2020 there are only 691 observation which seems relatively lower than in w3
*ALT 02.01.2021: Including "other" resulted in an increase in obs.
save landright, replace


********************************************************************************
*crop unit conversion factors
********************************************************************************
/*ALT: Theoretically this should be unnecessary because conversion factors are now
included in their respective files. However, in practice there is a lot of missing info
and so we need to construct a central conversion factors file like the one provided in W3.
Issues this section is used to address:
	*Known but missing conversion factors
	*Calculating conversion factors for seed (see seed section for why we need this)
	*Units that had conversion factors in previous waves that were not used in W4
	*Conversion factors for units that weren't included but which can be inferred from the literature
*/
use "C:\Users\obine\OneDrive\Documents\wave4stata\secta3i_harvestw4.dta", clear
append using "C:\Users\obine\OneDrive\Documents\wave4stata\secta3ii_harvestw4.dta"
append using "C:\Users\obine\OneDrive\Documents\wave4stata\secta3iii_harvestw4.dta"
replace cropcode=1120 if inrange(cropcode, 1121,1124)
label define CROPCODE 1120 "1120. YAM" , replace
//recode cropcode (2170=2030) //Bananas=plaintains ALT 06.23.2020: Bad idea, because the conversion factors vary a bunch (har har)
ren sa3iq6ii unit
ren sa3iq6_4 size
ren sa3iq6_2 condition
ren sa3iq6_conv conv_fact

replace unit=sa3iiq1c if unit==.
replace size=sa3iiq1d if size==.
replace condition=sa3iiq1b if condition==.  //ALT 02.01.21 Typo; fixed //DYA.11.21.2020  I am not sure why this? sa3iiq1d is "What was the total harvest of [CROP] from all HH's plots? (Size)". Should be sa3iiq1b but this is used below
replace conv_fact=sa3iiq1_conv if conv_fact==.

replace unit=sa3iiiq13c if unit==.
replace size=sa3iiiq13d if size==.
replace condition=sa3iiiq13b if condition==.
replace conv_fact=sa3iiiq13_conv if conv_fact==.

replace unit=sa3iq6d2 if unit==.
replace size=sa3iq6d4 if size==.
//ALT 09.25.20: something weird is happening here
replace condition=sa3iq6d2a if condition==.
replace conv_fact=sa3iq6d_conv if conv_fact==.
//drop if sa3iq3==2 | sa3iq3==. //drop if no harvest //ALT 02.03.21: I was mistakenly dropping things needed for conversion factors here
drop if unit==.  //DYA.11.21.2020 So all the missing units are instances where there was no harvest during the season
//At this point we have all cropcode/size/unit/condition combinations that show up in the survey.
//Ordinarily, we'd collapse by state/zone/country to get median values most representative of a hh's area.
//However, here the values are the same across geographies so we don't need to do it - we just need to add in our imputed values.

//ALT 06.23.2020: Code added for bananas/plantains, oil palm, other missing conversions. Turns out conversions are missing from the tree crop harvest in the next section, and so tree crops are being underreported in the final data.
replace conv_fact=1 if unit==1 //kg
replace conv_fact=0.001 if unit==2 //g

replace conv_fact=25 if size==10 //25kg bag
replace conv_fact=50 if size==11 //50kg bag
replace conv_fact=100 if size==12 //100kg bag

replace conv_fact = 21.3 if unit==160 & cropcode==2230 //Conversion factors for sugar cane, because they are not in the files or basic info doc
replace conv_fact = 2.13 if unit==80 & cropcode==2230
replace conv_fact = 53.905 if unit==170 & cropcode==2230
replace conv_fact = 1957.58 if unit==180 //Estimated weight for a pick-up 
//Banana/Plantain & oil palm conversions from W3
replace conv_fact=0.5 if unit==80 & size==0 & cropcode==2030
replace conv_fact=0.6 if unit==80 & (size==1 | size==.) & cropcode==2030
replace conv_fact=0.7 if unit==80 & size==2 & cropcode==2030
replace conv_fact=0.445 if unit==100 & size==0 & cropcode==2030
replace conv_fact=1.345 if unit==100 & (size==1 | size==.) & cropcode==2030
replace conv_fact=2.12 if unit==100 & size==2 & cropcode==2030
replace conv_fact=5.07 if unit==110 & size==0 & cropcode==2030
replace conv_fact=7.14 if unit==110 & (size==1 | size==.) & cropcode==2030
replace conv_fact=21.62 if unit==110 & size==2 & cropcode==2030

replace conv_fact=0.135 if unit==80 & size==0 & cropcode==2170
replace conv_fact=0.23 if unit==80 & (size==1 | size==.) & cropcode==2170
replace conv_fact=0.34 if unit==80 & size==2 & cropcode==2170
replace conv_fact=0.615 if unit==100 & size==0 & cropcode==2170
replace conv_fact=1.06 if unit==100 & (size==1 | size==.) & cropcode==2170
replace conv_fact=2.1 if unit==100 & size==2 & cropcode==2170
replace conv_fact=3.51 if unit==110 & size==0 & cropcode==2170
replace conv_fact=5.14 if unit==110 & (size==1 | size==.) & cropcode==2170
replace conv_fact=7.965 if unit==110 & size==2 & cropcode==2170

replace conv_fact=5.235 if unit==140 & size==0 & cropcode==2170
replace conv_fact=13.285 if unit==140 & (size==1 | size==.) & cropcode==2170
replace conv_fact=15.972 if unit==140 & size==2 & cropcode==2170
replace conv_fact=3.001 if unit==150 & size==0 & cropcode==2170
replace conv_fact=6.959 if unit==150 & (size==1 | size==.) & cropcode==2170
replace conv_fact=16.11 if unit==150 & size==2 & cropcode==2170

//Oil palm bunch data. Lots of papers report weights, but none report variances, so asessing small/med/large is difficult.
//The lit cites bunch weights anywhere from 15-40 kg, but Nigeria-specific research exclusively cites lower values. Here,
//I use the range from Genotype and genotype by environment (GGE) biplot analysis of fresh fruit bunch yield and yield components of oil palm (Elaeis guineensis Jacq.).
//by Okoye et al (2008) to approximate the field variation.

replace conv_fact=9.5 if unit==100 & size==0 & cropcode==3180
replace conv_fact=14.5 if unit==100 & size==2 & cropcode==3180
replace conv_fact=12 if unit==100 & (size==1 | size==.) & cropcode==3180

//Now one-size-fits-all estimates from WB and external sources to get stragglers 
//These from Local weights and measures in Nigeria: a handbook of conversion factors by Kormawa and Ogundapo
//paint rubber - 2.49 //LSMS says about 2.9
replace conv_fact=2.49 if unit==11 & conv_fact==.
replace conv_fact = 1.36 if (unit==20 | unit==30) & size==0 & conv_fact==. //Lower estimate given by Kormawa and Ogundapo
replace conv_fact = 1.5 if (unit==20 | unit==30) & (size==1 | size==.) & conv_fact==. //congo/mudu value from LSMS W1, assuming medium if left blank
replace conv_fact = 1.74 if (unit==20 | unit==30) & size==2 & conv_fact==. //Upper estimate by K&O
replace conv_fact = 2.72 if unit==50 & size==0 & conv_fact==. //1 tiya=2 mudu
replace conv_fact = 3 if unit==50 & (size==1 | size==.) & conv_fact==. //2x med mudu
replace conv_fact = 3.48 if unit==50 & size==2 & conv_fact==. //2x lg mudu
replace conv_fact = 0.35 if unit==40 & size==0  & conv_fact==. //Small derica from W1
replace conv_fact = 0.525 if unit==40 & (size==1 | size==.) & conv_fact==. //central value
replace conv_fact = 0.7 if unit==40 & size==2 & conv_fact==. & conv_fact==. //large derica from W1
replace conv_fact = 15 if unit==140 & size==0 & conv_fact==. //Small basket from W1
replace conv_fact = 30 if unit==140 & (size==1 | size==.) & conv_fact==. //Med basket W1
replace conv_fact = 50 if unit==140 & size==2 & conv_fact==. //Lg basket W1
replace conv_fact = 85 if unit==170 & size==. & conv_fact==. //Med wheelbarrow w1 

drop if conv_fact==.

collapse (median) conv_fact, by(unit size cropcode condition)
ren conv_fact conv_fact_median
save conversion_cf, replace



*ALL PLOTS
********************************************************************************
/*ALT 08.16.21: Imported the W3 code for this section 
This code is part of a project to create database-style files for use in AgQuery. At the same time,
it simplifies and reduces the ag indicator construction code. Most files generated by the old code
are still constructed (marked as "legacy" files); some files are eliminated where data were consolidated.
*/
	***************************
	*Crop Values
	***************************
	//Nonstandard unit values
use "${Nigeria_GHS_W4_raw_data}/secta3ii_harvestW4.dta", clear
	replace cropcode=1120 if inrange(cropcode, 1121,1124)
	label define CROPCODE 1120 "1120. YAM", replace
	keep if sa3iiq3==1
	ren sa3iiq5a qty
	ren sa3iiq1b condition
	ren sa3iiq1c unit
	ren sa3iiq1d size
	ren sa3iiq6 value
	merge m:1 hhid using weight, nogen keepusing(weight_pop_rururb) keep(3)
	//ren cropcode crop_code
	gen price_unit = value/qty
	gen obs=price_unit!=.
	keep if obs==1
	foreach i in zone state lga ea hhid {
		preserve
		bys `i' cropcode unit size condition : egen obs_`i'_price = sum(obs)
		collapse (median) price_unit_`i'=price_unit [aw=weight_pop_rururb], by (`i' unit size condition cropcode obs_`i'_price)
		tempfile price_unit_`i'_median
		save `price_unit_`i'_median'
		restore
	}
	bys cropcode unit size condition : egen obs_country_price = sum(obs)
	collapse (median) price_unit_country = price_unit [aw=weight_pop_rururb], by(cropcode unit size condition obs_country_price)
	tempfile price_unit_country_median
	save `price_unit_country_median'
//Because we have several qualifiers now (size and condition), using kg as an alternative for pricing. Results from experimentation suggests that the kg method is less accurate than using original units, so original units should be preferred.
use "${Nigeria_GHS_W4_raw_data}/secta3ii_harvestW4.dta", clear
	keep if sa3iiq3==1
	replace cropcode=1120 if inrange(cropcode, 1121,1124)
	label define CROPCODE 1120 "1120. YAM", replace //Note: Plantains get recoded to bananas, but save that for the end because unit conversions are much different.
	ren sa3iiq5a qty
	ren sa3iiq1b condition
	ren sa3iiq1c unit
	ren sa3iiq1d size
	ren sa3iiq6 value
	merge m:1 hhid using weight, nogen keepusing(weight_pop_rururb) keep(1 3)
	merge m:1 cropcode unit size condition using conversion_cf, nogen keep(1 3)
	//ren cropcode crop_code
	gen qty_kg = qty*conv_fact 
	drop if qty_kg==. //34 dropped; largely basin and bowl.
	gen price_kg = value/qty_kg
	gen obs=price_kg !=.
	keep if obs == 1
	foreach i in zone state lga ea hhid {
		preserve
		bys `i' cropcode : egen obs_`i'_pkg = sum(obs)
		collapse (median) price_kg_`i'=price_kg [aw=weight_pop_rururb], by (`i' cropcode obs_`i'_pkg)
		tempfile price_kg_`i'_median
		save `price_kg_`i'_median'
		restore
	}
	bys cropcode : egen obs_country_pkg = sum(obs)
	collapse (median) price_kg_country = price_kg [aw=weight_pop_rururb], by(cropcode obs_country_pkg)
	tempfile price_kg_country_median
	save `price_kg_country_median'

	***************************
	*Plot variables
	***************************
use "${Nigeria_GHS_W4_raw_data}/sect11f_plantingW4.dta", clear
	gen crop_code_11f = cropcode
	merge 1:1 hhid plotid cropcode using "${Nigeria_GHS_W4_raw_data}/secta3i_harvestw4.dta", nogen
	merge 1:1 hhid plotid cropcode using "${Nigeria_GHS_W4_raw_data}/secta3iii_harvestw4.dta", nogen
	ren cropcode crop_code_a3i 
	ren plotid plot_id
	ren s11fq5 number_trees_planted
	replace crop_code_11f=crop_code_a3i if crop_code_11f==.
	replace crop_code_a3i = crop_code_11f if crop_code_a3i==.
	gen crop_code_master =crop_code_11f //Generic level
	recode crop_code_master (2170=2030) (2142 = 2141) (1121 1122 1123 1124=1120) //Only things that carry over from W3 are bananas/plantains, yams, and peppers. The generic pepper category 2040 in W3 is missing from this wave.
	label define CROPCODE 1120 "1120. YAM", replace
	la values crop_code_master CROPCODE
	merge m:1 hhid plot_id using plotarea, nogen keep(3) //ALT 05.03.23
	gen ha_planted = s11fq1/100*field_size
	replace ha_planted = s11fq4/100*field_size if ha_planted==.
	//merge m:1 zone area_unit using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_landcf.dta", nogen keep(1 3)
	gen ha_harvest = ha_planted if sa3iq4b ==2 | sa3iiiq7==1 //Was area planted less than area harvested? 2=No / In the last 12 months, has your household harvested any <Tree Crop>? They don't ask for area harvested, so I assume that the whole area is harvested (not true for some crops)
	replace ha_harvest=ha_planted*sa3iq5/100 if ha_harvest==.
	replace ha_harvest = 0 if ha_harvest==.
	/*gen month_planted = s11fq3a+(s11fq3b-2014)*12
	gen month_harvested = sa3iq4a1 + (sa3iq4a2-2014)*12
	gen months_grown = month_harvested-month_planted if s11fc5==1 //Ignoring permanent crops that may be grown multiple seasons
	replace months_grown=. if months_grown <1 | month_planted==. | month_harvested==.*/
	preserve
		gen obs=1
		replace obs=0 if inrange(sa3iq4,1,5) & s11fq0==1
		collapse (sum) obs, by(hhid plot_id crop_code_master)
		replace obs = 1 if obs > 1
		collapse (sum) crops_plot=obs, by(hhid plot_id)
		tempfile ncrops 
		save `ncrops'
	restore //14 plots have >1 crop but list monocropping; meanwhile 289 list intercropping or mixed cropping but only report one crop
	merge m:1 hhid plot_id using `ncrops', nogen
	
	gen lost_crop=inrange(sa3iq4,1,5) & s11fq0==1
	bys hhid plot_id : egen max_lost = max(lost_crop)
	gen replanted = (max_lost==1 & crops_plot>0)
	drop if replanted==1 & lost_crop==1 //Crop expenses should count toward the crop that was kept, probably.

	//bys hhid plot_id : egen crops_avg = mean(crop_code_master) //Checks for different versions of the same crop in the same plot
	gen purestand=1 if crops_plot==1 //This includes replanted crops
	gen perm_crop=(s11fq0==2)
	replace perm_crop = 1 if crop_code_master==1020 //I don't see any indication that cassava is grown as a seasonal crop in Nigeria
	bys hhid plot_id : egen permax = max(perm_crop)
	
	//bys hhid plot_id s11fq3a s11fq3b : gen plant_date_unique=_n
	gen plant_date = ym(s11fq3_2, s11fq3_1)
	format plant_date %tm
	gen harv_date = ym(sa3iq4a2, sa3iq4a1)
	format harv_date %tm
	gen harv_end = ym(sa3iq6c2, sa3iq6c1)
	format harv_end %tm
	
	bys hhid plot_id plant_date : gen plant_date_unique = _n
	bys hhid plot_id harv_date : gen harv_date_unique = _n
	bys hhid plot_id : egen plant_dates = max(plant_date_unique)
	bys hhid plot_id : egen harv_dates = max(harv_date_unique)
	replace purestand=0 if (crops_plot>1 & (plant_dates>1 | harv_dates>1))  | (crops_plot>1 & permax==1)  //Multiple crops planted or harvested in the same month are not relayed; may omit some crops that were purestands that preceded or followed a mixed crop.
	gen any_mixed = !(s11fq2==1 | s11fq2==3)
	bys hhid plot_id : egen any_mixed_max = max(any_mixed)
	replace purestand=1 if crops_plot>1 & plant_dates==1 & harv_dates==1 & permax==0 & any_mixed_max==0 //54 replacements, maybe half of which are proper relay crops; still some huge head-scratchers.
	gen relay=1 if crops_plot>1 & crops_plot>1 & plant_dates==1 & harv_dates==1 & permax==0 & any_mixed_max==0 //Looks like relay crops are reported either as relays or as monocrops 
	//replace purestand=1 if crop_code_11f==crops_avg
	replace purestand=0 if purestand==.
	drop crops_plot /*crops_avg*/ plant_dates harv_dates plant_date_unique harv_date_unique permax
	//Okay, now we should be able to relatively accurately rescale plots.
	replace ha_planted = ha_harvest if ha_planted==. //182 changes
	replace ha_harvest = ha_planted if sa3iq6d1 !=. //ALT 02.10.22: Assume people with "still to harvest" values will harvest the entire plot.
	//Let's first consider that planting might be misreported but harvest is accurate
	//ALT: n/a to W4:
	//replace ha_planted = ha_harvest if ha_planted > field_size & ha_harvest < ha_planted & ha_harvest!=. //4,476 changes
	gen percent_field=ha_planted/field_size
*Generating total percent of purestand and monocropped on a field
	bys hhid plot_id: egen total_percent = total(percent_field)
//Dealing with crops which have monocropping larger than plot size or monocropping that fills plot size and still has intercropping to add
	replace percent_field = percent_field/total_percent if total_percent>1 & purestand==0
	replace percent_field = 1 if percent_field>1 & purestand==1
	//45 changes made


	replace ha_planted = percent_field*field_size
	replace ha_harvest = ha_planted if ha_harvest > ha_planted

	*renaming unit code for merge
	//ALT 10.14.21: Tree crop harvests are recorded in both s11f (planting) and sa3iii (harvest); thus, it's likely that s11f has a lot of old harvests (range 2010-2018; mean 2017.365) that we wouldn't want to consider here. However, 465 obs note 2018 (vs 300 in harvest questionnaire), so I replace with sa3iii except when sa3iii is empty and the harvest year is 2018
	ren sa3iq6ii unit
	replace unit = sa3iiiq13c if unit==.
	replace unit = s11fq11b if unit==. & s11fq8b==2018 
	ren sa3iq6_4 size
	replace size = sa3iiiq13d if size==.
	replace size = s11fq11c if size==. & s11fq8b==2018
	ren sa3iq6_2 condition
	replace condition = sa3iiiq13b if condition==.
	replace condition = s11fq11d if condition==. & s11fq8b==2018
	ren sa3iq6i quantity_harvested
	replace quantity_harvested = sa3iiiq13a if quantity_harvested==.
	replace quantity_harvested = s11fq11a if quantity_harvested==. & s11fq8b==2018
	*merging in conversion factors
	ren crop_code_a3i cropcode
	merge m:1 cropcode unit size condition using conversion_cf, keep(1 3) nogen
//ALT 02.11.22
	gen quant_harv_kg = quantity_harvested * sa3iq6_conv
	replace quant_harv_kg = quantity_harvested * sa3iiiq13_conv if quant_harv_kg == .
	replace quant_harv_kg = quantity_harvested * conv_fact if quant_harv_kg == .
	//gen quant_harv_kg= quantity_harvested*conv_fact
	ren sa3iq6a val_harvest_est
	replace val_harvest_est = sa3iiiq14 if val_harvest_est==.
	//ALT 09.28.22: I'm going to keep the grower-estimated valuation in here even though it's likely inaccurate for comparison purposes.
	gen val_unit_est = val_harvest_est/quantity_harvested
	gen val_kg_est = val_harvest_est/quant_harv_kg
	merge m:1 hhid using weight, nogen keep(1 3)
	gen plotweight = ha_planted*weight_pop_rururb
	//IMPLAUSIBLE ENTRIES - at least 100x the typical yield
	foreach var in quantity_harvested quant_harv_kg val_harvest_est val_unit_est val_kg_est {
	replace `var' = . if (hhid == 299005 & plot_id == 2 & cropcode == 1020) | /* 2000 heaps of cassava on 0.003 ha 
	*/ (hhid == 339038 & plot_id == 2 & cropcode == 2190) | /* 5 tons of pumpkins on 0.0075 ha, an area smaller than my apartment
	*/ (hhid == 229068 & plot_id == 2 & cropcode == 1121) | /* 17 tons of yams on 0.144 ha
	*/ (hhid == 120058 & plot_id == 3 & cropcode == 1121) //14 tons of yams on 0.1 ha.
	}
	gen obs=quantity_harvested>0 & quantity_harvested!=.
//ALT 09.28.22: I don't think median estimated valuations were particularly useful (or internally valid); we'll keep them only for the growers that made them.	
/*
	foreach i in zone state lga ea hhid {
preserve
	bys cropcode `i' : egen obs_`i'_kg = sum(obs)
	collapse (median) val_kg_`i'=val_kg [aw=plotweight], by (`i' cropcode obs_`i'_kg)
	tempfile val_kg_`i'_median
	save `val_kg_`i'_median'
restore
}
preserve
collapse (median) val_kg_country = val_kg (sum) obs_country_kg=obs [aw=plotweight], by(cropcode)
tempfile val_kg_country_median
save `val_kg_country_median'
restore
*/
foreach i in zone state lga ea hhid {
/*preserve
	bys `i' cropcode unit : egen obs_`i'_unit = sum(obs)
	collapse (median) val_unit_`i'=val_unit [aw=plotweight], by (`i' unit size condition cropcode obs_`i'_unit)
	tempfile val_unit_`i'_median
	save `val_unit_`i'_median'
restore
*/
	merge m:1 `i' unit size condition cropcode using `price_unit_`i'_median', nogen keep(1 3)
	*merge m:1 `i' unit size condition cropcode using `val_unit_`i'_median', nogen keep(1 3)
	merge m:1 `i' cropcode using `price_kg_`i'_median', nogen keep(1 3)
	*merge m:1 `i' cropcode using `val_kg_`i'_median', nogen keep(1 3)
}
/*preserve
collapse (median) val_unit_country = val_unit (sum) obs_country_unit=obs [aw=plotweight], by(cropcode unit size condition)
tempfile val_unit_country_median
save `val_unit_country_median'
restore
*/
merge m:1 unit size condition cropcode using `price_unit_country_median', nogen keep(1 3)
*merge m:1 unit size condition cropcode using `val_unit_country_median', nogen keep(1 3)
merge m:1 cropcode using `price_kg_country_median', nogen keep(1 3)
*merge m:1 cropcode using `val_kg_country_median', nogen keep(1 3)

//We're going to prefer observed prices first
//ALT 09.25.22: WHY ARE THERE STILL MISSINMG VALUES IN HERE?!
gen price_unit = . 
gen price_kg = .
foreach i in country zone state lga ea {
	replace price_unit = price_unit_`i' if obs_`i'_price>9 & obs_`i'_price != .
	replace price_kg = price_kg_`i' if obs_`i'_pkg>9 & obs_`i'_price != .
}
 	//replace val_unit = price_unit_hhid if price_unit_hhid!=. 
	//replace val_kg = price_kg_hhid if price_kg_hhid!=. 
//ALT 09.25.22: 	
	//gen val_missing_unit = val_unit==. 
	//gen val_missing_kg = val_kg==.

/*	
foreach i in country zone state lga ea {
	replace val_unit = val_unit_`i' if obs_`i'_unit > 9 & val_missing_unit==1
    replace val_kg = val_kg_`i' if obs_`i'_kg > 9 & val_missing_kg == 1
}
	*/
	//replace val_unit = val_unit_hhid if val_unit_hhid!=.  //Preferring household values where available.
	//replace val_kg = val_kg_hhid if val_kg_hhid!=. & val_unit==.
//All that for these two lines:
	gen value_harvest = price_unit * quantity_harvested
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
value_harv~t |      9,210    63378.53    192444.3   272.7273    7500000
val_harves~t |     11,739     54432.8      156671          1    7000000

*/	
	
	replace value_harvest = price_kg * quant_harv_kg if value_harvest == .
/* 

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
value_harv~t |     11,378    57716.91    217123.9   22.51745   1.33e+07
val_harves~t |     11,735    54260.04    156072.4          1    7000000
*/	
	replace value_harvest = val_harvest_est if value_harvest == .
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
value_harv~t |     11,829    56602.66    213841.5   22.51745   1.33e+07
val_harves~t |     11,735    54260.04    156072.4          1    7000000
*/
//A few situations (mainly cocoa) where the grower estimated price is substantially below the area median.	

	//Replacing conversions for unknown units
	replace val_unit_est = value_harvest/quantity_harvested if val_unit_est==.
	replace val_kg_est = value_harvest/quant_harv_kg if val_kg_est == .

preserve
//ALT note to double check and see if the changes to valuation mess this up.
	collapse (mean) val_kg=price_kg conv_fact, by(hhid cropcode)
	save cropprice, replace //Backup for s-e income.
restore
preserve
	//ALT 02.10.22: NOTE: This should be changed to ensure we get all household values rather than just ones with recorded harvests (although I imagine the number of households that paid in a crop they did not harvest is small)
	collapse (mean) val_unit=price_unit, by (hhid cropcode unit size condition)
	drop if unit == .
	ren val_unit hh_price_mean
	lab var hh_price_mean "Average price reported for this crop-unit in the household"
	save cropprice, replace //This gets used for self-employment income
restore
	//still-to-harvest value
	gen same_unit=unit==sa3iq6d2 & size==sa3iq6d4 & condition==sa3iq6d2a

	//ALT 05.12.21: I feel like we should include the expected harvest.
	//Addendum 10.14: Unfortunately we can only reliably do this for annual crops because the question for tree crops was asked in the planting survey; estimates are probably not reliable.
	//Addendum to addendum 9.28.22: The plant survey also asks about temporary crops, not just tree crops. This was causing estimated harvests to be far too high.
	replace sa3iq6d1 = . if sa3iq6d1 > 19000 //This corrects two plots, one where the household anticipates harvesting 20,000 paint rubbers of peppers (2000x current harvest) and another that anticipates 722,500 bags of rice.
	drop unit size condition quantity_harvested
	ren sa3iq6d2 unit
	ren sa3iq6d4 size
	ren sa3iq6d2a condition
	ren sa3iq6d1 quantity_harvested
	replace quantity_harvested = . if hhid == 220016 & plot_id==2 & crop_code_master==1120 //One obs of 2000 pickups on a quarter of a hectare. Planting estimate was 1 pickup; likely a unit typo. 
	gen quant_harv_kg2 = quantity_harvested * sa3iq6d_conv
	replace quant_harv_kg2 = quantity_harvested * conv_fact if same_unit == 1
	drop conv_fact
	merge m:1 cropcode unit size condition using conversion_cf, nogen keep(1 3)
	replace quant_harv_kg2= quantity_harvested*conv_fact if quant_harv_kg2 == .
	gen val_harv2 = 0
	recode quant_harv_kg2 quantity_harvested value_harvest (.=0) //ALT 02.10.22: This is causing people with "still to harvest" values getting missing where they should have something.

	replace val_harv2=quantity_harvested*price_unit if same_unit==1
	gen missing_unit =val_harv2 == 0
	
foreach i in country zone state lga ea {
	replace val_harv2=quant_harv_kg2*price_kg_`i' if missing_unit==1 & obs_`i'_pkg > 9 & price_kg_`i'!=. 
}
drop missing_unit
	//replace val_harv2=quantity_harvested*val_unit_hhid if same_unit==1 & val_unit_hhid!=.
	//replace val_harv2=quant_harv_kg2*val_kg_hhid if same_unit==0 & val_kg_hhid != . 
	
//The few that don't have the same units are in somewhat suspicious units. (I'm pretty sure you can't measure bananas in liters)
	replace quant_harv_kg = quant_harv_kg+quant_harv_kg2 //Affects 1,081 obs
	replace value_harvest = value_harvest+val_harv2 // Affects 3,466 obs. That's odd.
	/*At this point: 

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
value_harv~t |     15,098    55117.49    203162.9          0   1.33e+07

if ~ != 0


    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
value_harv~t |     14,217    58533.01    208885.5   31.52444   1.33e+07

	*/

	drop val_harv2 quant_harv_kg2 val_* obs*

	
	//drop val_* obs*

	//ALT 03.23.23: CSIRO Data Request
	/*preserve
		merge m:1 lga ea using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_ea_coords.dta", nogen keep(1 3)
		ren zone adm1
		ren state adm2
		ren lga adm3
		ren ea adm4
		ren hhid hhID
		ren plot_id plotID
		ren crop_code crop //The original, unmodified crop code 
		ren area_est plot_area_reported   //farmer estimated plot area - may need to be created
		ren field_size plot_area_measured 
		replace plot_area_measured = . if gps_meas==0
		ren percent_field crop_area_share
		gen planting_month = month(plant_date)
		gen planting_year = year(plant_date)
		gen harvest_month_begin = month(harv_date)
		gen harvest_month_end = month(harv_end)
		gen harvest_year_begin = year(harv_date)
		gen harvest_year_end = year(harv_date)
		keep adm* hhID plotID crop plot_area_reported plot_area_measured crop_area_share planting_month planting_year harvest_month_begin harvest_month_end harvest_year_begin harvest_year_end gps_meas purestand
		save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_all_plots_date.dta", replace
	restore
	*/
	collapse (sum) quant_harv_kg value_harvest /*val_harvest_est*/ ha_planted ha_harvest number_trees_planted percent_field /*(max) months_grown*/, by(zone state lga sector ea hhid plot_id crop_code_master purestand relay field_size gps_meas area_est)
	bys hhid plot_id : egen percent_area = sum(percent_field)
	bys hhid plot_id : gen percent_inputs = percent_field/percent_area
	drop percent_area //Assumes that inputs are +/- distributed by the area planted. Probably not true for mixed tree/field crops, but reasonable for plots that are all field crops
	//Labor should be weighted by growing season length, though. 
	recode ha_planted (0=.) //A few obs where the plantation area isn't given and the presence of other crops on the plot prevents us from inferring area.
	merge m:1 hhid plot_id using plotdecisionmakers, nogen keep(1 3) keepusing(dm_gender)

	save allplot,replace



********************************************************************************
* TLU (Tropical Livestock Units) *
********************************************************************************

use "${Nigeria_GHS_W4_raw_data}/sect11i_plantingw4.dta", clear
gen tlu=0.5 if (animal_cd==101|animal_cd==102|animal_cd==103|animal_cd==104|animal_cd==105|animal_cd==106|animal_cd==107|animal_cd==109)
replace tlu=0.3 if (animal_cd==108)
replace tlu=0.1 if (animal_cd==110|animal_cd==111)
replace tlu=0.2 if (animal_cd==112)
replace tlu=0.01 if (animal_cd==113|animal_cd==114|animal_cd==115|animal_cd==116|animal_cd==117|animal_cd==118|animal_cd==119|animal_cd==120|animal_cd==121)
replace tlu=0.7 if (animal_cd==122)
lab var tlu "Tropical Livestock Unit coefficient"
ren tlu tlu_coefficient
*Owned
ren animal_cd lvstckid
gen cattle=inrange(lvstckid,101,107)
gen smallrum=inlist(lvstckid,110,  111, 120)  //DYA.11.21.2020 no 119 in the options
gen poultry=inrange(lvstckid,113,120)  //DYA.11.21.2020  "120" guinea fowl is poultry
gen other_ls=inlist(lvstckid,108,109, 122, 123) //DYA.11.21.2020   no 121
gen cows=inrange(lvstckid,105,105)
gen chickens=inrange(lvstckid,113,116)
ren s11iq6 nb_ls_stardseas
gen nb_cattle_stardseas=nb_ls_stardseas if cattle==1 
gen nb_smallrum_stardseas=nb_ls_stardseas if smallrum==1 
gen nb_poultry_stardseas=nb_ls_stardseas if poultry==1 
gen nb_other_ls_stardseas=nb_ls_stardseas if other_ls==1 
gen nb_cows_stardseas=nb_ls_stardseas if cows==1 
gen nb_chickens_stardseas=nb_ls_stardseas if chickens==1 
gen nb_ls_today =s11iq2a   //DYA.11.21.2020 This wave makes the distinction between animal owned and animal kept but in earlier waves there was not such distinction and it is more likely that in W1-3 we are counting animals owned and kept together (this could be why  tlu is much smaller in W4 is we use s11iq2 instead of s11iq2a which I am using now)
gen nb_cattle_today=nb_ls_today if cattle==1 
gen nb_smallrum_today=nb_ls_today if smallrum==1 
gen nb_poultry_today=nb_ls_today if poultry==1 
gen nb_other_ls_today=nb_ls_today if other_ls==1  
gen nb_cows_today=nb_ls_today if cows==1 
gen nb_chickens_today=nb_ls_today if chickens==1 
gen tlu_stardseas = nb_ls_stardseas * tlu_coefficient
gen tlu_today = nb_ls_today * tlu_coefficient
ren s11iq16 nb_ls_sold 
ren s11iq17 income_ls_sales 
recode   tlu_* nb_* (.=0)
collapse (sum) tlu_* nb_*  , by (hhid)
lab var nb_cattle_stardseas "Number of cattle owned at the begining of ag season"
lab var nb_smallrum_stardseas "Number of small ruminant owned at the begining of ag season"
lab var nb_poultry_stardseas "Number of cattle poultry at the begining of ag season"
lab var nb_other_ls_stardseas "Number of other livestock (dog, donkey, and other) owned at the begining of ag season"
lab var nb_cows_stardseas "Number of cows owned at the begining of ag season"
lab var nb_chickens_stardseas "Number of chickens owned at the begining of ag season"
lab var nb_cattle_today "Number of cattle owned as of the time of survey"
lab var nb_smallrum_today "Number of small ruminant owned as of the time of survey"
lab var nb_poultry_today "Number of cattle poultry as of the time of survey"
lab var nb_other_ls_today "Number of other livestock (dog, donkey, and other) owned as of the time of survey"
lab var nb_cows_today "Number of cows owned as of the time of survey"
lab var nb_chickens_today "Number of chickens owned as of the time of survey"
lab var tlu_stardseas "Tropical Livestock Units at the begining of ag season"
lab var tlu_today "Tropical Livestock Units as of the time of survey"
lab var nb_ls_stardseas  "Number of livestock owned at the begining of ag season"
lab var nb_ls_stardseas  "Number of livestock owned at the begining of ag season"
lab var nb_ls_today "Number of livestock owned as of today"
lab var nb_ls_sold "Number of total livestock sold alive this ag season"
drop tlu_coefficient
save tlucoefficient, replace






********************************************************************************
* GROSS CROP REVENUE *
********************************************************************************
**Creating median crop prices at different geographic levels to use for imputation**
use "${Nigeria_GHS_W4_raw_data}/secta3ii_harvestw4.dta", clear
//ren cropcode crop_code Note to do this @ end.
ren sa3iiq6 sales_value
recode sales_value (.=0)
/*DYA*/ ren sa3iiq5a quantity_sold
/*DYA*/ ren sa3iiq1c unit
		ren sa3iiq1d size
		ren sa3iiq1b condition
*renaming unit code for merge 
*merging in conversion factors
merge m:1 cropcode unit condition size using conversion_cf, gen(cf_merge)
//ALT 02.15.22: More accurate conversion, hopefully
replace conv_fact = sa3iiq1_conv if sa3iiq1_conv!=.
gen kgs_sold= quantity_sold*conv_fact
//ALT 02.15.22: Needed for crop value lost
recode cropcode (2170=2030) (2142 = 2141) (1121 1122 1123 1124=1120) //Only things that carry over from W3 are bananas/plantains, yams, and peppers. The generic pepper category 2040 in W3 is missing from this wave.
label define CROPCODE 1120 "1120. YAM", replace
ren cropcode crop_code
collapse (sum) sales_value kgs_sold, by (hhid crop_code)
lab var sales_value "Value of sales of this crop"
save cropsales, replace 


use "${Nigeria_GHS_W4_raw_data}/allplot", clear
ren crop_code_master crop_code
collapse (sum) value_harvest, by (hhid crop_code) 
merge 1:1 hhid crop_code using "${Nigeria_GHS_W4_raw_data}/cropsales.dta"
replace value_harvest = sales_value if sales_value>value_harvest & sales_value!=. /* In a few cases, sales value reported exceeds the estimated value of crop harvest */
ren sales_value value_crop_sales 
recode  value_harvest value_crop_sales  (.=0)
collapse (sum) value_harvest value_crop_sales, by (hhid crop_code)
ren value_harvest value_crop_production 
lab var value_crop_production "Gross value of crop production, summed over main and short season"
lab var value_crop_sales "Value of crops sold so far, summed over main and short season"
*save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hh_crop_values_production.dta", replace 
save cropvalueproduction, replace
//Legacy code 
collapse (sum) value_crop_production value_crop_sales, by (hhid)
lab var value_crop_production "Gross value of crop production for this household"
lab var value_crop_sales "Value of crops sold so far"
gen proportion_cropvalue_sold = value_crop_sales / value_crop_production
lab var proportion_cropvalue_sold "Proportion of crop value produced that has been sold"
replace proportion_cropvalue_sold = . if proportion_cropvalue_sold > 1 //HS 4/12/23: Where proportion is greater than 1 (i.e. where value sold >0 but value harvested = 0), repace with empty "."
*save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hh_crop_production.dta", replace
save hhcropproduction, replace

*Crops lost post-harvest
use "${Nigeria_GHS_W4_raw_data}/secta3ii_harvestw4.dta", clear
ren sa3iiq18a share_lost //ALT 02.15.22: This is quantity lost, not percentage. 
ren sa3iiq1c unit
ren sa3iiq1d size
ren sa3iiq1b condition
merge m:1 cropcode unit condition size using conversion_cf, nogen keep(1 3)
//ALT 02.15.22: I think it's probably better to do this as units, not kg, but I think that requires a little restructuring to make that process make sense.
recode cropcode (2170=2030) (2142 = 2141) (1121 1122 1123 1124=1120) //Only things that carry over from W3 are bananas/plantains, yams, and peppers. The generic pepper category 2040 in W3 is missing from this wave.
label define CROPCODE 1120 "1120. YAM", replace
replace conv_fact = sa3iiq1_conv if sa3iiq1_conv!=.
recode share_lost (.=0)
gen kgs_lost = share_lost * conv_fact 
merge m:m hhid cropcode using cropprice, nogen keep(1 3)
gen val_kg = 1
gen crop_value_lost = kgs_lost * val_kg
collapse (sum) crop_value_lost, by (hhid)
lab var crop_value_lost "Value of crops lost between harvest and survey time"
*save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_crop_losses.dta", replace
save croplosses, replace
********************************************************************************
* CROP EXPENSES *
********************************************************************************
//See NGA W3

	*********************************
	* 			LABOR				*
	*********************************
use "${Nigeria_GHS_W4_raw_data}/sect11c1b_plantingw4.dta", clear //Hired Labor
	ren plotid plot_id
	ren s11c1q2 numberhiredmale
	ren s11c1q5 numberhiredfemale
	ren s11c1q8 numberhiredchild
	ren s11c1q3 dayshiredmale
	ren s11c1q6 dayshiredfemale
	ren s11c1q9 dayshiredchild
	ren s11c1q4 wagehiredmale
	ren s11c1q7 wagehiredfemale
	ren s11c1q10 wagehiredchild
	ren s11c1q14a numbernonhiredmale
	ren s11c1q14b numbernonhiredfemale
	ren s11c1q14c numbernonhiredchild
	ren s11c1q15a daysnonhiredmale
	ren s11c1q15b daysnonhiredfemale
	ren s11c1q15c daysnonhiredchild
	keep zone state lga ea hhid plot_id *hired*
	gen season="pp"
tempfile postplanting_hired
save `postplanting_hired'

use "${Nigeria_GHS_W4_raw_data}/secta2b_harvestw4.dta", clear
ren plotid plot_id
	ren sa2bq2 numberhiredmale 
	ren sa2bq3 dayshiredmale
	ren sa2bq5 numberhiredfemale
	ren sa2bq6 dayshiredfemale
	ren sa2bq8 numberhiredchild
	ren sa2bq9 dayshiredchild
	ren sa2bq4 wagehiredmale //Wage per person/per day
	ren sa2bq7 wagehiredfemale
	ren sa2bq10 wagehiredchild
	ren sa2bq14a numbernonhiredmale
	ren sa2bq14b numbernonhiredfemale
	ren sa2bq14c numbernonhiredchild
	ren sa2bq15a daysnonhiredmale
	ren sa2bq15b daysnonhiredfemale
	ren sa2bq15c daysnonhiredchild
	keep zone state lga ea hhid plot_id *hired*
	gen season="ph"
append using `postplanting_hired'

unab vars : *female
local stubs : subinstr local vars "female" "", all
reshape long `stubs', i(zone state lga ea hhid plot_id season) j(gender) string
reshape long number days wage, i(zone state lga ea hhid plot_id gender season) j(labor_type) string
gen val = days*number*wage
//farm labor
preserve 
	drop if strmatch(gender, "child") //Not keeping track of hired labor for some reason.
	collapse (sum) days number val, by(hhid gender)
	gen hired_ = days*number
	gen wage_paid_aglabor_ = val/(days*number)
	keep hhid gender hired_ wage_paid_aglabor_
	reshape wide hired_ wage_paid_aglabor_, i(hhid) j(gender) string
	egen hired_all=rowtotal(hired*)
	egen wage_paid_aglabor=rowtotal(wage*)
	lab var wage_paid_aglabor "Daily agricultural wage paid for hired labor (local currency)"
	lab var wage_paid_aglabor_female "Daily agricultural wage paid for hired labor - female workers (local currency)"
	lab var wage_paid_aglabor_male "Daily agricultural wage paid for hired labor - male workers (local currency)"
	lab var hired_all "Total hired labor (number of person-days)" 
	lab var hired_female "Total hired women's (number of person-days)"
	lab var hired_male "Total hired men's labor (number of person-days)"
	*save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_ag_wage.dta", replace 
	save wage, replace 
restore

merge m:1 hhid using wage, nogen keep(1 3) keepusing(weight_pop_rururb)
merge m:1 hhid plot_id using plotarea, nogen keep(1 3) keepusing(field_size)
gen plotweight = weight*field_size
recode wage (0=.)
gen obs=wage!=.
*Median wages

foreach i in zone state lga ea hhid {
preserve
	bys `i' season gender : egen obs_`i' = sum(obs)
	collapse (median) wage_`i'=wage  [aw=plotweight], by (`i' season gender obs_`i')
	tempfile wage_`i'_median
	save `wage_`i'_median'
restore
}
preserve
collapse (median) wage_country = wage (sum) obs_country=obs [aw=plotweight], by(season gender)
tempfile wage_country_median
save `wage_country_median'
restore

drop obs plotweight
tempfile all_hired_ex
save `all_hired_ex'

//Family labor
use "${Nigeria_GHS_W4_raw_data}/sect11c1a_plantingw4.dta", clear
	drop if s11c1q1a==2
	ren plotid plot_id
	ren indiv pid
	ren s11c1q1b days
keep zone state lga sector ea hhid plot_id pid days
gen season="pp"
tempfile postplanting_family
save `postplanting_family'

use "${Nigeria_GHS_W4_raw_data}/secta2a_harvestw4.dta", clear
	ren plotid plot_id
	ren indiv pid
	ren sa2aq1b days
keep zone state lga sector ea hhid plot_id pid days
gen season="ph"
tempfile harvest_family
save `harvest_family'


use "${Nigeria_GHS_W4_raw_data}/sect1_plantingw4.dta", clear
ren indiv pid
gen male = s1q2==1
gen age = s1q6
keep hhid pid age male
tempfile members
save `members', replace

use `postplanting_family',clear
append using `harvest_family'
drop if days==.
merge m:1 hhid pid using `members', nogen keep(3) //183 unmatched
gen gender="child" if age<16
replace gender="male" if strmatch(gender,"") & male==1
replace gender="female" if strmatch(gender,"") & male==0
gen labor_type="family"
gen number=1 // ALT 05.01.23
keep zone state lga sector ea hhid plot_id season gender days labor_type /*ALT 05.01.23*/ number 
append using `all_hired_ex'
	//ALT 05.01.23: 
	drop if number == . //Empty obs
	replace days = days * number //if labor_type!="family"
	//end ALT 05.01.23
foreach i in zone state lga ea hhid {
	merge m:1 `i' gender season using `wage_`i'_median', nogen keep(1 3) 
}
	merge m:1 gender season using `wage_country_median', nogen keep(1 3) //~234 with missing vals b/c they don't have matches on pid
	recode obs* (.=0)
replace wage=wage_hhid if wage==.
gen wage_missing = wage==. //ALT 05.02.23
foreach i in country zone state lga ea { 
	replace wage = wage_`i' if obs_`i' > 9 & wage_missing==1 //ALT 05.02.23
}
egen wage_sd = sd(wage_hhid), by(gender season)
egen mean_wage = mean(wage_hhid), by(gender season)
/* The below code assumes that wages are normally distributed and values below the 0.15th percentile and above the 99.85th percentile are outliers, keeping the median values for the area in those instances.
In reality, what we see is that it trims a significant amount of right skew - the max value is 14 stdevs above the mean while the min is only 1.15 below. 
*/
//replace wage=wage_hhid if wage_hhid !=. & abs(wage_hhid-mean_wage)/wage_sd <3 //Using household wage when available, but omitting implausibly high or low values. Trims about 5,000 hh obs, max goes from 80,000->35,000; mean 3,300 -> 2,600

replace val = wage*days if val==.
keep zone state lga sector ea hhid plot_id season days val labor_type gender number
//drop if val==. //Either days or number was missing, or both. //ALT 20
merge m:1 plot_id hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_plot_decision_makers", nogen keep(3) keepusing(dm_gender) //ALT: 261 entries across 65 plots are unmatched here; all are post-planting labor only, and I'm not sure why they don't show up in the plot roster
collapse (sum) number val days, by(hhid plot_id season labor_type gender dm_gender) //this is a little confusing, but we need "gender" and "number" for the agwage file.
	la var gender "Gender of worker"
	la var dm_gender "Plot manager gender"
	la var labor_type "Hired, exchange, or family labor"
	la var days "Number of person-days per plot"
	la var val "Total value of hired labor (Naira)"
*save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_plot_labor_long.dta",replace
save plotlaborlong,replace
preserve
	collapse (sum) labor_=days, by (hhid plot_id labor_type)
	reshape wide labor_, i(hhid plot_id) j(labor_type) string
		la var labor_family "Number of family person-days spent on plot, all seasons"
		la var labor_nonhired "Number of exchange (free) person-days spent on plot, all seasons"
		la var labor_hired "Number of hired labor person-days spent on plot, all seasons"
	*save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_plot_labor_days.dta",replace //AgQuery
	save plotlaborday,replace //AgQuery
restore
//At this point all code below is legacy; we could cut it with some changes to how the summary stats get processed.
preserve
	gen exp="exp" if strmatch(labor_type,"hired")
	replace exp="imp" if strmatch(exp,"")
	//append using `inkind_payments' //Only available at hh level in W4
	collapse (sum) val, by(hhid plot_id exp dm_gender)
	gen input="labor"
	*save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_plot_labor.dta", replace //this gets used below.
	save plotlabor, replace //this gets used below.
restore	
//And now we go back to wide
collapse (sum) val, by(hhid plot_id season labor_type dm_gender)
ren val val_ 
reshape wide val_, i(hhid plot_id season dm_gender) j(labor_type) string
ren val* val*_
reshape wide val*, i(hhid plot_id dm_gender) j(season) string
gen dm_gender2 = "male" if dm_gender==1
replace dm_gender2 = "female" if dm_gender==2
replace dm_gender2 = "mixed" if dm_gender==3
drop dm_gender
ren val* val*_
reshape wide val*, i(hhid plot_id) j(dm_gender2) string
collapse (sum) val*, by(hhid)
*save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hh_cost_labor.dta", replace
save hhlaborcost, replace














































































































