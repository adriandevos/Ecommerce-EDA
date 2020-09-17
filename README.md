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

Check and remove observations with NA values as they are not useful for our analysis
```
data <- na.omit(data)
```
