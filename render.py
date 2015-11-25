import webbrowser
import re
# **** This file will create an html file using data from scrapedContent.txt
# **** To get updated data, must run the scraper.py first, then run render.py

# scrapedContent.txt contains the data we need to display in the html
data1 = open('data/data_airbnb.txt', 'r')
data2 = open('data/data_wimdu.txt', 'r')

html = open('webUI/template.html', 'r').read()
listing ='webUI/listingTemplate.html'

# this is the file we will write html to and display
outputFile = 'webUI/bnbListing.html'
htmlFile = open(outputFile, 'w')

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
htmlFile.write(html)

print("Rendered scraped content successfully!")
print("Output file: '" + outputFile + "'. ")
print("Opening " + outputFile + "...")

webbrowser.open(outputFile)
