#!/usr/bin/env python
from __future__ import print_function
from random import shuffle
from urllib2 import urlopen
from BeautifulSoup import BeautifulSoup
import sys

main_url = 'http://www.reuters.com'

pictures_desc = []

soup    = BeautifulSoup(urlopen(main_url + '/news/pictures'))
chowder = BeautifulSoup(urlopen(main_url + soup.find('div',{'class':'topStory'})\
                                               .findAll('a')[0]['href']))

for slide in chowder.find('div',{"class":"slide-list-container"})\
                    .findAll('div',{"class":["slide","slick-slide"]}):

  pictures_desc.append({"url": slide.find('img')['data-lazy'],
                        "description": slide.find('div', {"class":"slide-desc-txt"}).text})

shuffle(pictures_desc)

print(pictures_desc[0]['url'])
print(pictures_desc[0]['description'], file=sys.stderr)
