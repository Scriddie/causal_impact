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

# create separate dataframes for treatment and control
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

# create separate column for treatment and control group
monthly_interv = get_monthly_df(df_interv, "y_interv")
monthly_control = get_monthly_df(df_control, "y_control")

x_rct = as.Date(monthly_interv$x)
y_interv = monthly_interv$y_interv
y_control = monthly_control$y_control
ci_data <- (zoo(cbind(y_interv, y_control, x_rct), x_rct))

# intervention vs control
ggplot(ci_data) +
  geom_line(aes(x_rct, y_control, color=0)) +
  geom_line(aes(x_rct, y_interv, color=1))

# feed into CausalImpact
pre.period <- as.Date(c("2014-01-01", "2015-08-31"))
post.period <- as.Date(c("2015-09-01", "2016-06-01"))
impact = CausalImpact(ci_data, pre.period, post.period)
plot(impact) 


# TODO: 
# What's the difference between baseline and endline




### US voter data
# pth = paste("data/Tanzania/data/baseline/", "3ie_base_visit.dta", sep="")
# df_raw= data.frame(read.dta(pth))








