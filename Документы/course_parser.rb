require 'nokogiri'
require 'open-uri'
require 'sqlite3'
require 'mechanize'

main_url = 'https://oz.by/books/'

def get_page(url)
	page = open(url).read
	page_content = Nokogiri::HTML(page)
end

def get_categories_links(url)
	page = get_page(url)
	links = []
	page.xpath('//*[@id="top-page"]/div/main/div/div/div/div/div/div/a').each do |category_link|
		
		if category_link["href"].match('http').nil? 
			links << "https://oz.by" + category_link["href"]
		else 
			links << category_link["href"] 
		end
	end
	links.uniq
end

def next_category_page(page)
	if page.at_xpath('//*[@id="paginator1"]/div/a')["class"] == "g-pagination__next pg-next disabled"
		false
	else
		"https://oz.by" + page.at_xpath('//*[@id="paginator1"]/div/a')["href"]
	end 
end

def get_book_information(book_url) 
	book_page = get_page(book_url)
	information = Hash.new
	information[:title] = book_page.xpath('//*[@id="top-page"]/div/div/div/div/div/div/div/h1').text
	information[:authors] = ""
	book_page.xpath('//*[@id="top-page"]/div[3]/div/div/div/div/div[2]/div/figure/a/span/span[1]').each do |author|
		information[:authors]  += author.text.to_s + ","
	end
	information[:authors].chop!
	information[:description] = book_page.xpath('//*[@id="truncatedBlock"]').text
	book_page.xpath('///*[@id="top-page"]/div[3]/div/div/div/div/div[1]/div[1]/table/tbody/tr').each do |line| 
		information[:publishing_house] = line.xpath('td[2]').text if line.xpath('td[1]').text == "Издательство"		
		information[:pages] = line.xpath('td[2]').text	if line.xpath('td[1]').text == "Страниц"		
	end
	information[:small_image] =   book_page.xpath('//*[@id="top-page"]/div[3]/div/div[1]/div/div[1]/div[2]/div[1]/div[3]/figure/a/img').first['src']
	information[:big_image] = book_page.xpath('//*[@id="top-page"]/div[3]/div/div[1]/div/div[1]/div[2]/div[1]/div[3]/figure/a').first['href']
	information
end

def get_books_on_page(url)
	books = []
	get_page(url).xpath('//*[@id="goods-table"]/li/div/div/div/a').each do |book|
		books << "https://oz.by" + book["href"]
	end
	books
end

def save_to_db(hash)
	db = SQLite3::Database.open('libruary')
	db.execute(
		"INSERT INTO books(" + hash.keys.join(",") +
		")" + "VALUES (" + (('?,')*hash.keys.size).chomp(',') +
		")",
		hash.values)
	db.close
end

get_categories_links(main_url).each do |category_link|							
	get_books_on_page(category_link).each do |book_link|
	info = get_book_information(book_link)
	puts "Downloaded"
	agent = Mechanize.new
	agent.get(info[:small_image]).save "img/#{info[:title]}/small.jpg" unless File::exists?("img/#{info[:title]}/small.jpg")
	agent.get(info[:big_image]).save "img/#{info[:title]}/big.jpg"     unless File::exists?("img/#{info[:title]}/big.jpg")
	info[:small_image] = "img/#{info[:title]}/small.jpg" 
	info[:big_image]   = "img/#{info[:title]}/big.jpg"
	save_to_db(info)
	end
end


