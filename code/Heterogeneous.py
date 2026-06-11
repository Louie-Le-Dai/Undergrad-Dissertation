# Import relevant modules
import pandas as pd
import numpy as np
import warnings
warnings.filterwarnings('ignore')

# Change display pattern
pd.set_option('display.unicode.ambiguous_as_wide', True)
pd.set_option('display.unicode.east_asian_width', True)


datalev = pd.read_excel(r'datalev_control.xlsx')

datalev['OperatingNetCashFlow'] = np.log(datalev['OperatingNetCashFlow'])*0.01

datalev['CashHoldings'] = np.log(datalev['CashHoldings'])*0.01



indicators = datalev.columns.difference(['Stkcd', 'date', 'ind', 'Province'])

# 计算3-6年的平均值
datalev_post = datalev[datalev['date'].between(2019, 2022)].groupby('Stkcd')[indicators].mean()

# 计算1-2年的平均值
datalev_pre = datalev[datalev['date'].between(2013, 2018)].groupby('Stkcd')[indicators].mean()

# 计算差值
diff = datalev_post - datalev_pre

# 将结果重置为 DataFrame 格式
result = diff.reset_index()

result = pd.merge(result, datalev[['Stkcd', 'T']], on = ['Stkcd']).drop_duplicates().dropna().reset_index(drop=True)

result.dropna(inplace=True)

print(result)

del result['T_x']

from scipy.stats.mstats import winsorize

for i in ['AssetLiabilityRatio', 'Boardsize', 'CashHoldings', 'Flexlev',
       'KZ', 'OperatingNetCashFlow', 'con', 'debt', 'indp', 'lev',
       'liq', 'salegr', 'size', 'tax']:
    result[i] = winsorize(result[i], limits=[0.05, 0.05])

result = pd.merge(result, datalev[['Stkcd', 'Province']], on = ['Stkcd']).drop_duplicates().dropna().reset_index(drop=True)

result = pd.merge(result, datalev[['Stkcd', 'ind']], on = ['Stkcd']).drop_duplicates().dropna().reset_index(drop=True)

result.to_excel(r'heterocf.xlsx', index=False)

pd.merge(result, datalev[['Stkcd', 'ind']], on='Stkcd')
