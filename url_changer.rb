require 'csv'
require 'pry'
require 'mechanize'
require 'nokogiri'

class Url
	attr_accessor :rows, :good_url
	def initialize
		@rows = []
	end
	def one_at_a_time
		CSV.foreach("original.csv") do |row|
			if row.first.split('/').count > 2
				url = row.first.gsub("usat :", "http://www.usatoday.com")
				if url.end_with? '/'
					@rows << [url]
				else
					validate_or_correct_url(url)
					@rows << [good_url]
				end
			else 
				@rows << ["N/A. This is a portal, not a news item."]
			end
		end
	end

	def validate_or_correct_url(url)
		puts url
		begin 
			agent = Mechanize.new 
			page = agent.head(url) 
			good_url = url 
		rescue Mechanize::ResponseCodeError

			agent = Mechanize.new
			google_page = agent.get("http://www.google.com")
			google_page.encoding = 'utf-8'
			broken_url = url.split('/')
			if !broken_url.last.match(/[a-z]/i)
				broken_url.pop
			end
			search_terms = broken_url.last + broken_url[3] + " site:usatoday.com"
			search_results = google_page.form do |form|
				form.field_with(:name=>"q").value = search_terms
			end.submit
			if search_results.parser
				if search_results.parser.css('h3.r')
					if search_results.parser.css('h3.r').first
						if search_results.parser.css('h3.r').first.css('a')
							if search_results.parser.css('h3.r').first.css('a').first
								if search_results.parser.css('h3.r').first.css('a').first.attributes['href']
									good_url = search_results.parser.css('h3.r').first.css('a').first.attributes['href'].value.gsub('/url?q=','')
									good_url = good_url.gsub(/(&sa=).*$/,"")
								end
							end
						end
					end
				sleep(0.1)
				end
			end
		end
		puts good_url
		@good_url = good_url
	end

	def write_into_CSV_file
		CSV.open("final.csv", "wb") do |csv|
			@rows.map do |row|
				csv<<row
			end
		end
	end
end
urls = Url.new
urls.one_at_a_time
urls.write_into_CSV_file