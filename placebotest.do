 
                  //////////// 安慰剂检验 ////////////

clear
import excel "C:\Users\16654\Desktop\论文提升计划\hetercf.xlsx", sheet("Sheet1") firstrow

xtset Stkcd date

encode Province, gen(province)

// 控制变量: Boardsize size indp dual salegr roa tobinq degree
global controls Boardsize size indp dual salegr roa tobinq degree

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
    
    quietly xtreg Flexsum tp_pb $controls i.date i.province##i.date, fe cluster(Stkcd)
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
	xline(0.0263, lwidth(vthin) lp(shortdash)) xtitle("Coefficients") ///
	legend(label(1 "kdensity of Estimates") label(2 "p value")) ///
	plotregion(style(none)) /// 无边框
    graphregion(color(white)) // 白底		
