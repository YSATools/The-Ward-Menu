class DirectoryPDF
  # http://www.bin-co.com/blog/2007/11/creating-pdf-in-ruby-on-rails-pdfwriter/
  # http://www.cnblogs.com/hardrock/archive/2006/07/24/458184.html
  # http://wiki.rubyonrails.org/rails/pages/HowtoIntegrateJasperReports
  require 'string_extensions' #int'l #AJ-patch
  require 'pdf/writer'
  require 'pdfwriter_utf8' #int'l #AJ-patch
  require 'pdfwriter_add_vertical_text.rb' #AJ-patch
  require 'activesupport'
  require 'rubygems'
  require 'ftools'

  # Structs
  Person = Struct.new(:first, :last, :alias, :email, :address, :phone_number, :picture, :page)
  Apartment = Struct.new(:address, :people)
  Complex = Struct.new(:name, :apartments)
  Page = Struct.new(:segment) # an array of full and / or partial apartments


# Approximately the width of the widest picture divided by its height
# If all pictures are cropped to 135x135, 0.9 works great.
# If you have any pictures that are too wide, just crop them
# or if you're really that lazy use 0.7 
PICTURE_RATIO = 0.9
###############################################################
###############################################################

PAGE_CENTER = pdf.margin_width.to_f / 2
TOP = pdf.absolute_top_margin
BOTTOM = pdf.absolute_bottom_margin
BASE_FONT = 20
TITLE_FONT = BASE_FONT + 8
H_WHITESPACE = (TOP - BOTTOM - pdf.font_height(TITLE_FONT))
L_MARGIN = pdf.absolute_left_margin
R_MARGIN = pdf.absolute_right_margin
MARGIN_WIDTH = R_MARGIN - L_MARGIN

L_CENTER = PAGE_CENTER / 2
L_L_MARGIN = pdf.absolute_left_margin
L_R_MARGIN = PAGE_CENTER - (L_L_MARGIN / 2)
#MARGIN_WIDTH = L_R_MARGIN - L_L_MARGIN

R_CENTER = L_CENTER + PAGE_CENTER
R_R_MARGIN = pdf.absolute_right_margin
R_L_MARGIN = R_R_MARGIN - PAGE_CENTER + L_L_MARGIN

CELLS_PER_ROW = 2
ROWS_PER_PAGE = 3
TITLES_PER_PAGE = 2
NAME_FONT = BASE_FONT + 2
EMAIL_FONT = BASE_FONT
TITLE_CELL_HEIGHT = pdf.font_height(TITLE_FONT)
TEXT_CELL_HEIGHT = pdf.font_height(BASE_FONT)
CELL_WIDTH = (MARGIN_WIDTH / CELLS_PER_ROW)
CELL_HEIGHT = H_WHITESPACE / ROWS_PER_PAGE
CELLS_PER_PAGE = CELLS_PER_ROW * ROWS_PER_PAGE
PICTURE_CELL_HEIGHT = (CELL_HEIGHT - TEXT_CELL_HEIGHT * 3)
PICTURE_HEIGHT = PICTURE_CELL_HEIGHT * PICTURE_RATIO

FOOTER = BOTTOM - pdf.font_height(BASE_FONT)


  def initialize
    print "Generating the PDF... could take some time"
    @pdf = PDF::Writer.new()
    @pdf.select_font "Times-Roman", :encoding => nil
    @new_page = false
    @people = nil
  end

  def title
    # The title of the first page
    title = 'BYU 196th Ward    -    Spring / Summer 2009'
  end

  def index
  end

  def add_records(people)
    @people = people

    bishopric = []

    bishopric << bishop = 'Bishop & Sister Clayton'
    bishopric << first_counselor = 'Brother & Sister Billings'
    bishopric << sceond_counselor = 'Brother & Sister Holman'

    # If you would like to name street addresses
    apartment_names = []

    apartment_names << [street = '1960 North Canyon Road', complex_name = 'Stadium Terrace']
    apartment_names << [street = '240 East 2230 North', complex_name = 'Temple Lane']
    apartment_names << [street = '239 East 2230 North', complex_name = 'Temple Lane']
    apartment_names << [street = '236 East 2230 North', complex_name = 'Temple Lane']
    #apartment_names << [street = 'PROVO, UTAH', complex_name = 'Houses']
    #apartment_names << [street = 'XXX', complex_name = 'NO PRINT']
    #apartment_names << [street = true, complex_name = 'Houses']

    #
    # Put each person in a dwelling
    # Filter the bishopric and excluded
    #
    _bishopric = []
    apartments = []
    apartment = nil
    address = nil
    for person in people
      go_next = false
      for _alias in bishopric
        if _alias == "#{person[:first]} #{person.last}"
          _bishopric << person
          go_next = true
          break
        end
      end
      next if go_next

      if address != person.address
        # First is always empty
        apartments << apartment
        apartment = Apartment.new(person.address, people = [])
        address = person.address
      end
      apartment.people << person
    end
    apartments << apartment
    # Remove that empty first
    apartments.compact!
    apartments.sort! { |a,b| a.address <=> b.address }


    #
    # Associate each address with its (complex) name
    #
    APT_DELIM = '#'
    complexes = []
    complex = nil
    complex_name = nil
    for apartment in apartments
      # Swap from '123 Apple Lane 230 North #04' to 'Apple Towers Apts #04'
      apt_name = apartment.address
      door_pos = apt_name.rindex(APT_DELIM)
      door_num = ''
      if door_pos
        door_num = apt_name[door_pos, apt_name.length - 1]
        apt_name = apt_name[0, door_pos]
        for name in apartment_names # comes from settings
          if name[0] == apt_name.rstrip
            apt_name = name[1]
            break
          end
        end
      end
      apartment.address = apt_name + door_num
    end
    apartments.sort! { |a,b| b.address <=> a.address }
    for apartment in apartments
      apt_name = apartment.address
      door_pos = apt_name.rindex(APT_DELIM)
      door_num = ''
      if door_pos
        apt_name = apt_name[0, door_pos]
      end
      if complex_name != apt_name
        complexes << complex
        complex_name = apt_name
        complex = Complex.new(complex_name, [])
      end
      complex.apartments << apartment
    end
    complexes.compact!
    complexes.sort! { |a,b| b.name <=> a.name }
    for complex in complexes
        complex.apartments.sort! { |a,b| a.address <=> b.address }
    end
    # TODO find away around this hard-coded hack
    # Order the complexes
    tmp = complexes.clone
    complexes[0] = tmp[1]
    complexes[1] = tmp[0]
    complexes[2] = tmp[2]

    #for complex in complexes
    #	for apartment in complex.apartments
    #		print "\n", complex.name, " ", apartment.address
    #	end
    #end
    #print "\n"


    #
    # Put each complex on a page
    #
    pages = []
    page = []
    row_count = 0
    max_row = 3
    for complex in complexes
      for apartment in complex.apartments
        num_rows = (apartment.people.length / 2.0).ceil
        if (page.length > 2) || ((num_rows + row_count) > max_row)
          page = []
          row_count = 0
        end
        row_count += num_rows
        
        apartment.address = "#{complex.name} #{apartment.address.slice!(/#.*/)}"
        #print "\n", apartment.address, "\n"
        apartment.people.sort! { |a,b| a.alias <=> b.alias } 
        #for person in apartment.people
          #print person.name, " ", person.name.inspect, " ", person.phone_number, " ", person.email, "\n"
          #person.picture = ""
        #end
        page << apartment
        pages << page # creates dups
      end
      pages << page # creates dups
    end
    pages.uniq! # removes dups
    pages.compact! # removes nils

    for page in pages
      for apartment in page
        print "\n", apartment.address
      end
    end
    print "\n"

    #TODO arrange pages for double-sided printing


    #
    # Put page numbers on each person 
    #
    i = 0
    people = []
    for page in pages
      for apartment in page
        for person in apartment.people
          person.page = i + 1 + padding_pages
          people << person
        end
      end
      i += 1
    end


  end

  def add_record(record)
  end

  def new_section(params)
    # with_or_without_pics
    # row_or_block
    # contacts_per_page
    # image_percent_size
  end

  def new_page
    # TODO
    # The ultimate goal would be to make this such that it
    # prepares the PDF such that you only have to hit print.
    # This means that you should be able to do n-per-page
    # printing on single pdf pages.
    #
    # This method will need to track which page it is on
    # and where the fake margins are.
    pdf.start_new_page
  end

  def appendix
  end

  def render
  end

  def save_as(filename)
    pdf.save_as('Ward_Picture_Directory.pdf')
    puts "\n", 'Saved generated picture directory in file named "Ward_Picture_Directory.pdf"'
  end
end

#
# How this might work:
#

# directory = DirectoryPDF.new
# directory.title(ward_name, photo_data)
# directory.subtitle('Membership Directory')

# directory.page_break
# directory.new_section(string_box, int_members_per_page)
# while bishop = bishopric.next
#   directory.add_record(bishop)
# end

# directory.page_break
# directory.subtitle('Leadership')
# directory.new_section(string_list, int_members_per_page)
# while leader = leadership.next
#   directory.add_record(leader)
# end

# while complex = complexes.next
#   directory.page_break
#   directory.subtitle(complex_name, photo_data)
#   directory.page_break
#   while apartment = apartments.next
#     directory.vert_title(complex_name)
#     directory
#   end
# end

# Resources
# http://railscasts.com/episodes/78-generating-pdf-documents




###############################################################
#                                                             #
#                        PDF TIME!!!                          #
#                                                             #
###############################################################
def next_page()
end


#TODO new page layout for each section
#
# BISHOPRIC
#
y = TOP
x = pdf.absolute_left_margin
B_CELL_WIDTH = MARGIN_WIDTH

# TITLE
pdf.font_size = TITLE_FONT
text_x = L_MARGIN + (MARGIN_WIDTH - pdf.text_line_width(title)).to_f / 2
pdf.add_text(text_x, y, title)
y -= TITLE_CELL_HEIGHT * 2

for person in _bishopric
	# First & Last Name
	text_to_add = person.alias
	pdf.select_font "Times-Bold", :encoding => nil
	pdf.font_size = BASE_FONT
	text_x = x + (B_CELL_WIDTH - pdf.text_line_width(text_to_add)).to_f / 2
	pdf.add_text(text_x, y, text_to_add)
	pdf.select_font "Times-Roman", :encoding => nil
	y -= PICTURE_CELL_HEIGHT - 10
      
	# Potrait
	image_info = PDF::Writer::Graphics::ImageInfo.new(person.picture)
	if (nil != image_info && image_info.height != nil)
		scale = PICTURE_HEIGHT.to_f / image_info.height
		image_width = image_info.width * scale
		image_height = image_info.height * scale
		image_x = x + (B_CELL_WIDTH - image_width).to_f / 2
		image_y = y + (PICTURE_CELL_HEIGHT - image_height).to_f / 2
		pdf.add_image(person.picture, image_x, image_y, image_width, image_height)
	end

	# Address
	text_to_add = person.address
	pdf.font_size = BASE_FONT
	text_x = x + (B_CELL_WIDTH - pdf.text_line_width(text_to_add)).to_f / 2
	pdf.add_text(text_x, y, text_to_add)
	y -= TEXT_CELL_HEIGHT
			      
	# Phone Number
	text_to_add = person.phone_number
	pdf.font_size = BASE_FONT
	text_x = x + (B_CELL_WIDTH - pdf.text_line_width(text_to_add)).to_f / 2
	pdf.add_text(text_x, y, text_to_add)
	y -= TEXT_CELL_HEIGHT

	# E-mail
	text_to_add = person.email
	pdf.font_size = EMAIL_FONT
	text_x = x + (B_CELL_WIDTH - pdf.text_line_width(text_to_add)).to_f / 2
	pdf.add_text(text_x, y, text_to_add)
	y -= TEXT_CELL_HEIGHT

	# Space Between Persons
	y -= TEXT_CELL_HEIGHT
end

y = FOOTER
pdf.font_size = BASE_FONT
pager = "Page " + padding_pages.to_s()
text_x = x + (B_CELL_WIDTH - pdf.text_line_width(pager)).to_f / 2
pdf.add_text(text_x, y, pager)

#
# Apartments
#
#orig_pages = pages.clone()
i = 0
# TODO make pages a multiple of four and swap like crazy
#need = (pages_per_page * front) + (pages_per_page * back)
#need = pages.length % 4
#while i < need do
#	pages << nil
#TODO HORRIBLE HACK
#end
#if 0 != pages.length % 2
#	pages << nil
#end

for page in pages
	pdf.start_new_page
	# TODO per page header?
	if nil == page
		next
	end
	#i = orig_pages.index(page) + 1 + padding_pages
	y = TOP
	x = 0
	for apartment in page
		# TODO make work for n-colomns rather than odd/even
		odd = true
		# Apt Title
		#pp pdf.font_families
		for person in apartment.people
			if apartment.people.first == person
				pdf.select_font "Courier-Bold", :encoding => nil
				pdf.font_size = 18
				pdf.add_vertical_text(x - 10, y - 20, apartment.address.upcase)
			end
			pdf.select_font "Times-Bold", :encoding => nil

			# First & Last Name
			text_to_add = person.alias
			pdf.font_size = BASE_FONT
			text_x = x + (CELL_WIDTH - pdf.text_line_width(text_to_add)).to_f / 2
			pdf.add_text(text_x, y, text_to_add)
			y -= PICTURE_CELL_HEIGHT
			pdf.select_font "Times-Roman", :encoding => nil
      
			# Potrait
		    image_info = PDF::Writer::Graphics::ImageInfo.new(person.picture)
			if (nil != image_info && image_info.height != nil)
			    scale = PICTURE_HEIGHT.to_f / image_info.height
			    image_width = image_info.width * scale
			    image_height = image_info.height * scale
			    image_x = x + (CELL_WIDTH - image_width).to_f / 2
				image_y = y + (PICTURE_CELL_HEIGHT - image_height).to_f / 2
				pdf.add_image(person.picture, image_x, image_y, image_width, image_height)
			end
			y -= TEXT_CELL_HEIGHT
      
			# Phone Number
			text_to_add = person.phone_number
			text_x = x + (CELL_WIDTH - pdf.text_line_width(text_to_add)).to_f / 2
			pdf.add_text(text_x, y, text_to_add)
			y -= TEXT_CELL_HEIGHT

			# E-mail
			text_to_add = person.email
			pdf.font_size = EMAIL_FONT
			text_x = x + (CELL_WIDTH - pdf.text_line_width(text_to_add)).to_f / 2
			pdf.add_text(text_x, y, text_to_add)
			y -= TEXT_CELL_HEIGHT

			if odd && person != apartment.people.last
				x += CELL_WIDTH
				y += PICTURE_CELL_HEIGHT + (TEXT_CELL_HEIGHT * 3)
				odd = false
			else
				x -= CELL_WIDTH
				y -= TEXT_CELL_HEIGHT
				odd = true
			end
		end
		#y -= TITLE_CELL_HEIGHT * 1.25
	end
end

#people = open(MARSHAL_FILE) { |f| Marshal.load(f) }
#print "\n<table>"
#people.sort! { |a,b| a.first <=> b.first }
#for person in people
#	print "<tr><td>#{person.alias}</td><td>#{person.phone_number}</td><td>Page #{person.page}</td></tr>"
#end
#print "\n</table>"
#print "\n<table>"
#people.sort! { |a,b| a.last <=> b.last }
#for person in people
#	print "<tr><td>#{person.last}, #{person.first}</td><td>#{person.phone_number}</td><td>Page #{person.page}</td></tr>"
##	print "#{person.last}, #{person.first}, #{person.phone_number}, Page #{person.page}\n"
#end
#print "\n</table>"






