# Import relevant modules
import pandas as pd
import numpy as np
import warnings
warnings.filterwarnings('ignore')

# Change display pattern
pd.set_option('display.unicode.ambiguous_as_wide', True)
pd.set_option('display.unicode.east_asian_width', True)


cash = pd.read_excel(r'现金流.xlsx')

cash['date'] = cash['date'].apply(lambda x: x[: 4])
cash['date'] = cash['date'].astype(int)

# Calculate the Cashflow Variance
cash['cfvar'] = (
    cash.groupby('Stkcd')['cashflow']
    .rolling(window=3, min_periods=1)  # 窗口期为5年，至少有1年数据
    .std()
    .reset_index(level=0, drop=True)  # 删除多余的索引
)

cash.tail(20)

cash['cfvar'] = cash.apply(
    lambda row: row['cfvar'] if 2014 <= row['date'] <= 2022 else None, axis=1
)

cash['cfvar'] = np.log(cash['cfvar'])


asset = pd.read_excel(r'资产总计.xlsx')

asset['date'] = asset['date'].apply(lambda x: x[: 4])
asset['date'] = asset['date'].astype(int)

equi = pd.read_excel(r'等价物.xlsx')

equi['date'] = equi['date'].apply(lambda x: x[: 4])
equi['date'] = equi['date'].astype(int)

cash1 = pd.merge(asset, equi, on = ['Stkcd', 'date'])

net = pd.read_excel(r'净利润.xlsx')

net['date'] = net['date'].apply(lambda x: x[: 4])
net['date'] = net['date'].astype(int)

cash2 = pd.merge(cash1, net, on = ['Stkcd', 'date'])

cash = cash[~cash['date'].isin([2009, 2010, 2011, 2012, 2013])]

cash3 = pd.merge(cash2, cash, on = ['Stkcd', 'date'])


ind = pd.read_excel(r'行业.xlsx')

cash3 = pd.merge(cash3, ind, on = ['Stkcd'])

treatind = [
    "化学原料和化学制品制造业",
    "医药制造业",
    "化学纤维制造业",
    "非金属矿物制品业",
    "金属制品业",
    "通用设备制造业",
    "专用设备制造业",
    "汽车制造业",
    "铁路、船舶、航空航天和其他运输设备制造业",
    "电气机械和器材制造业",
    "计算机、通信和其他电子设备制造业",
    "仪器仪表制造业",
    "互联网和相关服务",
    "软件和信息技术服务业",
    "研究和试验发展",
    "专业技术服务业",
    "科技推广和应用服务业",
    "生态保护和环境治理业"
]


cash3['T'] = cash3['ind'].apply(lambda x: 1 if x in treatind else 0)

# CF from Wind
cf = pd.read_excel(r'现金流wind.xlsx')

cf['Stkcd'] = cf['Stkcd'].apply(lambda x: x[: 6])

cf = pd.melt(cf, id_vars=['Stkcd'], var_name='date', value_name='cf')

cf['cfvar'] = (
    cf.groupby('Stkcd')['cf']
    .rolling(window=3, min_periods=1)  # 窗口期为3年，至少有1年数据
    .std()
    .reset_index(level=0, drop=True)  # 删除多余的索引
)

cf['Stkcd'] = cf['Stkcd'].astype(int)

cash3 = pd.merge(cash3, cf, on = ['Stkcd', 'date'])

# Index Calculation
cash3['hold'] = cash3['equi']/ cash3['totasset']
cash3['produce'] = cash3['net']/ cash3['totasset']
cash3['remain'] = (cash3['equi']-cash3['shortdebt'])/ cash3['totasset']
cash3['cfvar_y'] = 1/ np.log(cash3['cfvar_y'])

'''
cv_hold = np.std(cash3['hold'])/ np.mean(cash3['hold'])
cv_produce = np.std(cash3['produce'])/ np.mean(cash3['produce'])
cv_remain = np.std(cash3['remain'])/ np.mean(cash3['remain'])
cv_cfvar = np.std(cash3['cfvar_y'])/ np.mean(cash3['cfvar_y'])

'''



w = pd.DataFrame()

w['hold'] = cash3.groupby('date')['hold'].std()/ cash3.groupby('date')['hold'].mean()
w['produce'] = cash3.groupby('date')['produce'].std()/ cash3.groupby('date')['produce'].mean()
w['remain'] = cash3.groupby('date')['remain'].std()/ cash3.groupby('date')['remain'].mean()
w['cfvar_y'] = cash3.groupby('date')['cfvar_y'].std()/ cash3.groupby('date')['cfvar_y'].mean()

w_normalized = w.div(w.sum(axis=1), axis=0)

cash3[['date', 'hold', 'produce', 'remain', 'cfvar_y']]


w_normalized = w_normalized.rename({'hold': 'weighted_hold',
           'produce': 'weighted_produce',
           'remain': 'weighted_remain',
           'cfvar_y': 'weighted_cfvar_y'}, axis=1)

cash3 = pd.merge(cash3, w_normalized, on=['date'])

cash3['Flex'] = cash3['hold'] * cash3['weighted_hold'] + cash3['cfvar_y'] * cash3['weighted_cfvar_y'] + cash3['produce'] * cash3['weighted_produce'] + cash3['remain'] * cash3['weighted_remain']


cash3.to_excel(r'data.xlsx', index = False)



# 杠杆
levg = pd.read_excel(r'杠杆.xlsx')
levg['Stkcd'] = levg['Stkcd'].apply(lambda x: x[: 6])

levg = levg.set_index('Stkcd')



L = pd.DataFrame(columns = ['Stkcd', 'date'])

for i, j in enumerate(['debt', 'tax', 'liq', 'lev']):
    le = levg.iloc[ :, i*11: (i+1)*11]
    le.columns = pd.Series(range(2013, 2024))
    L1 = pd.melt(le.reset_index(), id_vars='Stkcd', 
        var_name='date', value_name=j)
# 如果 L 是空的，直接赋值为 L1
    if L.empty:
        L = L1
    else:
        # 按 ['Stkcd', 'date'] 进行 merge，逐次添加新的列
        L = pd.merge(L, L1, on=['Stkcd', 'date'], how='outer')
    print(L)

L = L.sort_values(by=['Stkcd', 'date']).reset_index(drop=True)

L['lev'] = 1-L['lev']*0.01
L['con'] = L['tax']/ L['debt']

L['Flexlev'] = L['lev'] + L['con'] + L['liq']

L['Stkcd'] =L['Stkcd'].astype(int)
L['date'] = L['date'].astype(int)

L = pd.merge(L, cash3[['Stkcd', 'ind']], on = ['Stkcd'])

L = L.drop_duplicates()

L['T'] = L['ind'].apply(lambda x: 1 if x in treatind else 0)

L.to_excel(r'datalev.xlsx', index = False)







