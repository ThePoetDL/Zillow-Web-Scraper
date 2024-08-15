# write a simple scraping script for zillow that doesn't get blocked by its scrape protectors

import time
import random
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from bs4 import BeautifulSoup

# Set up Selenium with Chrome driver
service = Service(ChromeDriverManager().install())
options = webdriver.ChromeOptions()
options.add_argument('--headless')  # Run Chrome in headless mode (without GUI)
driver = webdriver.Chrome(service=service, options=options)

# Set the URL with the desired filters
url = "https://www.zillow.com/philadelphia-pa-19121/?searchQueryState=%7B%22pagination%22%3A%7B%7D%2C%22isMapVisible%22%3Atrue%2C%22mapBounds%22%3A%7B%22north%22%3A40.01252172069298%2C%22south%22%3A39.958397854107815%2C%22east%22%3A-75.12297428530388%2C%22west%22%3A-75.22331036013298%7D%2C%22usersSearchTerm%22%3A%2219121%22%2C%22regionSelection%22%3A%5B%7B%22regionId%22%3A65788%2C%22regionType%22%3A7%7D%5D%2C%22filterState%22%3A%7B%22sort%22%3A%7B%22value%22%3A%22globalrelevanceex%22%7D%2C%22price%22%3A%7B%22min%22%3Anull%2C%22max%22%3A125000%7D%2C%22mp%22%3A%7B%22min%22%3A0%2C%22max%22%3A355%7D%2C%22ah%22%3A%7B%22value%22%3Atrue%7D%7D%2C%22isListVisible%22%3Atrue%2C%22mapZoom%22%3A14%7D"

# Navigate to the URL
driver.get(url)

# Wait for the page to load
time.sleep(random.uniform(5, 10))  # Wait for a random time between 5 and 10 seconds

# Get the page source HTML
html_content = driver.page_source

# Parse the HTML content using BeautifulSoup
soup = BeautifulSoup(html_content, "html.parser")

print(soup.prettify())

# Find all the property listings
property_listings = soup.find_all("div", class_="list-card-info")

# Loop through each listing and extract the relevant information
for listing in property_listings:
    address = listing.find("a", class_="list-card-addr").text.strip()
    price = listing.find("div", class_="list-card-price").text.strip()
    details = listing.find("div", class_="list-card-details").text.strip()

    # Print the extracted information
    print(f"Address: {address}")
    print(f"Price: {price}")
    print(f"Details: {details}")
    print()

# Close the browser
driver.quit()
