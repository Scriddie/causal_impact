library(tidyverse)
library(CausalImpact)
library(foreign)


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












