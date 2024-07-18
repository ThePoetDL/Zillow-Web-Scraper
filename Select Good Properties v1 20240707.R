# Set up
library(dplyr)
library(rvest)
library(openxlsx)
library(tidyverse)
library(stringr)
library(purrr)
rm(list = ls())

#Notes:
#help doc: https://zillowscraper.com/r-scrape-zillow/
#Use selector gadget chrome extension to identify elements to pull

# Set working directory
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#Hardcoded variables
drop.zips <- list('19023', '08102', '08103', '19018', '08030', '08110', '19079')
drop.BRs <- list(5, 6) #drop 5 and 6 bedroom apartments

#Import Files
filename_ManualEntry <- '_Manual Entry Sheet v1 20240707.xlsx' #XLSX of properties which have been ruled out
df.FairMarketRentsRAW <- read.xlsx(filename_ManualEntry, sheet = "FairMktRents")

filestoImport <- list.files(path = './Scrape Results/')
list.ImportedData <- list()
for (i in seq_along(filestoImport)) {
  list.ImportedData[[i]] <- read.xlsx(paste0('./Scrape Results/',filestoImport[i]))
}
df.ImportedDataRaw <- do.call(what = rbind, args = list.ImportedData)





#Clean up main file
df.PotentialInvestments <- df.ScrapedDataRAW  %>%
  mutate(ScrapeDate = as.Date(ScrapeDate, origin = '1899-12-30')) %>%
  filter(!(Zip %in% drop.zips)) %>%
  filter(!(Bedrooms %in% drop.BRs)) %>%
  filter(!is.na(Price)) %>%
  distinct(Street_Address, Zip, Price, .keep_all = T)
# str(df.PotentialInvestments)

#Convert df.FairMarketRentsRAW to flat file
df.FairMarketRents <- df.FairMarketRentsRAW %>%
  pivot_longer(-ZipCode)   %>% # id_variables should be replaced with the actual column(s) containing the ID information
  as.data.frame()
colnames(df.FairMarketRents) <- c('zipcodes', 'NumBR', 'Rent')
df.FairMarketRents <- df.FairMarketRents %>%
  filter(NumBR != 'Group', NumBR != 'SRO') %>%
  mutate(NumBR = str_replace_all(NumBR, '.BR', '')) %>%
  mutate(NumBR = as.numeric(NumBR))


#Function to calculate fair market rent from zip code and number of BR
Calc_FairMarketRent <- function(ZipCode, NumBedrooms) {
  #ZipCode and NumBR both integers
  ####Test variables
  # ZipCode <- 19121
  # NumBedrooms <- 2
  # ZipCode = as.character(ZipCode)
  
  tempDF.FMR <- df.FairMarketRents %>%
    filter(NumBR == NumBedrooms) %>%
    filter(str_detect(zipcodes, ZipCode))
  return (tempDF.FMR$Rent[1])
}

df.PotentialInvestments$FairMarketRent <- mapply(
  Calc_FairMarketRent,
  df.PotentialInvestments$Zip,
  df.PotentialInvestments$Bedrooms
)
df.PotentialInvestments$FairMarketRent_Annual <- df.PotentialInvestments$FairMarketRent * 12

df.PotentialInvestments <- df.PotentialInvestments %>%
  mutate(PricetoRent = Price / FairMarketRent_Annual) %>%
  arrange(PricetoRent)
