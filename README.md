# Ecommerce-EDA
An exploratory data analysis of E-Commerce data provided graciously by the UCI Machine Learning Repository

Load required libraries and load data
```
library(readr)
library(dplyr)
library(ggplot2)
library(DataExplorer)
library(lubridate)

data<-read.csv("ecomm.csv")
```
```
data <- na.omit(data)
dim(data)
```

> [1] [406829]      [8]
Check and remove observations with NA values as they are not useful for our analysis. Were left with:

405829 Observations
8 Columns

## Data cleanup
We first need to reformat and reorganize some columns. We'll use the InvoiceDate column to generate extradate/time related data for analysis
```
data$Date<-as.Date(data$InvoiceDate, format="%m/%d/%Y") #Reformat to date variable
data$month<-format(data$Date, "%m") #extract month value
data$year<-format(data$Date, "%Y") #extract year value
data$Time<-format(strptime(data$InvoiceDate,"%m/%d/%Y %H:%M"),'%H:%M') #Exract POSIXct time value
data$hours<-format(strptime(data$Time,"%H:%M"),'%H') #Extract hour time
```
We'll also generate the day of the week that each observation falls on, giving us a better insight into consumer behavior.
```
data$dow<-weekdays(as.POSIXct(data$Date), abbreviate = F)
data$dow<-as.factor(data$dow)
data$dow <- ordered(data$dow, levels=c("Monday", "Tuesday", "Wednesday", "Thursday", 
                                         "Friday", "Saturday", "Sunday"))
```

## Date/Time exploration
**Lets start by looking a time series of total revenue:**

![](images/timeseries.jpeg)

We can see a noticeable pattern of consistent linear growth, with some very large spikes later in the year. October 2011 has an extremely large spike, which will be interesting to explore later on. Unfortunately we only have one years worth of data, and it would be interesting to see if sales dipped again in January of 2012, and then rose similarly to the way they did in 2011.
### Seasonality
![](images/seasonality.jpeg)  ![](images/seasonality_revenue.jpeg)

When looking into the seasonality of these e-commerce sales, we interestingly can see a significant spike in average unit price from April-July, and then a quick downard trend right after. It's unclear to me why unit prices are so high in these months, but its clear that there is an obvious seasonality trend.

There is a smaller spike in October as well.

Similarly, we see a clear increase in e-commerce revenue from October-December. One explanation for this would be the increased gift buying around the major holidays of the winter months.

### Day/Time
![](/images/DowRevenue.jpeg)

We see the most highest revenue of sales coming on Wednesday of all days. In fact the beginning of the week (Mon-Wed) has the highest revenue of sales, and the weekend has the lowest revenue. This trend is the opposite of what I would have expected. Based on my own consumer habits, I would think people would be much more likely to online shop on the weekend.

![](/images/transactions%20per%20hour.jpeg) ![](/images/transactions_boxplot.jpeg)

Looking closer, we see the most transactions occuring in the middle of the day, and slowly decreasing as the day goes on. I believe this is due to midday having the most shoppers being awake and alert.

## Regional Exploration

Looking at the top countries by revenue, we can see that the UK dominates spending and  # of transactions for this dataset. UK Revenue and # of transactions take a dip in Q2, but increase heavily in Q3 and Q4. 

![](images/transactions_per_day.jpeg)
![](images/revenue_by_country.jpeg)


Looking a bit closer, we can begin to understand how region affects seasonality. For example, USA shows the most intense relative spike in revenue during the winter months due to the increase in spending for the winter holidays. This revenue spike is related to American culture, and the data backs it up. Similarly we see intense spikes in the UK and Australia, who both widely celebrate the winter holidays. 

![](images/topcountries_revenue.jpeg)
> This graph shows smoothed regression lines for revenue. 
## RFM (Recency, Frequency, Monetary) Analysis
In order to better understand the customers for this dataset, we can use RFM analysis as a classificiation techinique. We can classify all unique customers into segments based on the recency of their last purchase, frequency of purchases, and average purchase value. Once we see who our customers are, we can then focus on customer retention and create personalized marketing campaigns to different segments of customers. 

### Setup
First we'll create our metrics for analysis:
```
RFM1 = data %>% 
  group_by(CustomerID) %>% 
  summarise(Recency =as.numeric(as.Date("2012-01-01")-max(Date)),
            Frequency =n_distinct(InvoiceNo), Monetary = sum(TotalSale)/n_distinct(InvoiceNo)) 

RFM1= RFM1 %>% filter (Monetary>0) #Exclude customers who havent spent money
```

Then we'll examine the quantiles to observe how our segments will be defined:
```
quantile(RFM1$Recency) #Check quantiles for subsetting
quantile(RFM1$Frequency)#Check quantiles for subsetting
quantile(RFM1$Monetary)#Check quantiles for subsetting
summary(RFM1)
```

Then categorize unique clients based on quantile scores for each metric
```
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
```
I pulled this formula from a marketing website, it gives heavier weight to R_Score, so this RFM analyis is mostly focused on developing marketing for segements based on recency of client purchases:
RFM1 = RFM1 %>% mutate(RFM_Score = 100*R_Score + 10*F_Score+M_Score)

![](images/Customer%20Segmentation.jpeg)
