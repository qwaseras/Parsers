require 'nokogiri'
require 'open-uri'
require 'csv'

category_url = ARGV[0]

def get_category_page(category_url)
	page = open(category_url)
	content = page.read
	parsed_content = Nokogiri::HTML(content)
end

def get_product_links(page)
	product_links = []
	page.xpath('//*[@id="center_column"]/div/div/div/div/div/div/div/div/h5/a').each do |links|
		product_links << links["href"]	
	end
	product_links	
end

def write_product_information(product_link, file)
	product_content = open(product_link)
	parsed_product_content = Nokogiri::HTML(product_content)
	
	product_name = parsed_product_content.xpath('//*[@id="right"]/div/div/div/h1/text()').inner_text.strip

	product_pictures =  parsed_product_content.at_xpath('//*[@id="thumbs_list_frame"]/li/a') ? 
						parsed_product_content.xpath('//*[@id="thumbs_list_frame"]/li/a') :
						parsed_product_content.xpath('//*[@id="bigpic"]')
						
	weights = []
	prices = []

	if parsed_product_content.at_xpath('//*[@id="attributes"]/fieldset/div/ul/input ') 
		parsed_product_content.xpath('//*[@id="attributes"]/fieldset/div/ul/li/span[1]').each do |x|
			weights << x.inner_text.strip unless x.inner_text.strip == 'IVA incluído'
		end

		parsed_product_content.xpath('//*[@id="attributes"]/fieldset/div/ul/li/span[2]').each do |x|
			prices << x.inner_text.strip
		end
		
		for i in 0..weights.length - 1
			z = product_pictures[i] ? product_pictures[i] : product_pictures.last
			file <<  ["#{product_name} #{weights[i]}", prices[i], "#{z["href"]}"]
		end
	else
		file << [product_name, parsed_product_content.xpath('//*[@id="price_display"]').inner_text.strip, product_pictures.first["src"]]
	end
	puts "#{product_name} is downloaded"
end

def get_next_page(page)
	if page.at_xpath('//*[@id="pagination_next_bottom"]/a') 
		"https://www.petsonic.com#{page.xpath('//*[@id="pagination_next_bottom"]/a').first["href"]}" 
	else
	  nil
	end
end

CSV.open("#{ARGV[1]}.csv", 'wb') do |csv_file|
 csv_file << ['Название и вес','Цена', 'Изображение']
	page_counter = 0
	while !category_url.nil?
		puts "#{page_counter+=1} page"
		csv_file << ["#{page_counter} страница"]
		get_product_links(get_category_page(category_url)).each do |link|
			write_product_information(link, csv_file)
		end
		category_url =	get_next_page(get_category_page(category_url))
	end	
	puts 'All products from this category has been downloaded'
end