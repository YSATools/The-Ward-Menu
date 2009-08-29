require 'directorypdf'
require 'ftools'

dir = DirectoryPDF.new
dir.section({:columns => 2, :rows =>3, :left_padding => 20})
(1..6).each do |item|
  image = File.open("test_pics/test_#{item.to_s}.jpg", 'r').read
  dir.add_image_element(image, 100, 100)
  dir.add_text_element("Item: #{item}", 'Courier-Bold', 14)
  dir.add_text_element("Col: #{dir.column_number.to_s}", 'Courier-Bold', 14)
  dir.add_text_element("Row: #{dir.row_number.to_s}", 'Courier-Bold', 14)
  dir.add_text_element("Page: #{dir.page_number.to_s}", 'Courier-Bold', 14)
  dir.next_column
end
dir.save('WardDir')
