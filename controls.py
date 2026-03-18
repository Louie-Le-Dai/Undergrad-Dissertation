# Import relevant modules
import pandas as pd
import numpy as np
import warnings
warnings.filterwarnings('ignore')

# Change display pattern
pd.set_option('display.unicode.ambiguous_as_wide', True)
pd.set_option('display.unicode.east_asian_width', True)

# 结构转换
def transform(df, var):
    if df['Stkcd'].dtype == 'O':
        df['Stkcd'] = df['Stkcd'].apply(lambda x: x[: 6]).astype(int)
    df = pd.melt(df, id_vars=['Stkcd'], var_name='date', value_name=var)
    return df

# 控制变量: roa dual salegr top1 size age indp boardsize cash
roa = pd.read_excel(r'roa.xlsx')
roa = transform(roa, 'roa')

ceo = pd.read_excel(r'董事.xlsx')
ceo['Stkcd'] = ceo['Stkcd'].astype(int)
ceo['date'] = ceo['date'].apply(lambda x: x[: 4])
ceo['date'] = ceo['date'].astype(int)
ceo['Boardsize'] = np.log(ceo['Boardsize'])
ceo['indp'] = ceo['indp']*0.01

asset = pd.read_excel(r'asset.xlsx') # Size
asset = transform(asset, 'size')
asset['size'] = np.log(asset['size'])*0.01

sale = pd.read_excel(r'营业收入.xlsx')
sale = transform(sale, 'sale')
sale = sale.sort_values(by=['Stkcd', 'date']).reset_index(drop=True)
sale['salegr'] = sale.groupby('Stkcd')['sale'].pct_change()
sale = sale[~sale['date'].isin([2012])]
del sale['sale']

age = pd.read_excel(r'年龄.xlsx') # Age & Province
age['Stkcd'] = age['Stkcd'].apply(lambda x: x[: 6]).astype(int)
age['age'] = 2023 - age['age'].dt.year
age['age'] = np.log(age['age'])

cash = pd.read_excel(r'现金持有.xlsx') 
cash['date'] = cash['date'].apply(lambda x: x[: 4]).astype(int)

control = cash
control = pd.merge(control, roa, on = ['Stkcd', 'date'])
control = pd.merge(control, ceo, on = ['Stkcd', 'date'])
control = pd.merge(control, asset, on = ['Stkcd', 'date'])
control = pd.merge(control, sale, on = ['Stkcd', 'date'])
control = pd.merge(control, age, on = ['Stkcd', 'date'])

control.to_excel(r'control.xlsx', index = False)



# 机制变量: Risk, InventoryTurnover, TaxBurden, CashFlow, Investment

# Coporate Risk
risk = pd.read_excel(r'risk.xlsx') 
risk['date'] = risk['date'].apply(lambda x: x[: 4]).astype(int)

ind = pd.read_excel(r'行业.xlsx') 

risk = pd.merge(risk, ind, on = ['Stkcd'])

roa_ave = risk.groupby(['date', 'ind']).mean()['roa'].reset_index()

risk = pd.merge(risk, roa_ave, on = ['date', 'ind'])

risk['adj_roa'] = risk['roa_x'] - risk['roa_y']

risk['roa_var'] = (
    risk.groupby('Stkcd')['adj_roa']
    .rolling(window=3, min_periods=1)  # 窗口期为3年，至少有1年数据
    .std()
    .reset_index(level=0, drop=True) # 删除多余的索引
)


risk = risk.sort_values(by=['Stkcd', 'date'], ascending=True)
risk = risk[~risk['date'].isin([2009, 2010, 2011, 2012])]

# InventoryTurnover
ivto = pd.read_excel(r'周转率.xlsx') 
ivto['date'] = ivto['date'].apply(lambda x: x[: 4]).astype(int)

# Investment
inv = pd.read_excel(r'投资.xlsx') 
inv['date'] = inv['date'].apply(lambda x: x[: 4]).astype(int)
inv['inv'] = np.log(inv['inv'])*0.01

# TaxBurden
tax = pd.read_excel(r'税负.xlsx') 

rev = tax.iloc[:, 0: 12]
rev.columns = ['Stkcd'] + list(range(2013, 2024))
rev = transform(rev, 'rev')

incometax = tax.iloc[:, [0] + list(range(12, 23))]
incometax.columns = ['Stkcd'] + list(range(2013, 2024))
incometax = transform(incometax, 'incometax')

taxburden = pd.merge(rev, incometax, on = ['Stkcd', 'date'])
taxburden['taxburden'] = taxburden['incometax']/ taxburden['rev']
taxburden = taxburden[taxburden['taxburden'] >= 0].sort_values(['Stkcd', 'date']).reset_index(drop=True)



mec = risk
mec = pd.merge(mec, inv, on = ['Stkcd', 'date'])
mec = pd.merge(mec, taxburden, on = ['Stkcd', 'date'])
mec = pd.merge(mec, ivto, on = ['Stkcd', 'date'])

mec = mec[['Stkcd', 'date', 'ind', 'roa_var', 'inv', 'taxburden', 'CashFlow', 'InventoryTurnover']]


# Merge

datalev = pd.read_excel(r'datalev.xlsx')
control = pd.read_excel(r'control.xlsx')

datalev = pd.merge(datalev, control, on = ['Stkcd', 'date'], how = 'outer')

province = pd.read_excel('省份.xlsx')
province['Stkcd'] = province['Stkcd'].apply(lambda x: x[: 6]).astype(int)
datalev = pd.merge(datalev, province, on = ['Stkcd'])

datalev = pd.merge(datalev, taxburden, on = ['Stkcd', 'date'], how = 'outer')

datalev = pd.merge(datalev, age[['Stkcd', 'age']], on = ['Stkcd'], how = 'outer')

datalev = pd.merge(datalev, roa, on = ['Stkcd', 'date'])

from scipy.stats.mstats import winsorize

for i in datalev.columns:
    if datalev[i].dtype != 'O':
        print(i)
        datalev[i] = winsorize(datalev[i], limits=[0.01, 0.01])

datalev.to_excel(r'datalev_control2.xlsx', index = False)




datalev = pd.read_excel(r'datalev_control2.xlsx')

for i in ['liq', 'con', 'lev']:
    datalev[i] = (datalev[i] - datalev[i].min()) / (datalev[i].max() - datalev[i].min())


datalev.to_excel(r'datalev_control_scaled.xlsx', index = False)





mec = pd.merge(datalev, mec, on = ['Stkcd', 'date'])


# 筛选指标列（假设除 'Entity' 和 'Year' 之外都是指标）
indicators = mec.columns.difference(['Stkcd', 'date', 'ind', 'Province'])

# 计算3-6年的平均值
mec_post = mec[mec['date'].between(2019, 2022)].groupby('Stkcd')[indicators].mean()

# 计算1-2年的平均值
mec_pre = mec[mec['date'].between(2013, 2018)].groupby('Stkcd')[indicators].mean()

# 计算差值
diff = mec_post - mec_pre

# 将结果重置为 DataFrame 格式
result = diff.reset_index()

result = result[['Stkcd', 'Flexlev', 'roa_var', 'inv', 'taxburden_x', 'CashFlow', 'InventoryTurnover']]

result = pd.merge(result, datalev[['Stkcd', 'T']], on = ['Stkcd']).drop_duplicates().dropna().reset_index()


print(result)

for i in ['Stkcd', 'Flexlev', 'roa_var', 'inv', 'taxburden_x', 'CashFlow', 'InventoryTurnover']:
    result[i] = winsorize(result[i], limits=[0.05, 0.05])



result.to_excel(r'heter.xlsx', index = False)










