library(tidyverse)
library(CausalImpact)
library(foreign)
library(ggplot2)

### RCT data


# check baseline data
pth = paste("data/Tanzania/data/baseline/", "3ie_base_visit.dta", sep="")
df_raw= data.frame(read.dta(pth))

# check data
pth = paste("data/Tanzania/data/existing pts/", "3ie_exist_vis.dta", sep="")
df_raw = data.frame(read.dta(pth))
write.csv(df, "existing_patients.csv")

df = df_raw %>% 
  dplyr::select(c(interv, c_visitdate, miss)) %>% 
  mutate(c_visitdate = as.Date(c_visitdate, format="%Y-%m-%d"),
         interv = ifelse(interv=="Interv", 1, 0)) %>% 
  mutate(month_visit = (format(c_visitdate, "%Y-%m-01"))) %>% 
  mutate(post_intervention = ifelse(c_visitdate < as.Date("2015-09-01"), 1, 0))
  ### FOR NOW ONLY INTERVENTION
  # filter(interv==1)

df_interv = df %>% 
  filter(interv==1)

df_control = df %>% 
  filter(interv==0)

# plot group averages over time
get_monthly_df = function(param_df, c_name){
  data = aggregate(param_df$miss, by=list(param_df$month_visit), FUN=mean) %>% 
      transmute(!!c_name := x, x = Group.1) %>% 
      drop_na()
  return(data)
}

monthly_interv = get_monthly_df(df_interv, "y_interv")
monthly_control = get_monthly_df(df_control, "y_control")

# feed into CausalImpact
ggplot(monthly_control, aes(x, y)) + 
  geom_point() + 
  geom_smooth(method="lm", se = FALSE)

ci_data <- (zoo(cbind(monthly_interv$y, monthly_control$y), as.Date(data$x)))
pre.period <- as.Date(c("2014-01-01", "2015-08-31"))
post.period <- as.Date(c("2015-09-01", "2016-06-01"))
impact = CausalImpact(ci_data, pre.period, post.period)
plot(impact) 
# + 
  # scale_y_continuous(limits = c(-1, 1))






# --------------------

a = as.Date(df$c_visitdate)
data = zoo(cbind(x_RCT, y_RCT), df$c_visitdate)
pre.period <- as.Date(c("2014-01-01", "2015-09-01"))
post.period <- as.Date(c("2015-09-01", "2016-06-01"))
impact = CausalImpact(data, pre.period, post.period)

set.seed(1)
x1 <- 100 + arima.sim(model = list(ar = 0.999), n = 100)
y <- 1.2 * x1 + rnorm(100)
y[71:100] <- y[71:100] + 10
data <- cbind(y, x1)

time.points <- seq.Date(as.Date("2014-01-01"), by = 1, length.out = 100)
data <- zoo(cbind(y, x1), time.points)
head(data)

# TODO: 
# What's the difference between baseline and endline




### US voter data







