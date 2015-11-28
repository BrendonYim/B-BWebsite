from BeautifulSoup import BeautifulSoup
import urllib2
import re
import os

################# HELPER FUNCTIONS ################################
def getSoup(url):

	# use usllib to open the website at the specified url
	req = urllib2.Request(url, headers=hdr)
	response = urllib2.urlopen(req)
	page = response.read()

	# use beautifulsoup to get the html returned from urllib
	soup = BeautifulSoup(page)
	return soup

def scrape_airbnb(filename, soup):

	# open file to write to
	theFile = open(filename, 'w')

	# find all blocks that contains our title and image that we want
	# bs4 should give us back an array
	cards = soup.findAll('div', { "class": "col-sm-12 row-space-2 col-md-6" })
	
	# loop through each block to find what we want
	for card in cards:
		theFile.write('##### LISTING #####\n')
		
		### 1. Image source ### find images in the block
		imgsrc = card.find('img')['data-urls']
		if imgsrc == None:
			imgsrc = "noimage.jpg"
		else:
			imgsrc = imgsrc.split('", "')[0].replace("[", "").replace('"', '')
		theFile.write(imgsrc + '\n')

		### 2. Title ### get title by attribute data-name in the card itself
		title = card.find('div')['data-name'].strip()
		theFile.write(title + '\n')

		### 3. Link Href ### get link path in the card attribute data-url
		href = 'https://www.airbnb.com' + card.find('div')['data-url'].strip()
		theFile.write(href + '\n')

		### 4. Rating ### get rating
		rating = card.find('div').getText()
		rating = re.search('[0-9]\.[0-9]',rating)
		if rating!=None:
			rating = rating.group(0)
		else:
			rating = "-"
		theFile.write(rating + '\n')

		### 5. Price ###
		price = card.find('div').getText()
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
	print("Scraping other site.")
	theFile = open(filename, 'w')

	cards = soup.findAll('div', { "class": "box-content" })
	for card in cards:
		theFile.write('##### LISTING #####\n')

		### 1. Image source ### find images in the block
		if card.find('img', { "class":'offer__image' }):
			imgsrc = card.find('img', { "class":'offer__image' })['data-src'].strip()
		else:
			imgsrc = "noimage.svg"
		theFile.write(imgsrc + '\n')

		### 2. Title ### get title by attribute data-name in the card itself
		#title = card.find("a", { "class": "hit-url  js-hitLink" }).strip()
		#theFile.write(title + '\n')

		### 3. Link Href ### get link path in the card attribute data-url
		href = 'https://www.homeaway.co.uk' + card.find("a", { "class": "hit-url" }).strip()
		theFile.write(href + '\n')

		### 4. Rating ### get rating
		if card.find("div", { "class": "hit-rating" }):
			rating = card.find("div", { "class": "rating" })["class"].strip()
			rating = re.search('([0-9.]+)', rating).group(1)
			rating = str(float(rating) / 2)
		else:
			rating = "\n"
		theFile.write(rating + '\n')

		### 5. Price ###
		price = card.find("span", { "class": "price" }).getText().strip()
		price = card.find("span", { "class": "currency" }).getText().strip() + re.search('([0-9]+)', price).group(1)
		theFile.write(price + '\n')

		### 6. Details ###
		#details = card.find('div', { "class":"offer__description"}).getText().strip()
		#theFile.write(details + "\n")

		theFile.write('##### END LISTING #####\n')
	
	print("Scraped wimdu.com successfully!")
	


def render():	
	# scrapedContent.txt contains the data we need to display in the html
	data1 = open('airbnb.txt', 'r')
	data2 = open('wimdu.txt', 'r')

	html = open('template.html', 'r').read()
	listing ='listingTemplate.html'

	# each listing starts with: ##### LISTING #####
	# after that the content is formatted as in this order:
	# 1. image source
	# 2. listing title
	# 3. listing url
	# 4. rating
	# 5. price
	# 6. the rest are details information until hitting the next ##### LISTING ##### or EOF
	
	contents = ""
	card = ""
	details = ""
	i = 1
	for line in data1:
			if line.strip() == "##### END LISTING #####":
				card = card.replace("{{ details }}", details)
				contents = contents + card
			elif line.strip() == "##### LISTING #####":
				card = open(listing).read()

				details = ""
				i = 0
			else:
				if i == 1:
					card = card.replace('{{ image }}', line)
				elif i == 2:
					card = card.replace('{{ title }}', line)
				elif i == 3:
					card = card.replace('{{ url }}', line)
				elif i == 4:
					card = card.replace('{{ rating }}', line)
				elif i == 5:
					card = card.replace('{{ price }}', line)
				else:
					details = details + line
			i = i + 1
	
	for line in data2:
		if line.strip() == "##### END LISTING #####":
			card = card.replace("{{ details }}", details)
			contents = contents + card
		elif line.strip() == "##### LISTING #####":
			card = open(listing).read()
	
			details = ""
			i = 0
		else:
			if i == 1:
				card = card.replace('{{ image }}', line)
			elif i == 2:
				card = card.replace('{{ title }}', line)
			elif i == 3:
				card = card.replace('{{ url }}', line)
			elif i == 4:
				card = card.replace('{{ rating }}', line)
			elif i == 5:
				card = card.replace('{{ price }}', line)
			else:
				details = details + line
		i = i + 1
	
	html = re.sub('\{\{ listings \}\}', contents, html)
	print(html)


# this is the URL we're scraping data from
url_airbnb = "https://www.airbnb.com/s/London"
url_wimdu = "https://www.homeaway.co.uk/search/keywords:London"

hdr = {'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.64 Safari/537.11',
       'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
       'Accept-Charset': 'ISO-8859-1,utf-8;q=0.7,*;q=0.3',
       'Accept-Encoding': 'none',
       'Accept-Language': 'en-US,en;q=0.8',
       'Connection': 'keep-alive'}

# scraped data files
data_airbnb = "airbnb.txt"
#data_wimdu = "wimdu.txt"

scrape_airbnb(data_airbnb, getSoup(url_airbnb))
#scrape_wimdu(data_wimdu, getSoup(url_wimdu))


render()
