rm(list=ls(all=TRUE))

library(tidyverse)
library(CausalImpact)
library(foreign)
library(ggplot2)
library(gsynth)
data(gsynth)  # loads simdata and tournout


df_turnout = turnout
CUTOFF_YEAR = 1996
PLOT_ALL = FALSE
SAVE_DATA = FALSE

# lil plotling function
plt_ts = function(df){
  ggplot(data=df) + 
    geom_point(aes(x=year, y=turnout, color=interv)) # + 
    # scale_x_continuous(limits=c(-13, 4))
}

get_treatment_start = function(df){
  # if we wanted to do the same scaling as the guy
  for (i in unique(df$abb)){
    df_state = df %>% 
      filter(abb==i) %>% 
      filter(policy_edr==1)
    policy_start = min(df_state$year, 9999)
    if (policy_start != 9999){
      print(paste(i, "started in", policy_start))
    }
    # TODO: reset year conditinally (won't work with CausalImpact anymore)
    # df_turnout
  }
}

get_treatment_start(df_turnout)

### For now analysis only for the early states: ME, MN, WI; 1976
### TODO: We drop other states that have an intervention later. Is this necessary or should we cut df?
df_repl_1 = df_turnout %>% 
  mutate(interv = ifelse(abb %in% c("ME", "MN", "WI"), 1, 0)) %>% 
  # filter(!(abb %in% c("ID", "NH", "WY", "MT", "IA", "CT"))) %>% 
  filter(year<CUTOFF_YEAR) %>%  # This way we can be sure we see no other states with interventions
  dplyr::select(year, turnout, interv)

if (PLOT_ALL) plt_ts(df_repl_1)


# aggregate data frame by year (to be done for treatment and control)
agg_df = function(df, col_name){
  df_pp = aggregate(df$turnout, by=list(df$year), FUN=mean) %>% 
    transmute(
      !!col_name:=x,
      year=Group.1
    )
  return(df_pp)
}

# create separate data frames for control and intervention
df_interv = df_repl_1 %>% 
  filter(interv==1) %>% 
  dplyr::select(year, turnout)
df_control = df_repl_1 %>% 
  filter(interv==0) %>% 
  dplyr::select(year, turnout)

agg_interv = agg_df(df_interv, "turnout_interv")
agg_control = agg_df(df_control, "turnout_control")

# bing into format expected by CausalImpact
x = seq_along(as.numeric(agg_interv$year))
y_interv = agg_interv$turnout_interv
y_control = agg_control$turnout_control
data = cbind(y_interv, y_control, x)
head(data)

# beginning of intervention for early df
pre.period = c(1, 14)  # agg_interv$year[15] is 1976
post.period = c(15, 19)
impact = CausalImpact(data, pre.period, post.period)
plot(impact)
if (SAVE_DATA){
  ggsave("figures/CI_voter_data.png", plot(impact), device="png", width=7, height=4)
}

summary(impact, "report")

### ----------------------------------------------------------------------

## Generalized Synthetic Control Method
## Replicatino Material: EDR on Voter Turnout

## Author: Yiqing Xu



df_repl_2 = df_turnout %>% 
  mutate(interv = ifelse(abb %in% c("ME", "MN", "WI", "ID", "NH", "WY", "MT", "IA", "CT"), 1, 0)) %>% 
  filter(year<CUTOFF_YEAR) %>% 
  dplyr::select(-policy_mail_in, -policy_motor, -interv)

df_turnout %>%
  filter(abb=="CT")

if(PLOT_ALL){
  ggplot(df_repl_2, aes(x=year, y=turnout)) +
    stat_summary(fun.y="mean", geom="line") +
    scale_x_continuous(limits=c(1920, 1984))
}


# Warning, gsynth calculates only half the values if all the treatment starts at the same time!
# this will require some manual calculations when plotting

out = gsynth(turnout ~ policy_edr,
                 data = df_repl_2, index =c("abb", "year"),
                 force = "two-way", CV = TRUE, r=c(0,5), se = TRUE,
                 parallel = FALSE, nboots=2000, seed = 2139)

# If this is not the case, our treatments start at different times which is no good for CausalImpact
stopifnot(is.null(out$eff.cnt))

## first look (not in the paper)
# plot(out.syn2, type = "raw")
# plot(out.syn2, type = "counterfactual")

## GSC ##
if (SAVE_DATA){
  png("figures/fg_edr_main_syn.png",width=14,height=5,units="in", res=350)
}
## counterfactual
par(mfcol=c(1,2),mar=c(4,4,1,1),lend=1)
time<-c(1:19)
plot(1,type="n",xlab="",ylab='',axes=F,xlim=range(time),ylim=c(45,80))
box()
axis(1,at=seq(1,19,2));mtext("Term Relative to Reform",1,2.5,cex=1.5)
axis(2);mtext("Turnout %",2,2.5,cex=1.5)
abline(v=14,col="gray",lwd=2,lty=2)
mean(df_repl_2[df_repl_2$year==1940, "turnout"])
### This only works if the treatments dont start at the same time bc user friendliness doesnt matter
# lines(time, out$Y.tr.cnt[1:18], lwd=2)
# lines(time, out$Y.ct.cnt[1:18], col=1, lty=5, lwd=2)
### Now we have to calculate everything by hand, it's a pain, believe me
real_line = rowMeans(out$Y.tr) %>% setNames(time)
est_line = rowMeans(out$Y.ct) %>% setNames(time)
lines(time, real_line[1:19], lwd=2)
lines(time, est_line[1:19], col=1, lty=5, lwd=2)
### finally done with this nonsense
legend("topleft",legend=c("Treated Average","Estimated Y(0) Average for the Treated"),cex=1.5,
       seg.len=2, col=c(1,1),lty=c(1,5),lwd=2,bty="n") 
## gap
newx<-c(1:19)
plot(1,type="n",xlab="",ylab='',axes=F,xlim=c(1,19),ylim=c(-5,10))
box()
axis(1,at=seq(1,19,2));mtext("Term relative to reform",1,2.5,cex=1.5)
axis(2,at=seq(-10,10,2));mtext("Turnout %",2,2.5,cex=1.5)
abline(v=14,col="gray",lty=2,lwd=2)
abline(h=0,col="gray20",lty=2,lwd=1)
polygon(c(rev(newx), newx), c(rev(out$est.att[1:19,3]), out$est.att[1:19,4]),
        col = "#55555530", border = NA)
lines(newx,out$est.att[1:19,1],col=1,lty=1,lwd=2)
legend("topleft",legend=c("Estimated ATT","95% Confidence Intervals"), cex=1.5, seg.len=2,
       col=c(1,"#55555530"),lty=c(1,5),lwd=c(2,20),bty="n")
if (SAVE_DATA){
  graphics.off()
}


### Other interesting stuff:
# unobserved factors
out$r.cv

