#pdfwriter_utf8.rb
CONVERTER = Iconv.new( 'ISO-8859-15//IGNORE//TRANSLIT', 'utf-8')

module PDF
	class Writer
		alias :text_old :text
		def text( texto, options = {} )
			text_old( CONVERTER.iconv(texto), options )
		end

	    alias_method :old_add_text, :add_text
	    def add_text(x, y, text, *options)
	      old_add_text(x, y, CONVERTER.iconv(text), *options)
	    end 
	end
end

