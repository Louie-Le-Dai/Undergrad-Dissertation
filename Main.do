                   //////////// 实证部分 ////////////

                   //////////// 基本设置 ////////////
				  
clear
import excel "C:\Users\16654\Desktop\论文提升计划\hetercf.xlsx", sheet("Sheet1") firstrow

xtset Stkcd date

set matsize 3000
encode Province, gen(province)

// 控制变量: Boardsize size indp dual salegr roa tobinq degree
global controls Boardsize size indp dual salegr roa tobinq degree
summarize Flexsum $controls

// 基准回归 个体 年份*省份 年份固定效应 行业聚类 2015-2023
eststo clear
eststo: quietly xtreg Flexsum tp, cluster(Stkcd)
eststo: quietly xtreg Flexsum tp i.date i.province##i.date, fe cluster(Stkcd)
eststo: quietly xtreg Flexsum tp $controls, cluster(Stkcd)
eststo: quietly xtreg Flexsum tp $controls i.date i.province##i.date, fe cluster(Stkcd)
esttab, keep(tp) star(* 0.1 ** 0.05 *** 0.01) ///
    b(%8.4f) se(%6.4f) ///
    title("Regression Results") ///
    label stats(N r2_w, fmt(0 4) labels("N" "Adj-R2"))
esttab using "基准回归.csv", replace nogaps ///
    b(%8.4f) se(%6.4f) ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    level(95) ///
    title("Basic Regression Results") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))

	
/// 平行趋势检验
clear
import excel "C:\Users\16654\Desktop\论文提升计划\hetercf.xlsx", sheet("Sheet1") firstrow

xtset Stkcd date

encode Province, gen(province)

// 控制变量: Boardsize size indp dual salegr roa tobinq degree
global controls Boardsize size indp dual salegr roa tobinq degree

gen policy = date - first_treat
replace policy=. if policy >= 2015
tab policy
forvalues i = 7(-1)1{
  gen pre_`i' = (policy == -`i' & T==1) 
}
gen current = (policy == 0)

forvalues j = 1(1)5{
  gen  post_`j' = (policy == `j' & T==1)
}
drop pre_1
	
reghdfe Flexsum pre_* current post_* Boardsize size indp dual salegr roa tobinq degree, absorb(Stkcd date province#date) cluster(Stkcd)
coefplot, baselevels ///
keep(pre_* current post_*) ///
vertical ///
yline(0,lcolor(edkblue*0.8)) ///
xline(7, lwidth(vthin) lpattern(dash) lcolor(teal)) ///
ylabel(,labsize(*0.75)) xlabel(,labsize(*0.75)) ///
ytitle("ATE", size(small)) ///
xtitle("Year", size(small)) ///
addplot(line @b @at) ///
ciopts(lpattern(dash) recast(rcap) msize(medium)) ///
msymbol(circle_hollow) ///
level(90) /// 
scheme(s1mono)			

csdid Flexsum, ivar(Stkcd) time(date) gvar(first_treat) method(dripw) agg(event)

xtreg Flexsum tp Boardsize size indp dual salegr roa age i.date, fe

/// 稳健性：PSM-DID检验

// 近邻匹配

clear
import excel "C:\Users\16654\Desktop\论文提升计划\hetercf.xlsx", sheet("Sheet1") firstrow

xtset Stkcd date

set matsize 3000
encode Province, gen(province)

global controls Boardsize size indp dual salegr roa tobinq degree

psmatch2 T $controls, ///
	outcome(Flexsum) neighbor(4) logit ate common ties
pstest $controls, both graph

histogram _pscore if T==1, width(0.05) color(gs6) addplot( ///
    histogram _pscore if T==0, width(0.05) color(gs12)) legend(label(1 "Treatment") label(2 "Control"))
	
gen matched = _weight > 0  
keep if matched

preserve
set seed 1234

gen tmp = runiform()
sort tmp

gen common = _support
drop if common == .
drop if _weight == .

eststo clear
eststo: quietly xtreg Flexsum tp
eststo: quietly xtreg Flexsum tp i.date i.province##i.date, fe cluster(Stkcd)
eststo: quietly xtreg Flexsum tp $controls
eststo: quietly xtreg Flexsum tp $controls i.date i.province##i.date, fe cluster(Stkcd)
esttab, keep(tp) star(* 0.1 ** 0.05 *** 0.01) ///
	b(%8.4f) se(%6.4f) ///
    title("Regression Results") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))
esttab using "PSMDID.csv", replace nogaps ///
    b(%8.4f) se(%6.4f) ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    level(95) ///
    title("Basic Regression Results") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))
restore

// 核匹配
clear
import excel "C:\Users\16654\Desktop\论文提升计划\hetercf.xlsx", sheet("Sheet1") firstrow

xtset Stkcd date

set matsize 3000
encode Province, gen(province)

global controls Boardsize size indp dual salegr roa tobinq degree

psmatch2 T $controls, outcome(Flexsum) kernel ///
    logit ate common ties
pstest $controls, both graph

histogram _pscore if T==1, width(0.05) color(gs6) addplot( ///
    histogram _pscore if T==0, width(0.05) color(gs12)) legend(label(1 "Treatment") label(2 "Control"))	
	
gen matched = _weight > 0  
keep if matched

preserve
set seed 1234

gen tmp = runiform()
sort tmp

gen common = _support
drop if common == .
drop if _weight == .

eststo clear
eststo: quietly xtreg Flexsum tp
eststo: quietly xtreg Flexsum tp i.date i.province##i.date, fe cluster(Stkcd)
eststo: quietly xtreg Flexsum tp $controls
eststo: quietly xtreg Flexsum tp $controls i.date i.province##i.date, fe cluster(Stkcd)
esttab, star(* 0.1 ** 0.05 *** 0.01) ///
	b(%8.4f) se(%6.4f) ///
    title("Regression Results") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))
esttab using "PSMDID-kernel.csv", replace nogaps ///
    b(%8.4f) se(%6.4f) ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    level(95) ///
    title("Basic Regression Results") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))
restore

	
// 稳健性-同期政策（实际税率）
eststo clear
eststo: quietly xtreg Flexsum tp taxburden
eststo: quietly xtreg Flexsum tp taxburden i.date i.province##i.date, fe cluster(Stkcd)
eststo: quietly xtreg Flexsum tp taxburden $controls
eststo: quietly xtreg Flexsum tp taxburden $controls i.date i.province##i.date, fe cluster(Stkcd)
esttab, keep(tp taxburden) star(* 0.1 ** 0.05 *** 0.01) ///
    b(%8.4f) se(%6.4f) ///
    title("Regression Results") ///
    label stats(N r2_a, fmt(0 4))
esttab using "稳健性-实际税率.csv", replace nogaps ///
    b(%8.4f) se(%6.4f) ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    level(95) ///
    title("Basic Regression Results") ///
    label stats(r2_a, fmt(4))
	
// 稳健性-安慰剂检验
save processed.dta, replace

set matsize 500

* 安慰剂检验 - 虚构处理组
mat b = J(500,1,0)  // 系数矩阵
mat se = J(500,1,0) // 标准误矩阵
mat p = J(500,1,0)  // P 值矩阵

* 循环 500 次
forvalues i=1/500 {
	use processed.dta, clear
    keep if date==2017 // 保留一期数据
    sample 650, count // 随机抽取企业
    keep Stkcd  // 获取所抽取样本的 id 编号
    save match_id.dta, replace  // 另存 id 编号数据
    merge 1:m Stkcd using processed.dta // 与原数据匹配
	gen treat = (_merge == 3)
	gen tp_pb = treat*p
    
    quietly xtreg Flexsum tp_pb $controls i.date i.province##i.date if date>=2015, fe cluster(city)
    
    * 将回归结果赋值到对应矩阵的对应位置
    mat b[`i',1] = _b[tp_pb]
    mat se[`i',1] = _se[tp_pb]
    
    * 计算 p 值并赋值于矩阵
    mat p[`i',1] = 2*ttail(e(df_r), abs(_b[tp_pb]/_se[tp_pb]))
}

* 矩阵转化为向量
svmat b, names(coef)
svmat se, names(se)
svmat p, names(pvalue)

* 删除空值并添加标签
drop if pvalue1 == .
label var pvalue1 "p 值"
label var coef1 "估计系数"
keep coef1 se1 pvalue1

sum coef1 se1 pvalue1

* 绘图
twoway (kdensity coef1, mcolor(blue) yaxis(1)) ///
	(scatter pvalue1 coef1, msymbol(smcircle_hollow) mcolor(blue) yaxis(2)) ///
	, xtitle("Coefficients") xlabel(-0.05(0.05)0.05) ylabel(0(5)30) ///
	xline(0.0251, lwidth(vthin) lp(shortdash)) xtitle("Coefficients") ///
	legend(label(1 "kdensity of Estimates") label(2 "p value")) ///
	plotregion(style(none)) /// 无边框
    graphregion(color(white)) // 白底		

	
                   //////////// 中介效应 - 企业流动性 ////////////
clear
import excel "C:\Users\16654\Desktop\论文提升计划\hetercf.xlsx", sheet("Sheet1") firstrow

xtset Stkcd date

set matsize 3000
encode Province, gen(province)

global controls Boardsize size indp dual salegr roa tobinq degree
				   
gen lev100 = lev*100
eststo clear
eststo: quietly xtreg lev100 tp 
eststo: quietly xtreg lev100 tp i.date i.province##i.date, fe cluster(Stkcd)
eststo: quietly xtreg lev100 tp $controls
eststo: quietly xtreg lev100 tp $controls i.date i.province##i.date, fe cluster(Stkcd)
esttab, keep(tp) star(* 0.1 ** 0.05 *** 0.01) ///
    b(%8.4f) se(%6.4f) ///
    title("Regression Results") ///
    label stats(N r2_a, fmt(0 4))

gen cf_debt = OperatingNetCashFlow/debt
eststo clear
eststo: quietly xtreg cf_debt tp i.date i.province##i.date, fe cluster(Stkcd)
eststo: quietly xtreg cf_debt tp $controls i.date i.province##i.date, fe cluster(Stkcd)
esttab, keep(tp) star(* 0.1 ** 0.05 *** 0.01) ///
	b(%8.4f) se(%6.4f) ///
    title("Cash Flow") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))

eststo clear
eststo: quietly xtreg liquidity tp i.date i.province##i.date, fe cluster(Stkcd)
eststo: quietly xtreg liquidity tp $controls i.date i.province##i.date, fe cluster(Stkcd)
esttab, keep(tp) star(* 0.1 ** 0.05 *** 0.01) ///
	b(%8.4f) se(%6.4f) ///
    title("Cash Flow") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))

eststo clear
eststo: quietly xtreg taxrebate tp i.date i.province##i.date, fe cluster(Stkcd)
eststo: quietly xtreg taxrebate tp $controls i.date i.province##i.date, fe cluster(Stkcd)
esttab, keep(tp) star(* 0.1 ** 0.05 *** 0.01) ///
	b(%8.4f) se(%6.4f) ///
    title("Cash Flow") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))
	
eststo clear
eststo: quietly xtreg SA tp i.date i.province##i.date, fe cluster(Stkcd)
eststo: quietly xtreg SA tp $controls i.date i.province##i.date, fe cluster(Stkcd)
esttab, keep(tp) star(* 0.1 ** 0.05 *** 0.01) ///
	b(%8.4f) se(%6.4f) ///
    title("Cash Flow") ///
    label stats(r2_a, fmt(4))

eststo clear
eststo: quietly xtreg KZ tp i.date i.province##i.date, fe cluster(Stkcd)
eststo: quietly xtreg KZ tp $controls i.date i.province##i.date, fe cluster(Stkcd)
esttab, keep(tp) star(* 0.1 ** 0.05 *** 0.01) ///
	b(%8.4f) se(%6.4f) ///
    title("Cash Flow") ///
    label stats(r2_a, fmt(4))

gen invest = (fixasset/size)*100
eststo clear
eststo: quietly xtreg invest tp i.date i.province##i.date, fe cluster(Stkcd)
eststo: quietly xtreg invest tp $controls i.date i.province##i.date, fe cluster(Stkcd)
esttab, keep(tp) star(* 0.1 ** 0.05 *** 0.01) ///
	b(%8.4f) se(%6.4f) ///
    title("Cash Flow") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))

eststo clear
eststo: quietly xtreg rdinvest tp i.date i.province##i.date, fe cluster(Stkcd)
eststo: quietly xtreg rdinvest tp $controls i.date i.province##i.date, fe cluster(Stkcd)
esttab, keep(tp) star(* 0.1 ** 0.05 *** 0.01) ///
	b(%8.4f) se(%6.4f) ///
    title("Cash Flow") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))

gen logOperatingNetCashFlow = log(OperatingNetCashFlow)
eststo clear
eststo: quietly xtreg logOperatingNetCashFlow tp i.date i.province##i.date, fe cluster(Stkcd)
eststo: quietly xtreg logOperatingNetCashFlow tp $controls i.date i.province##i.date, fe cluster(Stkcd)
esttab, keep(tp) star(* 0.1 ** 0.05 *** 0.01) ///
	b(%8.4f) se(%6.4f) ///
    title("Cash Flow") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))	
	
	
replace CashHoldings = log(CashHoldings)
gen CHr = CashHoldings/(size*10)
eststo clear
eststo: quietly xtreg CashHoldings tp Boardsize size indp dual salegr roa i.date i.province##i.date, fe cluster(Stkcd)
eststo: quietly reghdfe CHr tp Boardsize size indp dual salegr roa, absorb(Stkcd date province#date) cluster(Stkcd)
esttab, keep(tp) star(* 0.1 ** 0.05 *** 0.01) ///
	b(%8.4f) se(%6.4f) ///
    title("Cash Flow") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))	
	
	
sgmediation Flexsum tp lev, cmodel(regress) mmodel(regress)


/// 结构方程模型 -- 可能失败
clear
import excel "C:\Users\16654\Desktop\论文提升计划\hetercf.xlsx", sheet("Sheet1") firstrow

xtset Stkcd date

set matsize 3000
encode Province, gen(province)

global controls Boardsize size indp dual salegr roa tobinq degree
				   
foreach var in Flexsum lev {
    egen z_`var' = std(`var')
}
correlate z_Flexsum z_lev

sem (z_lev <- z_Flexsum) ///
    (tp <- z_lev z_Flexsum),method(mlmv)

destring rd, force replace

eststo clear
eststo: quietly xtreg CashHoldings pre_* current post_* $controls i.date i.province##i.date, fe cluster(Stkcd)
eststo: quietly xtreg CHr pre_* current post_* $controls i.date i.province##i.date, fe cluster(Stkcd)
esttab, keep(pre_* current post_*) star(* 0.1 ** 0.05 *** 0.01) ///
	b(%8.4f) se(%6.4f) ///
    title("Cash Flow") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))	
	
eststo clear
eststo: quietly xtreg fixasset pre_3 pre_2 current post_* Boardsize size indp dual salegr roa age lev i.date if date>=2015, fe cluster(province)
eststo: quietly xtreg liquidity pre_3 pre_2 current post_* Boardsize size indp dual salegr roa fixasset age lev i.date if date>=2015, fe cluster(province)
eststo: quietly xtreg rd pre_3 pre_2 current post_* Boardsize size indp dual salegr roa fixasset age lev i.date if date>=2015, fe cluster(province)
eststo: quietly xtreg cf_debt pre_3 pre_2 current post_* Boardsize size indp dual salegr roa fixasset age lev i.date if date>=2015, fe cluster(province)
esttab, keep(current post_*) star(* 0.1 ** 0.05 *** 0.01) ///
	b(%8.4f) se(%6.4f) ///
    title("Cash Flow") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))		
	
                        ////////////// 动态效应 ////////////// 
						
replace lev = lev*100			
eststo clear
eststo: quietly xtreg cf_debt pre_* current post_* $controls i.date i.province##i.date, fe cluster(Stkcd)
eststo: quietly xtreg lev pre_* current post_* $controls i.date i.province##i.date, fe cluster(Stkcd)
eststo: quietly xtreg cap pre_* current post_* $controls i.date i.province##i.date, fe cluster(Stkcd)
eststo: quietly xtreg rdinvest pre_* current post_* $controls i.date i.province##i.date, fe cluster(Stkcd)
esttab, keep(current post_*) star(* 0.1 ** 0.05 *** 0.01) ///
	b(%8.4f) se(%6.4f) ///
    title("Regression Results") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))
	
eststo clear
eststo: quietly xtreg cf_debt tp $controls i.date, fe cluster(ind)
eststo: quietly xtreg cf_debt pre_* current post_* $controls i.date, fe cluster(ind)
eststo: quietly xtreg liquidity tp $controls i.date, fe cluster(ind)
eststo: quietly xtreg liquidity pre_* current post_* $controls i.date, fe cluster(ind)
eststo: quietly xtreg net tp Boardsize size indp dual salegr roa i.date, fe cluster(ind)
eststo: quietly xtreg net current pre_* current post_* Boardsize size indp dual salegr roa i.date, fe cluster(ind)
esttab, keep(tp current post_*) star(* 0.1 ** 0.05 *** 0.01) ///
	b(%8.4f) se(%6.4f) ///
    title("Regression Results") ///
    label stats(r2_a, fmt(4))	

	
/// 异质性分析
eststo clear
eststo: quietly xtreg Flexsum tp
eststo: quietly xtreg Flexsum tp i.date i.province##i.date, fe cluster(Stkcd)
eststo: quietly xtreg Flexsum tp $controls
eststo: quietly xtreg Flexsum tp $controls i.date i.province##i.date, fe cluster(Stkcd)
esttab, keep(tp) star(* 0.1 ** 0.05 *** 0.01) ///
    b(%8.4f) se(%6.4f) ///
    title("Regression Results") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))
	
	
clear
import excel "C:\Users\16654\Desktop\毕业论文\hetercf.xlsx", sheet("Sheet1") firstrow

xtset Stkcd date
encode Province, gen(province)
global controls Boardsize size indp dual salegr roa tobinq

egen med_size = median(size) 
gen size_med = (size > med_size)
gen size_med_treat = size_med*tp
	
gen degreebac = (degree >= 4)	
gen degreebac_treat = degreebac*tp

xtile cap_tile = cap, n(6)
gen cap20 = (cap_tile >= 5)	
gen cap_high_treat = cap20*tp

xtile sa_tile = SA, n(5)
gen sa20 = (sa_tile == 5)	
gen sa_high_treat = sa20*tp

eststo clear
eststo: quietly xtreg Flexsum size_med_treat size_med tp $controls i.date i.province##i.date, fe cluster(Stkcd) 
eststo: quietly xtreg Flexsum degreebac_treat degreebac tp $controls i.date i.province##i.date, fe cluster(Stkcd)
eststo: quietly xtreg Flexsum cap_high_treat cap20 tp $controls i.date i.province##i.date, fe cluster(Stkcd) 
eststo: quietly xtreg Flexsum sa_high_treat sa20 tp $controls i.date i.province##i.date, fe cluster(Stkcd) 
esttab, keep (size_med_treat degreebac_treat cap_high_treat sa_high_treat tp) star(* 0.1 ** 0.05 *** 0.01) ///
    b(%8.4f) se(%6.4f) ///
    title("Regression of Heterogenity") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))
	

	
clear
import excel "C:\Users\16654\Desktop\毕业论文\hetercf.xlsx", sheet("Sheet1") firstrow

xtset Stkcd date

encode Province, gen(province)

// 控制变量: Boardsize size indp dual salegr roa tobinq degree
global X_common Boardsize size indp dual salegr roa tobinq degree
global D tp
global Y Flexsum

ddml init partial, kfolds(5)
ddml E[D|X]: pystacked $D $X_common, type(reg) method(rf)
ddml E[Y|X]: pystacked $Y $X_common, type(reg) method(rf)
ddml crossfit
ddml estimate, robust	
	