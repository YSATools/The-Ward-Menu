#pdfwriter_add_vertical_text.rb
module PDF
	class Writer
		def add_vertical_text(x, y, text, *options)
			letters = text.split(//)
			for letter in letters
				add_text(x, y, letter, *options)
				y -= font_height - 2
			end
		end

	    def add_text(x, y, text, *options)
	      old_add_text(x, y, CONVERTER.iconv(text), *options)
	    end 
	end
end

