### LOAD PACkages ###
library(devtools)
library(tidyverse)
library(grf)
library(haven)
library(cowplot)
library(DiagrammeR)
library(plotly)
library(Rcpp)
library(writexl)
library(readxl)
library(twang)
library(openxlsx)
library(policytree)
library(maq)
library(lfe)
library(scatterplot3d)
library(DescTools)

cat("\014")
rm(list = ls())

### LOAD DATA  ###
data <- read_excel("C:\\Users\\16654\\Desktop\\论文提升计划\\hetercf.xlsx")
data<- na.omit(data)

winsorize <- function(data, end){
  endpoint <- quantile(data, probs=c(end, 1-end), na.rm = T)
  data[data < endpoint[1]] <- endpoint[1]
  data[data > endpoint[2]] <- endpoint[2]
  return(data)
}

data$roa <- winsorize(data$roa, 0.01)
data$SA <- winsorize(data$SA, 0.01)
data$cf <- winsorize(data$cf, 0.01)

X <- select(data, size, Boardsize, roa, degree, tobinq, ZScore, SA, lev)

Y <- select(data, Flexsum)
Y$Flexsum = Y$Flexsum/2
W <- select(data, tp)

### Convert tibbles into vectors ###
x <- as.matrix(X)
y <- as.matrix(Y)
w <- as.matrix(W) 

### Create test and training sample ###
set.seed(10)
cases <- sample(seq_len(nrow(x)), round(nrow(x)*0.8))
train <- x[cases,]
test <- x[-cases,]

### factorized <- factor(data$Indnme)
### data$Indnme <- as.numeric(factorized)

### Train  Causal Forest via Iteration ###
### Y.hat = data$Y_hat, W.hat = data$W_hat
cf <- causal_forest(x, y, w, honesty = TRUE, num.trees = 1000, min.node.size = 10, ci.group.size = 4)
test_calibration(cf)

### Average Treatment Effect
ATE = average_treatment_effect (cf)
paste(ATE)
paste ("95% CI for the ATE:", round (ATE[1],3),"+/-", round ( qnorm (0.95)*ATE[2],4))

### Compare region wit low and high estimated CATEs
preds <- predict(cf, test)
tau.hat=predict(cf)$prediction
high_effect =tau.hat > median (tau.hat)
ate.high  =average_treatment_effect (cf ,subset = high_effect )
ate.low   =average_treatment_effect (cf ,subset =! high_effect )

paste ("95% CI for difference in ATE:",round ((ate.high [1]-ate.low[1])/2,4),"+/-", round ( qnorm (0.95)* sqrt (ate.high [2]^2+ate.low[2]^2),4))

### Run best linear prediction 
test_calibration(cf)

cf %>% variable_importance() %>% as.data.frame() %>% mutate(variable = colnames(cf$X.orig)) %>% arrange(desc(V1))

preds.hat = predict(cf, test, estimate.variance = TRUE)
sigma.hat = sqrt(preds.hat$variance.estimates)

preds.hat <- as.data.frame(preds.hat)
sigma.hat <- as.data.frame(sigma.hat)


ci.low    = (preds.hat$predictions)-1.96*(sigma.hat$sigma.hat)
ci.high   = (preds.hat$predictions)+1.96*(sigma.hat$sigma.hat)

ci.low    <-as.data.frame(ci.low)
ci.high   <-as.data.frame(ci.high)
test      <-as.data.frame(test)

test <- cbind(test,preds.hat,sigma.hat,ci.low,ci.high)


### Figure 3: Density Function###
ggplot(test, aes(x=predictions)) + geom_density(fill="snow3", color="black", alpha=0.8)  + 
  labs( x = "Estimated CATE", y = "Density") +
  theme_light()


### Figure 4: Cumulative Density Function ### 
ggplot(test, aes(x=predictions)) + stat_ecdf(geom = "step", size=2) + 
  geom_hline(yintercept=0.25, linetype="dashed", color = "black")   +
  geom_hline(yintercept=0.75, linetype="dashed", color = "black")   +
  labs( x = "Estimated CATE", y = "Density") +
  theme_light()


### Estimated Quartiles ### 
quantile(preds.hat$predictions)     



### Plot CATE's of 6 Characteristics in 2 cowplots ### 
p1 <- ggplot (test, aes( x=size, y = predictions ))   +        
  geom_point(size=1) + 
  geom_smooth(level = 0.95) + 
  labs( x = "Size", y = "CATE") +
  theme_light() 

p2 <- ggplot (test, aes( x=lev, y = predictions ))   + 
  geom_point(size=1) + 
  geom_smooth(level = 0.95) + 
  labs( x = "LEV", y = "CATE") +
  theme_light()

p3 <- ggplot (test, aes( x=tobinq, y = predictions ))   + 
  geom_point(size=1) + 
  geom_smooth(level = 0.95) + 
  labs( x = "Tobin Q", y = "CATE") +
  theme_light()

p4 <- ggplot (test, aes( x=degree, y = predictions ))   + 
  geom_point(size=1) + 
  geom_smooth(level = 0.95) + 
  labs( x = "Education Background", y = "CATE") +
  theme_light()

p5 <- ggplot (test, aes( x=roa, y = predictions ))   + 
  geom_point(size=1) + 
  geom_smooth(level = 0.95) + 
  labs( x = "ROA", y = "CATE") +
  theme_light()

p6 <- ggplot (test, aes( x=ZScore, y = predictions ))   + 
  geom_point(size=1) + 
  geom_smooth(level = 0.95) + 
  labs( x = "Z-Score", y = "CATE") +
  theme_light()

p7 <- ggplot (test, aes( x=SA, y = predictions ))   + 
  geom_point(size=1) + 
  geom_smooth(level = 0.95) + 
  labs( x = "SA", y = "CATE") +
  theme_light()

p8 <- ggplot (test, aes( x=Boardsize, y = predictions ))   + 
  geom_point(size=1) + 
  geom_smooth(level = 0.95) + 
  labs( x = "Boardsize", y = "CATE") +
  theme_light()

plot_grid(p1, ncol =1, rel_widths = 1)
plot_grid(p2, ncol =1, rel_widths = 1)
plot_grid(p3, ncol =1, rel_widths = 1)
plot_grid(p4, ncol =1, rel_widths = 1)
plot_grid(p5, ncol =1, rel_widths = 1)
plot_grid(p6, ncol =1, rel_widths = 1)
plot_grid(p7, ncol =1, rel_widths = 1)
plot_grid(p8, ncol =1, rel_widths = 1)


###
tree_1 = get_tree(cf, 1)
plot(tree_1)

###



