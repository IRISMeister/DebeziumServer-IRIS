# /usr/irissys/bin/irispython python/graph.py
import pandas as pd
import matplotlib.pyplot as plt
import iris

save_fig_path = "/home/irisowner/share/ex2.png"

#df=pd.read_csv("/home/irisowner/share/bench.csv")
iris.system.Process.SetNamespace("MYAPP")
df = iris.sql.exec("SELECT pkey seq,ts,ts2 FROM inventory.bench").dataframe()

# micro sec to sec
df["diff"] = (df["ts2"] - df["ts"])/1000/1000
df["period"] = df["seq"]//100

df2 = df[["period", "diff"]].groupby(["period"], as_index=True).mean()

#moving_average = df2.rolling(
#    window=100
#    , center=True
#    , min_periods=50,
#).mean()

ax = df2.plot(style=".", color="0.5", legend=False)
#moving_average.plot(ax=ax, linewidth=3, legend=False)
#plt.show
plt.savefig(save_fig_path)

