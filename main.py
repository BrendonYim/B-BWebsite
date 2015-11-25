from bs4 import BeautifulSoup
import urllib.request
import urllib.parse
import re

################# HELPER FUNCTIONS ################################
def getSoup(url):
	print("Visiting " + url + "...")
	# use usllib to open the website at the specified url
	request = urllib.request.Request(url, headers=hdr)
	page = urllib.request.urlopen(request)

	# use beautifulsoup to get the html returned from urllib
	print("Making soup...")
	soup = BeautifulSoup(page.read(), 'html.parser')
	return soup

def scrape_airbnb(filename, soup):
	print("Scraping airbnb.com... Please wait.")
	# open file to write to
	theFile = open(filename, 'w')

	# find all blocks that contains our title and image that we want
	# bs4 should give us back an array
	cards = soup.find_all('div', { "class": "listing" })

	# loop through each block to find what we want
	for card in cards:
		theFile.write('##### LISTING #####\n')

		### 1. Image source ### find images in the block
		if card.find('a', { "class":'media-photo' }):
			imgsrc = card.find('a', { "class":'media-photo' }).find('img')['data-urls'].strip().split('", "')[0].replace("[", "").replace('"', '')
		else:
			imgsrc = "noimage.svg"
		theFile.write(imgsrc + '\n')

		### 2. Title ### get title by attribute data-name in the card itself
		title = card['data-name'].strip()
		theFile.write(title + '\n')

		### 3. Link Href ### get link path in the card attribute data-url
		href = 'https://www.airbnb.com/' + card['data-url'].strip()
		theFile.write(href + '\n')

		### 4. Rating ### get rating
		rating = card['data-star-rating'].strip()
		theFile.write(rating + '\n')

		### 5. Price ###
		price = card['data-price'].strip()
		price = '$' + re.search('([0-9]+)', price).group(1)
		theFile.write(price + '\n')

		### 6. Details ###
		if card.find('div', { "class":"details"}):
			details = card.find('div', { "class":"details"}).getText().strip()
		else:
			details = "\n"
		theFile.write(details)

		theFile.write('##### END LISTING #####\n')
	
	print("Scraped airbnb successfully!")


def scrape_wimdu(filename, soup):
	print("Scraping wimdu.com... Please wait.")
	theFile = open(filename, 'w')

	cards = soup.find_all('li', { "class": "offer-list__item" })
	for card in cards:
		theFile.write('##### LISTING #####\n')

		### 1. Image source ### find images in the block
		if card.find('img', { "class":'offer__image' }):
			imgsrc = card.find('img', { "class":'offer__image' })['data-src'].strip()
		else:
			imgsrc = "noimage.svg"
		theFile.write(imgsrc + '\n')

		### 2. Title ### get title by attribute data-name in the card itself
		title = card.find("a", { "class": "offer__title-link" }).getText().strip()
		theFile.write(title + '\n')

		### 3. Link Href ### get link path in the card attribute data-url
		href = 'https://www.wimdu.com' + card.find("a", { "class": "offer__title-link" })["href"].strip()
		theFile.write(href + '\n')

		### 4. Rating ### get rating
		if card.find("span", { "class": "rating__value" }):
			rating = card.find("span", { "class": "rating__value" }).getText().strip()
			rating = re.search('([0-9.]+)', rating).group(1)
			rating = str(float(rating) / 2)
		else:
			rating = "\n"
		theFile.write(rating + '\n')

		### 5. Price ###
		price = card.find("div", { "class": "price__tag" }).getText().strip()
		price = '$' + re.search('([0-9]+)', price).group(1)
		theFile.write(price + '\n')

		### 6. Details ###
		details = card.find('div', { "class":"offer__description"}).getText().strip()
		theFile.write(details + "\n")

		theFile.write('##### END LISTING #####\n')
	
	print("Scraped wimdu.com successfully!")


############################ MAIN ###################################

query = input("Please enter a location: ")

# this is the URL we're scraping data from
url_airbnb = "https://www.airbnb.com/s/" + urllib.parse.quote_plus(query)
url_wimdu = "https://www.wimdu.com/search/?city=" + urllib.parse.quote_plus(query)

hdr = {'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.64 Safari/537.11',
       'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
       'Accept-Charset': 'ISO-8859-1,utf-8;q=0.7,*;q=0.3',
       'Accept-Encoding': 'none',
       'Accept-Language': 'en-US,en;q=0.8',
       'Connection': 'keep-alive'}

# scraped data files
data_airbnb = "data/data_airbnb.txt"
data_wimdu = "data/data_wimdu.txt"

scrape_airbnb(data_airbnb, getSoup(url_airbnb))
scrape_wimdu(data_wimdu, getSoup(url_wimdu))

import render
