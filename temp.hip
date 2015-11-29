import sys
from BeautifulSoup import BeautifulSoup
import urllib2
import re
import os

#reload(sys)
#sys.setdefaultencoding('utf-8')
################# HELPER FUNCTIONS ################################
def getSoup(url):
	hdr = {'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.86 Safari/537.36'}
	
	# use usllib to open the website at the specified url
	req = urllib2.Request(url, headers=hdr)
	
	page = '<html></html>'
	try:
		response = urllib2.urlopen(req)
		page = response.read()
	except urllib2.URLError, e:
		print url
		print(e)

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
	
	


#checks if the specified a tag contains the required type of link.
def reqClass(tag):
    return tag and re.compile("rating rating*").search(tag)


def scrape_wimdu(filename, soup):
	
	theFile = open(filename, 'w')

	cards = soup.findAll('div', { "class": "box-content" })
	for card in cards:
		theFile.write('##### LISTING #####\n')

		### 1. Image source ### find images in the block
		
		if card.find('div', { "class":"hit-thumbnail" }):
			imgsrc = card.find('div', { "class":"hit-thumbnail" })['style'].strip()
			imgsrc = imgsrc[imgsrc.find("(")+1:imgsrc.find(")")]
		elif card.find('div', { "class":"hit-thumbnail imgDelayLoadRef" }) :
			imgsrc = card.find('div', { "class":"hit-thumbnail imgDelayLoadRef" })['ref'].strip()
		else:
			imgsrc = "noimage.jpg"
		theFile.write(imgsrc + '\n')

		### 2. Title ### get title by attribute data-name in the card itself
		if card.find("a", { "class": "hit-url js-hitLink" }):
			title = card.find("a", { "class": "hit-url js-hitLink" }).getText()
		else:
			title = "\n"

		theFile.write(title + '\n')

		### 3. Link Href ### get link path in the card attribute data-url
		if card.find("a", { "class": "hit-url listing-url js-hitLink" }):
			href = 'https://www.homeaway.co.uk' + card.find("a", { "class":"hit-url listing-url js-hitLink" })['href']
		else:
			href = "-"
		theFile.write(href + '\n')

		### 4. Rating ### get rating
		rating = card.find("div", { "class": reqClass })
		if rating != None:
			rating = rating["class"]
			rating = re.search('([0-9])', rating)
			if rating.group(1) != None:
				rating = str((float(rating.group(0)) + float(rating.group(1)))  / 2.0)
		else:
			rating = "-"
		theFile.write(rating + '\n')

		### 5. Price ###
		price = (card.find("span", { "class": "price" }).getText())[1:]
		price = re.search("[0-9]+",price)
		if price == None:
			price = "-"
		theFile.write("&pound; " + price.group(0) + '\n')

		### 6. Details ###
		#details = card.find('div', { "class":"offer__description"}).getText().strip()
		#theFile.write(details + "\n")

		theFile.write('##### END LISTING #####\n')
	
	
	


def render():	
	# scrapedContent.txt contains the data we need to display in the html
	data1 = open('airbnb.txt', 'r')
	data2 = open('uk.txt', 'r')

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


def start(location,guests,checkin,checkout,priceMin,priceMax):

	#print(url_airbnb)
	#print(url_uk)
	# this is the URL we're scraping data from
	air_params = urllib2.quote(location) + "?guests=" + urllib2.quote(guests) + "&checkin=" + urllib2.quote(checkin) + "&checkout=" + urllib2.quote(checkout)
	url_airbnb = "https://www.airbnb.com/s/" +  air_params

	uk_params = "keywords:" + urllib2.quote(location)
	if checkin:
		uk_params = uk_params + "/arrival:" + urllib2.quote(checkin)
	if checkout:
		uk_params = uk_params + "/departure:" +  urllib2.quote(checkout)
	if guests:
		uk_params = uk_params + "/minSleeps/" + urllib2.quote(guests)

	url_uk = "https://www.homeaway.co.uk/search/" + uk_params
	
	# scraped data files
	data_airbnb = "airbnb.txt"
	data_wimdu = "uk.txt"

	scrape_airbnb(data_airbnb, getSoup(url_airbnb))
	scrape_wimdu(data_wimdu, getSoup(url_uk))

if REQUEST:
	location = REQUEST['location'].strip()
	guests = REQUEST['guests'].strip()
	checkin = REQUEST['checkin'].strip()
	checkout = REQUEST['checkout'].strip()
	priceMin = REQUEST['priceMin'].strip()
	priceMax = REQUEST['priceMax'].strip()

	start(location, guests, checkin, checkout, priceMin, priceMax)

render()
