#Plan
#Date/Time exploration
#Regional Exploration
#RFM  (Recency, Frequency, Monetary) Analysis

library(readr)
library(dplyr)
library(ggplot2)
library(DataExplorer)
library(lubridate)
setwd('/Users/adriandevos/Desktop/')
data<-read.csv("ecomm.csv")
plot_missing(data)
data <- na.omit(data) #This removes 135080 observations
dim(data)


data$Date<-as.Date(data$InvoiceDate, format="%m/%d/%Y")
data$month<-format(data$Date, "%m")
data$year<-format(data$Date, "%Y")
data$Time<-format(strptime(data$InvoiceDate,"%m/%d/%Y %H:%M"),'%H:%M')
data$hours<-format(strptime(data$Time,"%H:%M"),'%H')


data$dow<-weekdays(as.POSIXct(data$Date), abbreviate = F)
data$dow<-as.factor(data$dow)
data$dow <- ordered(data$dow, levels=c("Monday", "Tuesday", "Wednesday", "Thursday", 
                                         "Friday", "Saturday", "Sunday"))

data<-data %>%
  mutate(TotalSale = Quantity * UnitPrice)
cols<-c("month", "year","hours")
data[cols] <- lapply(data[cols], factor)

options(repr.plot.width=8, repr.plot.height=3)


ggplot(data,aes(x = Date, y = TotalSale)) + 
  stat_summary(fun.y = sum, geom="line")+
  scale_x_date(date_labels="%m/%y",date_breaks  ="1 month")+
  theme_minimal() + 
  labs(x = 'Date', y = 'Revenue (£)', title = 'Revenue by Date')


ggplot(data,aes(x = dow, y = TotalSale, color=dow,fill=dow)) + 
  geom_col()+
stat_summary(fun = sum)+ 
  scale_y_continuous(expand = c(0,0),
                     limits = c(0,2000000)) +
  labs(x = 'Day of Week', y = 'Revenue (£)', title = 'Revenue by Day of Week')

data2<-data %>%
  group_by(month,hours) %>%
  summarise(revenue = sum(Quantity * UnitPrice),
            transactions = n_distinct(InvoiceNo))
data2$transactions<-as.numeric(data2$transactions)

ggplot(data2, aes(x = hours, y = transactions)) +
  geom_col() +
  theme_minimal() +
  labs(x="Hour of the Day", y="Transactions", title="Transactions Per Hour")


ggplot(data,aes(x = hours, y = TotalSale)) + 
  geom_col() + 
  stat_summary(fun = sum)+ 
  scale_y_continuous(labels=comma,limits = c(0,2000000)) +
  labs(x = 'Hour Of Day', y = 'Revenue (£)',
       title = 'Revenue by Hour Of Day')

topCountries <- data %>%
  filter(Country == 'Netherlands' 
         | Country == 'EIRE' 
         | Country == 'Germany' 
         | Country == 'France' 
         | Country == 'Australia' 
         | Country == 'USA')

topCountries <- topCountries %>%
  group_by(Country, Date) %>%
  summarise(revenue = sum(TotalSale), transactions = n_distinct(InvoiceNo), customers = n_distinct(CustomerID)) %>%
  mutate(aveOrdVal = (round((revenue / transactions),2))) %>%
  ungroup() %>%
  arrange(desc(revenue))


#ggplot(topCountries, aes(x = Date, y = aveOrdVal, colour = Country)) + 
  geom_point()+
  scale_y_continuous(expand = c(0,0), limits = c(0,10000))+
  labs(x = ' Country', y = 'Average Order Price (£)', title = "Average Order Prices")

ggplot(topCountries, aes(x = Date, y = revenue, colour = Country)) + 
  geom_smooth(method = 'auto', se = FALSE) + 
  labs(x = ' Country', y = 'Revenue (£)', title = 'Revenue by Country over Time')
seasonal<-data
seasonal$monthabb <- sapply(seasonal$month, function(x) month.abb[as.numeric(x)])
seasonal$monthabb = factor(seasonal$monthabb, levels = month.abb)

seasonal %>%
  group_by(monthabb) %>% summarize(avg=mean(TotalSale)) %>%
  ggplot(aes(x=monthabb, y=avg)) + geom_point(color="#F35D5D", aes(size=avg)) + geom_line(group=1, color="#7FB3D5") + 
  theme_minimal() + theme(legend.position="none") + 
  scale_y_continuous(labels=scales::dollar_format())+
  labs(title="Seasonality Trend", y="Average Sale", x="Month")

#Unit Price
seasonal %>%
  group_by(monthabb) %>% summarize(avg=mean(UnitPrice)) %>%
  ggplot(aes(x=monthabb, y=avg)) + geom_point(color="#F35D5D", aes(size=avg)) + geom_line(group=1, color="#7FB3D5") + 
  theme_minimal() + theme(legend.position="none") + 
  scale_y_continuous(labels=scales::dollar_format())+
  labs(x="Month", y="Average Price of Unit", title="Seasonality Trends")


RFM1 = data %>% 
  group_by(CustomerID) %>% 
  summarise(Recency =as.numeric(as.Date("2012-01-01")-max(Date)),
            Frequency =n_distinct(InvoiceNo), Monetary = sum(TotalSale)/n_distinct(InvoiceNo)) 

RFM1= RFM1 %>% filter (Monetary>0)

quantile(RFM1$Recency) #Check quantiles for subsetting
quantile(RFM1$Frequency)#Check quantiles for subsetting
quantile(RFM1$Monetary)#Check quantiles for subsetting
summary(RFM1)

#Categorize into quantiles
RFM1$R_Score[RFM1$Recency>=23 & RFM1$Recency<39] = 1
RFM1$R_Score[RFM1$Recency>=39& RFM1$Recency<72] = 2
RFM1$R_Score[RFM1$Recency>=72 & RFM1$Recency<161] = 3
RFM1$R_Score[RFM1$Recency>=161 & RFM1$Recency<=396] = 4

RFM1$F_Score[RFM1$Frequency<=1] = 1
RFM1$F_Score[RFM1$Frequency>=2 & RFM1$Frequency<=3] = 2
RFM1$F_Score[RFM1$Frequency>=4 & RFM1$Frequency<=5] = 3
RFM1$F_Score[RFM1$Frequency>5] = 4

RFM1$M_Score[RFM1$Monetary< 153] = 1
RFM1$M_Score[RFM1$Monetary>=153 & RFM1$Monetary<237] = 2
RFM1$M_Score[RFM1$Monetary>=237 & RFM1$Monetary<371 ] = 3
RFM1$M_Score[RFM1$Monetary>=371] = 4

RFM1 = RFM1 %>% mutate(RFM_Score = 100*R_Score + 10*F_Score+M_Score)
RFM1$segmentRFM = NULL
champions = c(144)
loyal_customers = c(221,212,243,234,241,242,244)
potential_loyalist = c(131,133,142,124,132,123,143,134,114,113,141,231,213,214)
recent_customers = c(122,111)
promising = c(121,112,211)
needing_attention = c(222,232,233,223,224)
about_to_sleep = c(322,321,332,323,322,314,313)
at_risk = c(334,343,344,333,342,324,432,431,331,341)
cant_lose = c(443,434,433,444,442,424,423,441,414,413)
hibernating = c(412,421,422,311,312)
lost = c(411)
RFM1$segmentRFM = 'abc'
RFM1$segmentRFM[which(RFM1$RFM_Score %in% champions)] = "Champions"
RFM1$segmentRFM[which(RFM1$RFM_Score %in% loyal_customers)] = "Loyal Customers"
RFM1$segmentRFM[which(RFM1$RFM_Score %in% potential_loyalist)] = "Potential Loyalist"
RFM1$segmentRFM[which(RFM1$RFM_Score %in% recent_customers)] = "Recent customers"
RFM1$segmentRFM[which(RFM1$RFM_Score %in% promising)] = "Promising"
RFM1$segmentRFM[which(RFM1$RFM_Score %in% needing_attention)] = "Customer Needing Attention"
RFM1$segmentRFM[which(RFM1$RFM_Score %in% about_to_sleep)] = "About to Sleep"
RFM1$segmentRFM[which(RFM1$RFM_Score %in% at_risk)] = "At Risk"
RFM1$segmentRFM[which(RFM1$RFM_Score %in% cant_lose)] = "Can't Lose Them"
RFM1$segmentRFM[which(RFM1$RFM_Score %in% hibernating)] = "Hibernating"
RFM1$segmentRFM[which(RFM1$RFM_Score %in% lost)] = "Lost"


data %>%
  filter(year == 2011) %>%
  group_by(month) %>%
  summarise(transactions = n_distinct(InvoiceNo),
            ARPU = sum(Quantity * UnitPrice) / transactions) %>%
  ggplot(aes(x = month, y = ARPU)) +
  geom_line() +
  geom_point(aes(size = transactions)) +
  theme_minimal() +
  scale_y_continuous(labels=scales::dollar_format())+
  labs(title="Average revenue per user", y="Average Revenue per User", x="Month")

Customer_segmentation = RFM1 %>%
  group_by(segmentRFM) %>%
  summarise(No.ofcustomer = n()) %>%
  arrange(desc(No.ofcustomer)) %>%
  ungroup()

ggplot(data= Customer_segmentation, aes(x= reorder(as.factor(segmentRFM), No.ofcustomer), y= No.ofcustomer, fill = segmentRFM))+
  geom_bar(stat = "identity") +
  labs(x = "Segment", y = "Total Customer",
       title = "Customer Segmentation") +
  coord_flip()+
  theme(axis.text.x = element_text(angle=65, vjust=0.6))+
  theme(legend.position="none")



