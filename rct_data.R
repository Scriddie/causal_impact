rm(list=ls())
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

df = df_raw %>% 
  dplyr::select(c(interv, c_visitdate, miss)) %>% 
  mutate(c_visitdate = as.Date(c_visitdate, format="%Y-%m-%d"),
         interv = ifelse(interv=="Interv", 1, 0)) %>% 
  mutate(month_visit = (format(c_visitdate, "%Y-%m-01")),
         ones = 1) %>% 
  mutate(post_intervention = ifelse(c_visitdate < as.Date("2015-09-01"), 1, 0))

# visualize complete time series -> we see strong periodicity and a low number of obs near end
ggplot(data=df, aes(x=c_visitdate, y=ones, color=interv)) + 
  stat_summary(fun.y=sum, geom="line")

# we have too few data points in the end, hence we just cut off after treatment period
df = df %>% 
  filter(month_visit < as.Date("2016-01-1"))

# create separate dataframes for treatment and control
df_interv = df %>% 
  filter(interv==1)
df_control = df %>% 
  filter(interv==0)

# plot group averages over time
get_monthly_df = function(param_df, col_name){
  data = aggregate(param_df$miss, by=list(param_df$month_visit), FUN=mean) %>% 
      transmute(!!col_name := x, x = Group.1) %>% 
      drop_na()
  return(data)
}

# create separate column for treatment and control group
monthly_interv = get_monthly_df(df_interv, "y_interv")
monthly_control = get_monthly_df(df_control, "y_control")

x_rct = as.Date(monthly_interv$x)
y_interv = monthly_interv$y_interv
y_control = monthly_control$y_control

# # intervention vs control
# ggplot(ci_data) +
#   geom_line(aes(x_rct, y_control, color=0)) +
#   geom_line(aes(x_rct, y_interv, color=1))

# beginning of intervention
pre.period <- as.Date(c("2014-01-01", "2015-08-31"))
post.period <- as.Date(c("2015-09-01", "2016-06-01"))

# without counterfactuals
impact = CausalImpact((zoo(cbind(y_interv, x_rct), x_rct)),
                      pre.period, post.period)
plot(impact)
summary(impact)
summary(impact, "report")

# including counterfactuals
impact_counterfact = CausalImpact((zoo(cbind(y_interv, y_control, x_rct), x_rct)),
                      pre.period, post.period)

plot(impact_counterfact)
summary(impact_counterfact)
summary(impact_counterfact, "report")


### Including other covariates does not make a noticible difference
# df_covar =  df_raw %>% 
#   dplyr::select(c(interv, c_visitdate, age_cat, who_stage, marstat)) %>% 
#   mutate(c_visitdate = as.Date(c_visitdate, format="%Y-%m-%d"),
#          interv = ifelse(interv=="Interv", 1, 0)) %>% 
#   mutate(month_visit = (format(c_visitdate, "%Y-%m-01")),
#          ones = 1) %>% 
#   mutate(post_intervention = ifelse(c_visitdate < as.Date("2015-09-01"), 1, 0)) %>% 
#   filter(month_visit < as.Date("2016-01-1")) %>% 
#   mutate(
#     age_cat = as.numeric(age_cat),
#     who_stage = as.numeric(who_stage),
#     marstat = as.numeric(marstat)
#   ) %>% 
#   filter(interv==1) %>% 
#   drop_na()
# 
# df_covar_agg = aggregate(df_covar, by=list(df_covar$month_visit), FUN=mean)
# covar_age = df_covar_agg$age_cat
# covar_who_stage = df_covar$who_stage
# covar_marstat = df_covar$marstat
# impact_covar = CausalImpact(
#   (zoo(cbind(y_interv, covar_age, x_rct), x_rct)),
#   pre.period, post.period
# )
# plot(impact_covar)
# summary(impact_covar)

# TODO: What's the difference between baseline and endline?
# TODO: interpred difference between graph with counterfactuals and without, does it match expectations
# given how their package works?
# TODO: Do results including counterfactuals come close to results in report? Check thoroughtly!
# check summary and graph
# TODO: outline end of intervention period
# TODO: instead of the actual counterfactuals, give it some of the other variables form the data set as 
# covariates - Can we say the same as "Using purely observational variables led to the same substantive 
# conclusions"??
# TODO: use some other variables from data set to estimate causal impact of intervention on control group!
# TODO: try giving it some random nonesense as covariate time series (e.g. Quandl library)

