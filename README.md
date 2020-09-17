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

## Regional Exploration
## RFM (Recency, Frequency, Monetary) Analysis
## Sales Forecast
