import sys
from BeautifulSoup import BeautifulSoup
import urllib2
import re
import os
import datetime
import random

reload(sys)
sys.setdefaultencoding('utf-8')
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

def scrape_airbnb(filename, soup, append=False):

	# open file to write to
	if append:
		theFile = open(filename, 'a')
	else:
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
			imgsrc = "noimage.JPG"
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


def scrape_wimdu(filename, soup, append=False):
	
	if append:
		theFile = open(filename, 'a')
	else:
		theFile = open(filename, 'w')

	cards = soup.findAll('div', { "class": "box-content" })
	for card in cards:
		theFile.write('##### LISTING #####\n')

		### 1. Image source ### find images in the block
		
		if card.find('div', { "class":"hit-thumbnail" }):
			imgsrc = card.find('div', { "class":"hit-thumbnail" })['style'].strip()
			imgsrc = imgsrc[imgsrc.find("(")+1:imgsrc.find(")")]
		elif card.find('div', { "class":"hit-thumbnail js-lazyLoadImage" }) :
			imgsrc = card.find('div', { "class":"hit-thumbnail js-lazyLoadImage" })['data-bkg'].strip()
		elif card.find('div', { "class":"hit-thumbnail imgDelayLoadRef" }) :
			imgsrc = card.find('div', { "class":"hit-thumbnail imgDelayLoadRef" })['ref'].strip()
		else:
			imgsrc = "noimage.JPG"
		theFile.write(imgsrc + '\n')

		### 2. Title ### get title by attribute data-name in the card itself
		if card.find("a", { "class": "hit-url js-hitLink" }):
			title = card.find("a", { "class": "hit-url js-hitLink" }).getText()
		else:
			title = "\n"

		theFile.write(title + '\n')

		### 3. Link Href ### get link path in the card attribute data-url
		if card.find("a", { "class": "hit-url listing-url js-hitLink" }):
			href = 'https://www.homeaway.com' + card.find("a", { "class":"hit-url listing-url js-hitLink" })['href']
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
		price = None
		if card.find("span", { "class": "price" }):
			price = (card.find("span", { "class": "price" }).getText())[1:]
			price = re.search("[0-9]+",price)

		if price == None:
			price = "-"
		theFile.write("$ " + price.group(0) + '\n')

		### 6. Details ###
		#details = card.find('div', { "class":"offer__description"}).getText().strip()
		#theFile.write(details + "\n")

		theFile.write('##### END LISTING #####\n')
	
	
def scrape_weather(filename, soup):
	theFile = open(filename, 'w')

	loc, time, week = "", "", ""

	if soup.find('div', {"id": "wob_loc" }):
		loc = soup.find('div', {"id": "wob_loc" }).getText()
	if soup.find('div', {"id": "wob_dts" }):
		time = soup.find('div', {"id": "wob_dts" }).getText()
	if soup.find('div', {"id": "wob_dp" }):
		week = str(soup.find('div', {"id": "wob_dp" }))
	
	theFile.write("<h3>" + loc + " | " + time + "</h3>" + '\n' + week)

def render():	
	# scrapedContent.txt contains the data we need to display in the html
	data1 = open('airbnb.txt', 'r')
	data2 = open('uk.txt', 'r')
	weather = open('weather.txt', 'r')

	#Recommend Result
	data3 = open('airbnb_R.txt', 'r')
	data4 = open('uk_R.txt', 'r')
	
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
	
	#Recommend Result
	contents2 = ""
	
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
	
	#Recommend Result
	j = 0
	for line in data3:
		if line.strip() == "##### END LISTING #####":
			card = card.replace("{{ details }}", details)
			card = card.replace('class="card"', 'class="card rec"')
			if j < 8:
				contents2 = contents2 + card
				j = j + 1
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
	
	j = 0
	for line in data4:
		if line.strip() == "##### END LISTING #####":
			card = card.replace("{{ details }}", details)
			card = card.replace('class="card"', 'class="card rec"')

			if j < 8:
				contents2 = contents2 + card
				j = j + 1
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
	html = re.sub('\{\{ weather \}\}', weather.read(), html)

	#Recommend Result
	html = re.sub('\{\{ recommend_result \}\}', contents2, html)
	
	oSoup = BeautifulSoup(html)
	if location:
		oSoup.find('input', { "name": 'location'})['value'] = location
	if guests:
		oSoup.find('input', { "name": 'guests'})['value'] = guests
	if checkin:
		oSoup.find('input', { "name": 'checkin'})['value'] = checkin
	if checkout:
		oSoup.find('input', { "name": 'checkout'})['value'] = checkout
	if checkin:
		oSoup.find('input', { "name": 'priceMin'})['value'] = priceMin
	if checkin:
		oSoup.find('input', { "name": 'priceMax'})['value'] = priceMax
	
	#Recommend Result
	if state:
		oSoup.find('input', { "name": 'state'})['value'] = state
		
	oSoup.prettify()

	print(str(oSoup))


def start(location,guests,checkin,checkout,priceMin,priceMax, append=False):

	#print(url_airbnb)
	#print(url_uk)
	# this is the URL we're scraping data from
	air_params = urllib2.quote(location) + "?guests=" + urllib2.quote(guests)
	if checkin:
		air_params = air_params + "&checkin=" + urllib2.quote(datetime.datetime.strptime(checkin, '%Y-%m-%d').strftime('%m/%d/%y'))
	if checkout:
		air_params = air_params + "&checkout=" + urllib2.quote(datetime.datetime.strptime(checkout, '%Y-%m-%d').strftime('%m/%d/%y'))
	if priceMin:
		air_params = air_params + "&price_min=" + urllib2.quote(priceMin)
	if priceMax:
		air_params = air_params + "&price_max=" + urllib2.quote(priceMax)

	url_airbnb = "https://www.airbnb.com/s/" +  air_params

	uk_params = "keywords:" + urllib2.quote(location)
	if checkin:
		uk_params = uk_params + "/arrival:" + checkin
	if checkout:
		uk_params = uk_params + "/departure:" + checkout
	if guests:
		uk_params = uk_params + "/minSleeps/" + urllib2.quote(guests)
	if priceMin:
		uk_params = uk_params + "/minNightlyPrice/" + urllib2.quote(priceMin)
	if priceMax:
		uk_params = uk_params + "/maxNightlyPrice/" + urllib2.quote(priceMax)

	url_uk = "https://www.homeaway.com/search/" + uk_params

	url_weather = "https://www.google.com/search?q=weather+" + urllib2.quote(location)
	
	# scraped data files
	data_airbnb = "airbnb.txt"
	data_wimdu = "uk.txt"
	data_weather = "weather.txt"

	scrape_airbnb(data_airbnb, getSoup(url_airbnb), append)
	scrape_wimdu(data_wimdu, getSoup(url_uk), append)
	scrape_weather(data_weather, getSoup(url_weather))

def reset():
	d1 = open('airbnb.txt', 'w')
	d2 = open('uk.txt', 'w')
	w = open('weather.txt', 'w')

	#Recommend Result
	d3 = open('airbnb_R.txt', 'w')
	d4 = open('uk_R.txt', 'w')
	
	d1.write('')
	d2.write('')
	w.write('')

	#Recommend Result
	d3.write('')
	d4.write('')

#Recommend Result
def	scrape_recommendresult(state,guests,checkin,checkout,priceMin,priceMax, append=False):
	

	air_params = urllib2.quote(state) + "?guests=" + urllib2.quote(guests)
	if checkin:
		air_params = air_params + "&checkin=" + urllib2.quote(datetime.datetime.strptime(checkin, '%Y-%m-%d').strftime('%m/%d/%y'))
	if checkout:
		air_params = air_params + "&checkout=" + urllib2.quote(datetime.datetime.strptime(checkout, '%Y-%m-%d').strftime('%m/%d/%y'))
	if priceMin:
		air_params = air_params + "&price_min=" + urllib2.quote(priceMin)
	if priceMax:
		air_params = air_params + "&price_max=" + urllib2.quote(priceMax)

	url_airbnb = "https://www.airbnb.com/s/" +  air_params

	uk_params = "keywords:" + urllib2.quote(state)
	if checkin:
		uk_params = uk_params + "/arrival:" + checkin
	if checkout:
		uk_params = uk_params + "/departure:" + checkout
	if guests:
		uk_params = uk_params + "/minSleeps/" + urllib2.quote(guests)
	if priceMin:
		uk_params = uk_params + "/minNightlyPrice/" + urllib2.quote(priceMin)
	if priceMax:
		uk_params = uk_params + "/maxNightlyPrice/" + urllib2.quote(priceMax)

	url_uk = "https://www.homeaway.com/search/" + uk_params
	
	# scraped data files
	data_airbnb = "airbnb_R.txt"
	data_wimdu = "uk_R.txt"

	scrape_airbnb(data_airbnb, getSoup(url_airbnb), append)
	scrape_wimdu(data_wimdu, getSoup(url_uk), append)
	
location = ""
guests = ""
checkin = ""
checkout = ""
priceMin = ""
priceMax = ""

#Recommend Result
state = ""
randomCities = ["San Francisco", "Sydney", "Tokyo", "Seoul", "New York", "Las Vegas", 
				"Florida", "Germany", "Madrid", "Honolulu", "Kawaii", "London", 
				"Amsterdam", "Dubai", "Istanbul", "Lima", "Los Angeles"]

if REQUEST:
	location = REQUEST['location'].strip()
	
	#Recommend Result
	state = REQUEST['state'].strip()
	
	if unicode(REQUEST['guests'].strip(), 'utf-8').isnumeric():
		guests = REQUEST['guests'].strip()

	checkin = REQUEST['checkin'].strip()
	checkout = REQUEST['checkout'].strip()
	
	if unicode(REQUEST['priceMin'].strip(), 'utf-8').isnumeric():
		priceMin = REQUEST['priceMin'].strip()
	
	if unicode(REQUEST['priceMax'].strip(), 'utf-8').isnumeric():
		priceMax = REQUEST['priceMax'].strip()

	#Recommend Result
	if state:
		scrape_recommendresult(state, guests, checkin, checkout, priceMin, priceMax)
	else:
		scrape_recommendresult(random.choice(randomCities), guests, checkin, checkout, priceMin, priceMax, False)
		
	if location:
		start(location, guests, checkin, checkout, priceMin, priceMax)
	elif priceMin or priceMax or guests or checkin or checkout:
		start(random.choice(randomCities), guests, checkin, checkout, priceMin, priceMax, False)
		
else:
	reset()

render()
