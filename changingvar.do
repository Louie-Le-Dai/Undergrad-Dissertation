clear
import excel "C:\Users\16654\Desktop\论文提升计划\hetercf.xlsx", sheet("Sheet1") firstrow

xtset Stkcd date

set matsize 3000

encode Province, gen(province)

// 控制变量: Boardsize size indp dual salegr roa tobinq degree
global controls Boardsize size indp dual salegr roa tobinq c.degree##i.date

// 稳健性 - 更换变量
gen Cash2 = log(OperatingNetCashFlow + CashHoldings)

// 基准回归 个体 年份*省份 年份固定效应 行业聚类 2015-2023
eststo clear
eststo: quietly xtreg Cash2 tp, cluster(Stkcd)
eststo: quietly reghdfe Cash2 tp, absorb(Stkcd date province#date) cluster(Stkcd)
eststo: quietly xtreg Cash2 tp Boardsize size indp dual salegr roa tobinq c.degree##i.date, cluster(Stkcd)
eststo: quietly reghdfe Cash2 tp Boardsize size indp dual salegr roa tobinq c.degree##i.date, absorb(Stkcd date province#date) cluster(Stkcd)
esttab, star(* 0.1 ** 0.05 *** 0.01) ///
    b(%8.4f) se(%6.4f) ///
    title("Regression Results") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))
esttab using "稳健性-更换变量.csv", replace nogaps ///
    b(%8.4f) se(%6.4f) ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    level(95) ///
    title("Basic Regression Results") ///
    label r2

	
/// 平行趋势检验
clear
import excel "C:\Users\16654\Desktop\毕业论文\hetercf.xlsx", sheet("Sheet1") firstrow

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
	
xtreg Flexsum pre_* current post_* i.date, fe
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
eststo: quietly reghdfe Flexsum tp $controls
eststo: quietly reghdfe Flexsum tp $controls, absorb(date Stkcd city#date) cluster(ind)
esttab, keep(tp $controls) star(* 0.1 ** 0.05 *** 0.01) ///
	b(%8.4f) se(%6.4f) ///
    title("Regression Results") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))
esttab using "PSMDID_knn_B.csv", replace nogaps ///
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

psmatch2 T $controls, outcome(Flexsum) kernel logit ate common ties

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
eststo: quietly reghdfe Flexsum tp $controls, cluster(ind)
eststo: quietly reghdfe Flexsum tp $controls, absorb(date Stkcd city#date) cluster(ind)
esttab, star(* 0.1 ** 0.05 *** 0.01) ///
	b(%8.4f) se(%6.4f) ///
    title("Regression Results") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))
esttab using "PSMDID_kernel_B.csv", replace nogaps ///
    b(%8.4f) se(%6.4f) ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    level(95) ///
    title("Basic Regression Results") ///
    label stats(N r2_a, fmt(0 4) labels("N" "Adj-R2"))
restore


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
    
    quietly reghdfe Flexsum tp_pb $controls, absorb(date Stkcd city#date) cluster(ind)
    
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
twoway (kdensity coef1, mcolor(black) yaxis(1)) ///
	(scatter pvalue1 coef1, msymbol(smcircle_hollow) mcolor(blue) yaxis(2)) ///
	, xtitle("Coefficients") xlabel(-0.05(0.05)0.05) ylabel(0(5)30) ///
	xline(0.0332, lwidth(vthin) lp(shortdash)) xtitle("Coefficients") ///
	legend(label(1 "kdensity of Estimates") label(2 "p value")) ///
	plotregion(style(none)) /// 无边框
    graphregion(color(white)) // 白底