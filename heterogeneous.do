                   //////////// 实证部分 ////////////

				  
clear
import excel "C:\Users\16654\Desktop\论文提升计划\hetercf.xlsx", sheet("Sheet1") firstrow

xtset Stkcd date

set matsize 3000
tostring citycode, replace

encode citycode, gen(city)
encode Province, gen(province)

eststo clear
eststo: quietly reghdfe Flexsum tp Boardsize size SA lev roa ZScore tobinq c.degree##i.date, cluster(Stkcd)
eststo: quietly reghdfe Flexsum tp Boardsize size SA lev roa ZScore tobinq c.degree##i.date, cluster(ind)
eststo: quietly reghdfe Flexsum tp Boardsize size SA lev roa ZScore tobinq c.degree##i.date, absorb(Stkcd date province#date) cluster(Stkcd)
eststo: quietly reghdfe Flexsum tp Boardsize size SA lev roa ZScore tobinq c.degree##i.date, absorb(Stkcd date city#date) cluster(ind)
esttab, star(* 0.1 ** 0.05 *** 0.01) ///
    b(%8.4f) se(%6.4f) ///
    title("Regression Results") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))
esttab using "异质性分析拓展.csv", replace nogaps ///
    b(%8.4f) se(%6.4f) ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    level(95) ///
    title("Basic Regression Results") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))
	
	
                   //////////// stata验证 ////////////
	
	
clear
import excel "C:\Users\16654\Desktop\论文提升计划\hetercf.xlsx", sheet("Sheet1") firstrow

xtset Stkcd date

set matsize 3000
tostring citycode, replace

encode citycode, gen(city)
encode Province, gen(province)
global controls Boardsize size indp dual salegr roa tobinq degree

egen med_size = median(size) 
gen size_med = (size >= med_size)
gen size_med_treat = size_med*tp

egen med_lev = median(lev) 
gen lev_high = (lev >= med_lev)	
gen lev_high_treat = lev_high*tp

gen degreebac = (degree >= 4)	
gen degreebac_treat = degreebac*tp

xtile tobinq_tile = tobinq, n(10)
gen tobinq20 = (tobinq_tile == 10)	
gen tobinq_high_treat = tobinq20*tp

xtile zscore_tile = ZScore, n(10)
gen zscore20 = (zscore_tile == 1)	
gen zscore_high_treat = zscore20*tp

eststo clear
eststo: quietly xtreg Flexsum size_med_treat size_med tp $controls i.date i.province##i.date, fe cluster(Stkcd) 
eststo: quietly xtreg Flexsum degreebac_treat degreebac tp $controls i.date i.province##i.date, fe cluster(Stkcd)
eststo: quietly xtreg Flexsum lev_high_treat lev_high tp $controls i.date i.province##i.date, fe cluster(Stkcd) 
eststo: quietly xtreg Flexsum tobinq_high_treat tobinq20 tp $controls i.date i.province##i.date, fe cluster(Stkcd) 
eststo: quietly xtreg Flexsum zscore_high_treat zscore20 tp $controls i.date i.province##i.date, fe cluster(Stkcd) 
esttab, keep (size_med_treat degreebac_treat lev_high_treat tobinq_high_treat zscore_high_treat) star(* 0.1 ** 0.05 *** 0.01) ///
    b(%8.4f) se(%6.4f) ///
    title("Regression of Heterogenity") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))
esttab using "异质性stata验证_1.csv", replace nogaps ///
    b(%8.4f) se(%6.4f) ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    level(95) ///
    title("Basic Regression Results") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))	
	
eststo clear
eststo: quietly reghdfe Flexsum size_med_treat size_med tp $controls, absorb(Stkcd date city#date) cluster(ind) 
eststo: quietly reghdfe Flexsum degreebac_treat degreebac tp $controls, absorb(Stkcd date city#date) cluster(ind) 
eststo: quietly reghdfe Flexsum lev_high_treat lev_high tp $controls, absorb(Stkcd date city#date) cluster(ind) 
eststo: quietly reghdfe Flexsum tobinq_high_treat tobinq20 tp $controls, absorb(Stkcd date city#date) cluster(ind) 
eststo: quietly reghdfe Flexsum zscore_high_treat zscore20 tp $controls, absorb(Stkcd date city#date) cluster(ind) 
esttab, keep (size_med_treat degreebac_treat lev_high_treat tobinq_high_treat zscore_high_treat) star(* 0.1 ** 0.05 *** 0.01) ///
    b(%8.4f) se(%6.4f) ///
    title("Regression of Heterogenity") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))	
esttab using "异质性stata验证_2.csv", replace nogaps ///
    b(%8.4f) se(%6.4f) ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    level(95) ///
    title("Basic Regression Results") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))		
	