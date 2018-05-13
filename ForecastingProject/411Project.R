setwd("C:\\Users\\jarre\\OneDrive\\411\\Project")

#_____Install Data_____#
AAPL_data <- read.csv("AAPL_data_new.csv")

#_____Plot Data_____#
library(ggplot2)
ggplot(AAPL_data,aes(as.Date(Date),Close)) + geom_line() + labs(x="Date") + 
  ggtitle("AAPL Closing Price")  + 
  theme(plot.title = element_text(hjust = 0.5))

#_____Remove Trend_____#
AAPL_data$Close_Difference <- c(NA, diff(AAPL_data$Close))
ggplot(AAPL_data,aes(as.Date(Date),Close_Difference)) + geom_line() + labs(x="Date") + 
  ggtitle("AAPL Closing Price")  + 
  theme(plot.title = element_text(hjust = 0.5))

#_____Apply Exponential Smoothing_____#
library(fpp2)
library(tidyverse)
# tune optimal alpha parameter
tune_alpha <- function(df,h=100){
  train <- df[0:-h]
  test <- df[(length(df)-h+1):length(df)]
  alpha <- seq(.01, .99, by = .01)
  Accuracy <- NA
  for(i in seq_along(alpha)) {
    fit <- ses(train, alpha = alpha[i], h = 100) # h-100 period out forecast
    Accuracy[i] <- Accuracy(fit, test)[2,2]
  }
  
  # convert to a data frame and idenitify max alpha value
  alpha.fit <- data_frame(alpha, Accuracy)
  alpha.max <- filter(alpha.fit, Accuracy == max(Accuracy))
  return(alpha.max)
}

AAPL_alpha <- tune_alpha(AAPL_data$Close_Difference,h=100)[1,1]
AAPL_data$Close_Diff_SES <- c(NA,ses(AAPL_data$Close_Difference, alpha = AAPL_alpha$alpha, h = 100)$fitted)

# plot
ggplot(AAPL_data,aes(x=as.Date(Date))) + 
  geom_line(aes(y=Close_Difference),color='grey') +
  geom_line(aes(y=Close_Diff_SES),color='blue') +
  labs(x="Date",y="Change") +
  ggtitle("AAPL Closing Price") +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5))

#_____Calculating Features_____#

#__technical indicators__#
library(TTR)
citation('TTR')
# RSI
AAPL_data$RSI <- RSI(AAPL_data$Close,matype='SMA')

# Stochastic Momentum Index (SMI)
AAPL_data$SMI <- SMI(AAPL_data[,c("High","Low","Close")],matype=SMA)[,1]

# Stochastic Oscillator %K
AAPL_data$Stoch <- stoch(AAPL_data[,c("High","Low","Close")],matype=SMA,nFastD=14,nSlowD=14)[,1]

# Williams %R
AAPL_data$WPR <- WPR(AAPL_data[,c("High","Low","Close")])

# ROC
AAPL_data$ROC <- ROC(AAPL_data$Close)

# Moving Average Convergence / Divergence (MACD) Oscillator
AAPL_data$MACD <- MACD(AAPL_data$Close, maType = "EMA")[,1]
AAPL_data$MACD_Sig <- MACD(AAPL_data$Close, maType = "EMA")[,2]

# OBV
AAPL_data$OBV <- OBV(AAPL_data[,"Close"], AAPL_data[,"Volume"])

#__Search Data Features__#
library(pracma)

create_ma <- function(df,ma,name){
  for(i in ma){
    df[,paste(name,"_Stock_RSI_Change",sep="")] = c(NA,diff(RSI(df[,paste(name,"_Stock_Normalized_Daily",sep="")], matype="SMA")))
    df[,paste(name,"_RSI_Change",sep="")] = c(NA,diff(RSI(df[,paste(name,"_Normalized_Daily",sep="")], matype="SMA")))
    
    df[,paste(name,"_Stock_SMA",i,sep="")] = movavg(df[,paste(name,"_Stock_Normalized_Daily",sep="")], i, "s")
    df[,paste(name,"_Stock_SMA",i,"_Change",sep="")] = c(NA,diff(df[,paste(name,"_Stock_SMA",i,sep="")]))
    df[,paste(name,"_Stock_Disparity",i,sep="")] = df[,paste(name,"_Stock_Normalized_Daily",sep="")]/df[,paste(name,"_Stock_SMA",i,sep="")]
    df[,paste(name,"_Stock_Disparity",i,"_Change",sep="")] = c(NA,diff(df[,paste(name,"_Stock_Disparity",i,sep="")]))
    
    df[,paste(name,"_Stock_EMA",i,sep="")] = movavg(df[,paste(name,"_Stock_Normalized_Daily",sep="")], i, "s")
    df[,paste(name,"_Stock_EMA",i,"_Change",sep="")] = c(NA,diff(df[,paste(name,"_Stock_SMA",i,sep="")]))
    
    df[,paste(name,"_SMA",i,sep="")] = movavg(df[,paste(name,"_Normalized_Daily",sep="")], i, "s")
    df[,paste(name,"_SMA",i,"_Change",sep="")] = c(NA,diff(df[,paste(name,"_SMA",i,sep="")]))
    df[,paste(name,"_Disparity",i,sep="")] = df[,paste(name,"_Normalized_Daily",sep="")]/df[,paste(name,"_SMA",i,sep="")]
    df[,paste(name,"_Disparity",i,"_Change",sep="")] = c(NA,diff(df[,paste(name,"_Disparity",i,sep="")]))
    
    df[,paste(name,"_EMA",i,sep="")] = movavg(df[,paste(name,"_Normalized_Daily",sep="")], i, "s")
    df[,paste(name,"_EMA",i,"_Change",sep="")] = c(NA,diff(df[,paste(name,"_EMA",i,sep="")]))
    
  }
  return(df)
}

ma <- c(6,8,10,20)
AAPL_data <- create_ma(AAPL_data,ma=ma,name="Apple")

#_____Create Target_____#
library(data.table)
forecast_out = c(3,5,15,30)

for(f in forecast_out){
  AAPL_data[,paste("T",f,sep="")] <- sign(shift(AAPL_data$Close,n=f,fill=NA,type=c("lead")) - AAPL_data$Close)
  AAPL_data[,paste("T",f,sep="")][AAPL_data[,paste("T",f,sep="")] == 1] <- 1
  AAPL_data[,paste("T",f,sep="")][AAPL_data[,paste("T",f,sep="")] <= 0] <- 0
  AAPL_data[,paste("T",f,sep="")] <- as.factor(AAPL_data[,paste("T",f,sep="")])
}

# Remove All NAs to get full data set
AAPL_data <- na.omit(AAPL_data)
rownames(AAPL_data) <- seq(1:nrow(AAPL_data))

# Create X and Y
AAPL_Y <- AAPL_data[,c("T3","T5","T15","T30")]
AAPL_X <- AAPL_data[,!(colnames(AAPL_data) %in% c("Date","Apple_Stock_Normalized_Daily","Apple_Normalized_Daily","T3","T5","T15","T30","Open","High","Low","Close","Volume","Adj.Close","Close_Difference"))]

write.csv(AAPL_Y,"AAPL_Y.csv")
write.csv(AAPL_X,"AAPL_X.csv")
#_____RFE_____#
library(mlbench)
library(caret)

set.seed(123)
AAPL_X_Train <- AAPL_X[1:(0.5*nrow(AAPL_X)),]
AAPL_Y_Train <- AAPL_Y[1:(0.5*nrow(AAPL_Y)),]

# define the control using a random forest selection function
control <- rfeControl(functions=rfFuncs, method="cv", number=5)

# run the RFE algorithm
AAPL_results_T3 <- rfe(x=AAPL_X_Train, y=AAPL_Y_Train[,"T3"], sizes=c(1:20), rfeControl=control)
AAPL_results_T5 <- rfe(x=AAPL_X_Train, y=AAPL_Y_Train[,"T5"], sizes=c(1:20), rfeControl=control)
AAPL_results_T15 <- rfe(x=AAPL_X_Train, y=AAPL_Y_Train[,"T15"], sizes=c(1:20), rfeControl=control)
AAPL_results_T30 <- rfe(x=AAPL_X_Train, y=AAPL_Y_Train[,"T30"], sizes=c(1:20), rfeControl=control)

# list the chosen features
AAPL_pred_T3 <- predictors(AAPL_results_T3)
AAPL_pred_T5 <- predictors(AAPL_results_T5)
AAPL_pred_T15 <- predictors(AAPL_results_T15)
AAPL_pred_T30 <- predictors(AAPL_results_T30)

l = max(c(length(AAPL_pred_T3),length(AAPL_pred_T5),length(AAPL_pred_T15),length(AAPL_pred_T30)))
AAPL_T3 <- c(AAPL_pred_T3,rep.int(NA,(l-length(AAPL_pred_T3))))
AAPL_T5 <- c(AAPL_pred_T5,rep.int(NA,(l-length(AAPL_pred_T5))))
AAPL_T15 <- c(AAPL_pred_T15,rep.int(NA,(l-length(AAPL_pred_T15))))
AAPL_T30 <- c(AAPL_pred_T30,rep.int(NA,(l-length(AAPL_pred_T30))))

AAPL_features <- data.frame(T3=AAPL_T3,T5=AAPL_T5,T15=AAPL_T15,T30=AAPL_T30)
write.csv(AAPL_features,"Selected_Features.csv")

#AAPL_features <- read.csv("Selected_Features.csv")

#____Plot RFE_____#
library(ggrepel)

Apple_T3_Results <- AAPL_results_T3$results
Apple_T3_Results$Target <- "T3"
Apple_T5_Results <- AAPL_results_T5$results
Apple_T5_Results$Target <- "T5"
Apple_T15_Results <- AAPL_results_T15$results
Apple_T15_Results$Target <- "T15"
Apple_T30_Results <- AAPL_results_T30$results
Apple_T30_Results$Target <- "T30"

Apple_T3_Results_max <- Apple_T3_Results[Apple_T3_Results$Accuracy == max(Apple_T3_Results$Accuracy),]
Apple_T5_Results_max <- Apple_T5_Results[Apple_T5_Results$Accuracy == max(Apple_T5_Results$Accuracy),]
Apple_T15_Results_max <- Apple_T15_Results[Apple_T15_Results$Accuracy == max(Apple_T15_Results$Accuracy),]
Apple_T30_Results_max <- Apple_T30_Results[Apple_T30_Results$Accuracy == max(Apple_T30_Results$Accuracy),]

Apple_RFE_all <- rbind(Apple_T3_Results,Apple_T5_Results,Apple_T15_Results,Apple_T30_Results)
Apple_RFE_all$Target <- as.factor(Apple_RFE_all$Target)
Apple_RFE_all$Target <- relevel(relevel(relevel(relevel(Apple_RFE_all$Target,"T30"),"T15"),"T5"),"T3")

ggplot(Apple_RFE_all, aes(Variables,Accuracy,color=Target)) + 
  geom_line() + 
  geom_point() +
  ylim(0.5,0.95) +
  ggtitle("AAPL RFE Results for Targets 3, 5, 15, and 30") +
  theme(plot.title = element_text(hjust = 0.5)) +
  geom_point(data = Apple_T3_Results_max,color='red',size=2) +
  geom_text_repel(data = Apple_T3_Results_max, aes(Variables,Accuracy,label=round(Accuracy,2)),nudge_y = 0.030,show.legend = FALSE) +
  geom_point(data = Apple_T15_Results_max,color='blue',size=2) +
  geom_text_repel(data = Apple_T15_Results_max, aes(Variables,Accuracy,label=round(Accuracy,2)),nudge_y = -0.030,show.legend = FALSE) +
  geom_point(data = Apple_T5_Results_max,color='green',size=2) +
  geom_text_repel(data = Apple_T5_Results_max, aes(Variables,Accuracy,label=round(Accuracy,2)),nudge_y = 0.030,show.legend = FALSE) +
  geom_point(data = Apple_T30_Results_max,color='purple',size=2) +
  geom_text_repel(data = Apple_T30_Results_max, aes(Variables,Accuracy,label=round(Accuracy,2)),nudge_y = 0.025,show.legend = FALSE)

#_____Run Random Forest_____#

library(randomForest)
cv_rf <- function(y,x,row,n){
  set.seed(123) #Seed set to 123 for reproducability
  n.end <- nrow(x)-row
  actual <- y[row:nrow(x)]
  predicted <- vector()
  actual <- vector()
  for(i in 1:n.end+1){
    train_x <- x[1:(row-2+i),]
    train_y <- y[1:(row-2+i)]
    test_x <- x[(row-1+i),]
    rf <- randomForest(train_y~.,data=train_x,ntree=n)
    pred <- predict(rf,newdata=test_x)
    predicted[i] = pred
    actual[i] <- y[(row-1+i)]
  }
  r <- data.frame(Predicted=predicted,Actual=actual)
  tp <- nrow(r[r$Predicted == 2 & r$Actual == 2,])
  tn <- nrow(r[r$Predicted == 1 & r$Actual == 1,])
  fp <- nrow(r[r$Predicted == 2 & r$Actual == 1,])
  fn <- nrow(r[r$Predicted == 1 & r$Actual == 2,])
  
  ac <- (tp+tn)/(tp+tn+fp+fn)
  pr <- tp/(tp+fp)
  re <- tp/(tp+fn)
  sp <- tn/(tn+fp)
  
  data.frame(Accuracy=ac,Precision=pr,Recall=re,Specificity=sp)
}

AAPL_X_T3 <- AAPL_X[,(colnames(AAPL_X) %in% AAPL_pred_T3)]
AAPL_X_T5 <- AAPL_X[,(colnames(AAPL_X) %in% AAPL_pred_T5)]
AAPL_X_T15 <- AAPL_X[,(colnames(AAPL_X) %in% AAPL_pred_T15)]
AAPL_X_T30 <- AAPL_X[,(colnames(AAPL_X) %in% AAPL_pred_T30)]

AAPL_rf3 <- cv_rf(AAPL_Y[,"T5"],AAPL_X_T3,503,25)
AAPL_rf5 <- cv_rf(AAPL_Y[,"T5"],AAPL_X_T5,503,25)
AAPL_rf15 <- cv_rf(AAPL_Y[,"T15"],AAPL_X_T15,503,25)
AAPL_rf30 <- cv_rf(AAPL_Y[,"T30"],AAPL_X_T30,503,25)

final_AAPL_rf <- rbind(AAPL_rf3,AAPL_rf5,AAPL_rf15,AAPL_rf30)
rownames(final_AAPL_rf) <- c("3 Step","5 Step","15 Step","30 Step")
final_AAPL_rf
write.csv(final_AAPL_rf,"RF_AAPL_Results.csv")

final_AAPL_rf$Company <- "AAPL"
final_AAPL_rf$Step <- rownames(final_AAPL_rf)
final_AAPL_rf$Step <- relevel(relevel(relevel(relevel(as.factor(final_AAPL_rf$Step),"30 Step"),"15 Step"),"5 Step"),"3 Step")
ggplot(final_AAPL_rf,aes(x=Company,y=Accuracy,fill=Step)) + geom_bar(stat="Identity",position="dodge") + ggtitle("AAPL Random Forest Accuracy Results") + theme(plot.title = element_text(hjust = 0.5))

#_____Comparing Models without Search Data_____#

AAPL_X_TI <- AAPL_X[,c("RSI","SMI","Stoch","WPR","ROC","MACD","MACD_Sig","OBV")]
AAPL_rf3_TI <- cv_rf(AAPL_Y[,"T3"],AAPL_X_TI,503,25)
AAPL_rf5_TI <- cv_rf(AAPL_Y[,"T5"],AAPL_X_TI,503,25)
AAPL_rf15_TI <- cv_rf(AAPL_Y[,"T15"],AAPL_X_TI,503,25)
AAPL_rf30_TI <- cv_rf(AAPL_Y[,"T30"],AAPL_X_TI,503,25)

final_TI <- rbind(AAPL_rf3_TI,AAPL_rf5_TI,AAPL_rf15_TI,AAPL_rf30_TI)
rownames(final_TI) <- c("3 Step","5 Step","15 Step","30 Step")
write.csv(final_TI,"RFTI.csv")

ggplot(AAPL_data, aes(x=as.Date(Date))) + 
  geom_line(aes(y=Apple_Stock_Normalized_Daily, color="blue")) +
  geom_line(aes(y=Apple_Normalized_Daily, color="red")) +
  scale_color_manual(labels = c("'Apple Stock' Google Web Search", "'Apple' Google News Search"), values = c("blue", "red")) +
  theme_bw() +
  theme(legend.position="top") +
  theme(legend.title=element_blank()) +
  ylab("Search Volume Score") +
  xlab("Date")

citation('TTR')
