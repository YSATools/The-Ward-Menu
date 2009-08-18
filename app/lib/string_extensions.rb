#international character support
class String  
	require 'iconv'  
	def to_iso  
		c = Iconv.new('ISO-8859-15','UTF-8')  
		c.iconv(self)  
	end  
end  

