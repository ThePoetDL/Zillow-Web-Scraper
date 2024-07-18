# Set up
library(dplyr)
library(rvest)
library(openxlsx)
library(tidyverse)
library(stringr)
library(jsonlite)
rm(list = ls())

#Notes:
#help doc: https://zillowscraper.com/r-scrape-zillow/
#Use selector gadget chrome extension to identify elements to pull

# Set working directory
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#Property Groups
#source: https://www.pha.phila.gov/wp-content/uploads/2023/09/HCV-SAFMR-Payment-Standard-Schedule-effective-October-1-2023.pdf
Const_PHA_Group1 = list(19120,
                        19124,
                        19126,
                        19132,
                        19133,
                        19134,
                        19136,
                        19139,
                        19140,
                        19141,
                        19142,
                        19143,
                        19151)
Const_PHA_Group2 = list(
  19101,
  19104,
  19105,
  19109,
  19110,
  19111,
  19112,
  19114,
  19115,
  19116,
  19119,
  19121,
  19122,
  19131,
  19135,
  19137,
  19138,
  19144,
  19145,
  19148,
  19149,
  19150,
  19152
)
Const_PHA_Group3 = list(19125, 19128, 19129, 19153, 19154)
Const_PHA_Group4 = list(19118, 19127, 19146, 19147)
Const_PHA_Group5 = list(19102, 19103, 19106, 19107, 19123, 19130)
list_groups = list(
  Const_PHA_Group1,
  Const_PHA_Group2,
  Const_PHA_Group3,
  Const_PHA_Group4,
  Const_PHA_Group5
)
Const_PHA_GroupTest <- list(19134, 19137, 19125)

#Fixed Search variables
Max_Price <- '200000'
Min_Bedrooms <- '2'
Max_DaysonZillow <- '30'

#construct URL
#URL_Example <- 'https://www.zillow.com/philadelphia-pa-19121/?searchQueryState=%7B%22pagination%22%3A%7B%7D%2C%22usersSearchTerm%22%3A%2219121%22%2C%22mapBounds%22%3A%7B%22west%22%3A-75.21682404260254%2C%22east%22%3A-75.14386795739746%2C%22south%22%3A39.9648237462464%2C%22north%22%3A40.00125835756117%7D%2C%22regionSelection%22%3A%5B%7B%22regionId%22%3A65788%2C%22regionType%22%3A7%7D%5D%2C%22isMapVisible%22%3Atrue%2C%22filterState%22%3A%7B%22sort%22%3A%7B%22value%22%3A%22globalrelevanceex%22%7D%2C%22price%22%3A%7B%22max%22%3A200000%7D%2C%22mp%22%3A%7B%22max%22%3A1031%7D%2C%22beds%22%3A%7B%22min%22%3A2%7D%2C%22land%22%3A%7B%22value%22%3Afalse%7D%2C%22doz%22%3A%7B%22value%22%3A%2230%22%7D%7D%2C%22isListVisible%22%3Atrue%2C%22mapZoom%22%3A14%7D'
#URL_Example <- 'https://www.zillow.com/philadelphia-pa-19121/?searchQueryState=%7B%22pagination%22%3A%7B%7D%2C%22usersSearchTerm%22%3A%2219121%22%2C%22mapBounds%22%3A%7B%22west%22%3A-75.21682404260254%2C%22east%22%3A-75.14386795739746%2C%22south%22%3A39.9648237462464%2C%22north%22%3A40.00125835756117%7D%2C%22regionSelection%22%3A%5B%7B%22regionId%22%3A65788%2C%22regionType%22%3A7%7D%5D%2C%22isMapVisible%22%3Atrue%2C%22filterState%22%3A%7B%22sort%22%3A%7B%22value%22%3A%22globalrelevanceex%22%7D%2C%22price%22%3A%7B%22max%22%3A200000%7D%2C%22mp%22%3A%7B%22max%22%3A1031%7D%2C%22beds%22%3A%7B%22min%22%3A2%7D%2C%22land%22%3A%7B%22value%22%3Afalse%7D%2C%22doz%22%3A%7B%22value%22%3A%2214%22%7D%7D%2C%22isListVisible%22%3Atrue%2C%22mapZoom%22%3A14%7D
#Example filters: $200,000 max price, min 2 BR, Home type != empty lot, <30 days on zillow

df_PropertyData <- data.frame(
  "Address" = character(0),
  'Price' = numeric(0),
  'Bedrooms' = numeric(0),
  'SquareFootage' = numeric(0),
  'PropertyURL' = character(0)
)

listDFs <- list()
listDFs.counter <- 1
for (group in list_groups[]) {
  for (zipcode in group) {
    URL_to_Scrape <- paste0(
      'https://www.zillow.com/philadelphia-pa-',
      zipcode,
      '/?searchQueryState=%7B%22filterState%22%3A%7B%22price%22%3A%7B%22max%22%3A',
      Max_Price,
      '%7D%2C%22mp%22%3A%7B%22max%22%3A773%7D%2C%22sort%22%3A%7B%22value%22%3A%22globalrelevanceex%22%7D%2C%22beds%22%3A%7B%22min%22%3A',
      Min_Bedrooms,
      '%7D%2C%22doz%22%3A%7B%22value%22%3A%22',
      Max_DaysonZillow
      ,
      '%22%7D%7D%2C%22isListVisible%22%3Atrue%7D'
    )
    # print(URL_to_Scrape)
    
    #Download page HTML data
    page <- read_html(URL_to_Scrape)
    
    #####Extract key data from HTML
    
    #Determine number of results
    elements_NumSearchResults <- html_element(page, '.result-count')
    NumSearchResults <- html_text(elements_NumSearchResults)
    if (is.na(NumSearchResults)) {
      print(paste0("Due to lack of results, skipping zip = ", zipcode))
      next
    }
    NumSearchResults <- str_replace(NumSearchResults, ' results','')
    NumSearchResults <- str_replace(NumSearchResults, ' result','')
    NumSearchResults <- as.numeric(NumSearchResults)
    
    # Select elements with class 'vjmXt', which contain the price
    elements_Price <- html_elements(page, ".vjmXt")
    list_Prices <- html_text(elements_Price)
    list_Prices <- gsub(',', '', list_Prices)
    list_Prices <- gsub('\\$', '', list_Prices) %>% as.numeric()
    # list_Prices
    
    # Select elements with class '.exCsDV li:nth-child(1) b' which contains the number of bedrooms
    elements_BR  <- html_elements(page, ".exCsDV li:nth-child(1) b")
    list_BR <- html_text(elements_BR) %>% as.numeric()
    # list_BR
    
    # Select elements with class '.exCsDV li~ li+ li b' which contains the number of square footage
    elements_sqft <- html_elements(page, ".exCsDV li~ li+ li b")
    list_sqft  <- html_text(elements_sqft)
    list_sqft <- gsub(",", '', list_sqft) %>% as.numeric()
    # list_sqft
    
    # Select elements with class 'address' which contains the address
    elements_address <- html_elements(page, "address")
    list_address  <- html_text(elements_address)
    # list_address
    
    #select URL of the property with class '.Image-c11n-8-102-0__sc-1rtmhsc-0'
    elements_json <- html_elements(page, '[type="application/ld+json"]')
    json_text <- elements_json %>% html_text()
    json_data <- lapply(json_text, fromJSON)
    list_PropertyURL <- sapply(json_data, function(x) x$url)
    list_PropertyURL <- head(list_PropertyURL,-1) %>% unlist()
    # list_PropertyURL
  
    #Create tempDF containing property data
    df_temp <- cbind(list_address, list_Prices, list_BR, list_sqft, list_PropertyURL) %>% as.data.frame()
    df_temp <- df_temp %>% slice(1:NumSearchResults) #Drop Zillow recommended similar search results, only keep results for 
    #Merge tempDF into main DF
    if (ncol(df_PropertyData) == ncol(df_temp)) {
      df_PropertyData <- rbind(df_PropertyData, df_temp)
    }
    
    listDFs[[listDFs.counter]] <- df_temp #add tempDF to running dataframe containing all scraped data
    listDFs.counter <- listDFs.counter + 1
    timedelay <- round(runif(1, min = 0, max = 1))
    print(paste0("Zip = ", zipcode, "; timedelay (s) = ", timedelay))
    Sys.sleep(timedelay)
  }
}
colnames(df_PropertyData) <- c('Address', 'Price', 'Bedrooms', "SquareFeet", "PropertyURL")
df_PropertyData$ScrapeDate <- today()
df_PropertyData$Price <- as.numeric(df_PropertyData$Price)
df_PropertyData$Bedrooms <- as.numeric(df_PropertyData$Bedrooms)
df_PropertyData$SquareFeet <- as.numeric(df_PropertyData$SquareFeet)

#Separate address column into component fields
df_separated <- df_PropertyData %>%
  separate(
    Address,
    into = c("Street_Address", "City", "StateZip"),
    sep = ",",
    extra = "merge",
    remove = FALSE
  )
df_separated$StateZip <- str_trim(df_separated$StateZip, side = 'left')
df_separated <- df_separated %>%
  separate(
    StateZip,
    into = c("State", "Zip"),
    sep = " ",
    extra = "merge"
  )


df_separatedtemp <- df_separated %>% distinct(Address, Price, Bedrooms)
# separate(StateZip, into = c("State", "Zip"), sep = ' ', extra ='merge')


#Output data
filename_output <- paste0('./Scrape Results/Zillow Philadelphia Scrape ', format(today(), '%Y%m%d'), '.xlsx')

if (!file.exists(filename_output)) {
  write.xlsx(df_separated, filename_output)
}
