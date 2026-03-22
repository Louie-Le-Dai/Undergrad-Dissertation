 # Undergrad Dissertation: Tax Policy and Firm Financial Behaviors
This is the stata and R code for my undergrad thesis, completed in Oct 2025.

## Title:VAT Credit Refund, Corporate Liquidity andFinancial Flexibility
Author: Le Dai (Zhejiang University of Finance and Economics)

## Exective Summary
This research investigates the impact of China's VAT Credit Refund Policy on corporate financial flexibility using a panel of A-share listed firms from 2015 to 2023. By treating the 2018 and 2022 policy expansions as quasi-natural experiments, I employ a multi-period Difference-in-Differences (DID) approach to identify causal effects. The findings reveal that the policy significantly enhances firms' resilience by boosting liquidity, primarily through a sequential pattern of short-term debt repayment followed by long-term investment and R&D expansion.

## Abstract
In 2018, China implemented the Value-added Tax (VAT) Credit Refund Policy, which was further expanded in 2022 to provide additional cash flow to businesses. This tax incentive policy significantly improved the financial condition of enterprises. This paper uses a composite indicator as a measure of corporate financial flexibility and treats the VAT refund policy as a quasi-natural experiment. Using data from A-share listed companies between 2015 and 2023, this study examines the impact of the VAT refund policy on corporate financial flexibility. The results indicate that the VAT refund policy significantly enhances corporate financial flexibility. Mechanism tests suggest that the policy improves financial flexibility by enhancing corporate liquidity, specifically by (1) improving cash flow management; (2) reducing current liabilities; and (3) increasing investment and research and development (R&D) expenditures to obtain long-term benefits, thereby enhancing financial flexibility. Dynamic effect analysis reveals that businesses first use the refunded VAT to repay short-term debt before expanding investments and R&D to enhance profitability. Finally, heterogeneity analysis shows that the policy has a more significant impact on the financial flexibility of firms with higher financing constraints, smaller sizes, and higher capital intensity.

## Institutional Settings
This study is situated within China's major fiscal reforms aimed at reducing tax burdens and optimizing the business environment:
1. The VAT System in China: As China’s largest tax source (contributing nearly 40% of national tax revenue), the VAT system operates on an invoice-based credit method.
2. Policy Shock (2018 & 2022): The study leverages the VAT Credit Refund Policy introduced in June 2018 (initially targeting 18 designated industries) and its major expansion in 2022 (covering 16 industries, including manufacturing and small/micro enterprises). 
3. Economic Rationale: The policy aims to transform "excess input VAT" (which previously sat as an unusable credit on balance sheets) into immediate cash flow, thereby alleviating liquidity constraints and enhancing risk resilience.

Government policy document:
1. 2018 first implementation: https://www.chinatax.gov.cn/chinatax/n810341/n810765/n3359382/201807/c3730844/content.html (2018 first implementation);
2. 2022 further expansion: https://fgk.chinatax.gov.cn/zcfgk/c102416/c5202030/content.html#:~:text=%E5%9B%BD%E5%AE%B6%E7%A8%8E%E5%8A%A1%E6%80%BB%E5%B1%80%E6%94%BF%E7%AD%96%E6%B3%95%E8%A7%84%E5%BA%93.

## Data Source
The empirical analysis relies on a comprehensive micro-level dataset of Chinese firms:Sample Scope: 
1. All A-share listed companies in China from 2015 to 2023.
2. Primary Databases: Financial and corporate governance data were retrieved from the CSMAR (China Stock Market & Accounting Research, see: https://data.csmar.com/) and Wind databases (See: https://www.wind.com.cn/).
3. Data Cleaning: The final dataset (11,624 observations from 1,951 firms) excludes financial sector firms, companies in financial distress (ST/*ST), and observations with negative ROE or missing key variables. 2% winsorization was applied to mitigate outlier interference.

## Empirical Design
The paper treats the VAT refund policy as a quasi-natural experiment to identify causal effects:
1. Baseline Model: Employs a **Multi-period Difference-in-Differences (DID)** approach.
2. Dependent Variable: A **composite** Financial Flexibility (FF) Index constructed from debt capacity, cash holdings, cash flow volatility, and external financing costs using the Analytic Hierarchy Process (AHP) and the coefficient of variation method.
3. Fixed Effects: Includes Firm, Year, and Province-by-Year fixed effects to control for unobserved heterogeneity and variations in local tax enforcement intensity.
4. Robustness & Advanced Metrics: Parallel Trend Tests: Verified that treatment and control groups shared indistinguishable trends prior to policy implementation.
5. Selection Bias Correction: Combined DID with Propensity Score Matching (PSM) (Nearest-Neighbor and Kernel matching).
6. Alternative Estimators: Validated results using **CSDID** (Callaway and Sant’Anna) for staggered adoption and Double Machine Learning (DML) for high-dimensional settings.
7. Heterogeneity Analysis: Explored varied impacts using Causal Forests (Generalized Random Forest framework) to identify non-linear relationships and rank variable importance.

## Main References
1. Athey,S., & Imbens, G.W. (2016). Recursive partitioning for heterogeneous causal effects. *Proceedings of the National Academy of Sciences, 113*(27),7353–7360.
2. Callaway, B., & Sant’Anna, P.H.C.(2021). Difference-in-differences with multiple time periods. *Journal of Econometrics, 225*(2), 200–230.
3. Chernozhukov, V., Chetverikov, D., Demirer, M., Duflo, E., Hansen, C., Newey, W., & Robins, J. (2018). Double/debiased machine learning for treatment and structural parameters. *The Econometrics Journal, 21*(1),C1–C68.
4. Liu, Y., & Mao, J. (2019). How do tax incentives affect investment and productivity? Firm-level evidence from china. *American Economic Journal: Economic Policy, 11*(3), 261–291.
5. Yagan, D. (2015). Capital tax reform and the real economy: The effects of the 2003 dividend tax cut. *American Economic Review, 105*(12), 3531–3563.
6. Zwick, E., & Mahon, J. (2017). Tax policy and heterogeneous investment behavior. *American Economic Review, 107*(1), 217–248.





