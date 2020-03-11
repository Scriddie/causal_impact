library(tidyverse)
library(CausalImpact)
library(foreign)

### potentially interesting data sources:
# https://clinicaltrials.gov/
# kaggle dataset search
###


# TODO: find out what Xus data really means
# TODO: find some time series RCT data (e.g. finance, advertising)

### Use Xu paper data
load("data/Xu_paper/FLSource.RData")
df = data.frame(F.source, F.u.source, L.source)
xu


### Causal Impact toy example
set.seed(1)
n_days = 6
intervention = 1
x1 <- 100 + arima.sim(model = list(ar = 0.999), n=n_days)
y <- 1.2 * x1 + rnorm(n_days)
y[intervention:6] <- y[intervention:6] + 10
data <- cbind(y, x1)

matplot(data, type = "l")


pre.period = c(1, intervention)
post.period = c(intervention+1, n_days)

impact = CausalImpact(data, pre.period, post.period)

plot(impact)


# Use Breakfast RCT data
breakfast = new.env()
df = data.frame(load("data/breakfast/DS0001/36174-0001-Data.rda"))

# Use fertilizer Data
fertilizer = data.frame(read.dta("data/fertilizer/SAFI_main_dataset_AER.dta"))
head(fertilizer)
dim(fertilizer)

# Use visit Data
# visits = data.frame()

# Xu paper data


### Tanzania Data

# We have the following data:
# baseline
# endline
# existing patients
# new patients

library(ggplot2)

pth = paste("data/Tanzania/data/baseline/", "3ie_base_visit.dta", sep="")
df = data.frame(read.dta(pth))

# TODO: 
# group and interv column are the same
# fac_id and fac_label are the same
# maritalstatus is same as marstat
# What's the difference between baseline and endline
# we probably dont need any of the other miss columns
# Beginning of post-intervention: 1st September 2015

df_handy = df %>% 
  dplyr::select(group, c_month)

pth = paste("data/Tanzania/data/existing pts/", "3ie_exist_vis.dta", sep="")
df = data.frame(read.dta(pth))
write.csv(df, "existing_patients.csv")


# Intervention miss a lot more? -> (they also have more patients, I think)
aggregate(df$miss, by=list(df$interv), FUN=sum, na.rm=TRUE)

# for proper plot, sum up by month

df$plt_visit_date = as.factor(format(as.Date(df$c_visitdate, format="%Y-%m-%d"), "%Y-%m"))
df_plt = aggregate(df$miss, by=list(df$interv, df$plt_visit_date), FUN=mean)


plt = ggplot(df_plt) + 
  geom_point(aes(x=Group.2, y=x, color=Group.1))
plt





