require 'csv'
require 'pry'
require 'mechanize'
require 'nokogiri'

class Url
	attr_accessor :rows
	def initialize
		@rows = []
	end
	def one_at_a_time
		CSV.foreach("original.csv") do |row|
			if row.first.split('/').count > 2
				row = row.first.gsub("usat :", "http://www.usatoday.com")
				validate_and_correct_url(row)
				@rows << [row]
			end
		end
	end

	def validate_and_correct_url(row)
		agent = Mechanize.new 

		begin 
			page = agent.get(row) 
#read the URL where it lands... if it's http://www.usatoday.com/errors/404/ then search google
			if page
				row
			end
		rescue Mechanize::ResponseCodeError => e
#could try this: http://dazdaztech.wordpress.com/2013/08/03/using-google-custom-search-api-from-the-command-line/
			google_page = agent.get("http://www.google.com")
			broken_url = row.split('/')
			if !broken_url.last.match(/[a-z]/i)
				broken_url.shift
			end
			search_terms = broken_url.last + " site:usatoday.com"
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
				sleep(3)
				good_url
				end
			end
		end
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