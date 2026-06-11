                  //////////// PSM-DID ////////////
				  
clear
import excel "C:\Users\16654\Desktop\毕业论文\hetercf.xlsx", sheet("Sheet1") firstrow

xtset Stkcd date

encode Province, gen(province)

global controls Boardsize size indp dual salegr roa tobinq degree

psmatch2 T $controls, ///
	outcome(Flexsum) logit ate common ties
pstest $controls, both graph

gen matched = _weight > 0  
keep if matched

set seed 1234

gen tmp = runiform()
sort tmp

gen common = _support
drop if common == .
drop if _weight == .

eststo clear
eststo: quietly xtreg Flexsum tp
eststo: quietly xtreg Flexsum tp i.date i.province##i.date, fe cluster(city)
eststo: quietly xtreg Flexsum tp $controls
eststo: quietly xtreg Flexsum tp $controls i.date, fe cluster(city)
esttab, keep(tp) star(* 0.1 ** 0.05 *** 0.01) ///
	b(%8.4f) se(%6.4f) ///
    title("Regression Results") ///
    label stats(r2_a, fmt(4))
esttab using "PSMDID.csv", replace nogaps ///
    b(%8.4f) se(%6.4f) ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    level(95) ///
    title("Basic Regression Results") ///
    label stats(r2_a, fmt(4))
