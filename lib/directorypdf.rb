class DirectoryPDF
  # http://www.bin-co.com/blog/2007/11/creating-pdf-in-ruby-on-rails-pdfwriter/
  # http://www.cnblogs.com/hardrock/archive/2006/07/24/458184.html
  # http://wiki.rubyonrails.org/rails/pages/HowtoIntegrateJasperReports
  #left: 36 .. #right: 576
  #top: 756 .. #bottom: 36
  require 'string_extensions' #int'l #AJ-patch
  require 'pdf/writer'
  require 'pdf/simpletable'
  require 'pdfwriter_utf8' #int'l #AJ-patch
  require 'pdfwriter_add_vertical_text.rb' #AJ-patch
  require 'activesupport'
  require 'rubygems'
  require 'ftools'

  attr_accessor :print_page_number
  attr_reader :pdf, :column_number, :row_number, :page_number

  TEXT_FONT = 12

  def initialize
    @pdf = PDF::Writer.new()

    @top = @pdf.absolute_top_margin
    @bottom = @pdf.absolute_bottom_margin
    @left  = @pdf.absolute_left_margin
    @right = @pdf.absolute_right_margin

    @column_number = 0
    @row_number = 0
    @page_number = 0

    @print_page_number = false
  end

  def left_boundary
    return @pdf.absolute_left_margin + @left_padding
  end

  def top_boundary
    return @pdf.absolute_top_margin - @top_padding
  end

  def right_boundary
    return @pdf.absolute_right_margin - @right_padding
  end

  def bottom_boundary
    return @pdf.absolute_bottom_margin + @bottom_padding
  end

  def height
    return @pdf.absolute_top_margin - @pdf.absolute_bottom_margin
  end

  def width
    return @pdf.absolute_right_margin - @pdf.absolute_left_margin
  end

  def text_height(font='Times-Roman', size=TEXT_FONT)
		@pdf.select_font font, :encoding => nil
		@pdf.font_size = size  
    return @pdf.font_height
  end

  def text_width(font='Times-Roman', size=TEXT_FONT)
		@pdf.select_font font, :encoding => nil
		@pdf.font_size = size
    return @pdf.text_line_width('M')
  end

  def next_column
    @current_column += @cell_width
    if @right < (@current_column + @cell_width)
      next_row #@current_column = left_boundary 
    else
      @left = @current_column
      @top = @current_row
    end
    @column_number += 1
  end

  def next_row #TODO add force option
    return unless (left_boundary != @current_column)
    @current_row -= @cell_height
    if @bottom > (@current_row - @cell_height)
      next_page
    else
      @current_column = left_boundary 
      @left = @current_column
      @top = @current_row
    end
    @row_number += 1
  end

  def next_page
    return unless (top_boundary != @current_row || left_boundary != @current_column)
    if @print_page_number
      # TODO center the text
		  @pdf.add_text left_boundary, bottom_boundary, @page_number.to_s
    end
    @pdf.start_new_page
    @current_column = left_boundary
    @current_row = top_boundary
    @left = @current_column
    @top = @current_row
    @right = right_boundary
    @bottom = bottom_boundary

    @page_number += 1
  end


  def add_text_element(text, font='Times-Roman', size=TEXT_FONT)
		@pdf.select_font(font, :encoding => nil)
		@pdf.font_size = size

		left = @left + (@cell_width - @pdf.text_line_width(text)).to_f / 2
    right = @left + @cell_width
    bottom = @top - @pdf.font_height

		@pdf.add_text left, bottom, text
    @top = bottom
    #return right, bottom
  end
  
  def add_vertical_text_element(text, font='Courier-Bold', size=TEXT_FONT)
    #TODO use 'M'-based centering mechanism for diverse fonts
		@pdf.select_font font, :encoding => nil
		@pdf.font_size = size
    @pdf.add_vertical_text left_boundary, @current_row, text.upcase
  end
  
  def add_image_element(image, ratio=1)
    if not image
      @top -= @max_pic_height
      return
    end

    image_info = PDF::Writer::Graphics::ImageInfo.new(image)
    @top -= @max_pic_height
    if not image_info && image_info.height
      add_text_element 'No Image Data', 'Times-Roman', 12
      return
    end

    height_ratio = @max_pic_height.to_f / image_info.height
    width_ratio = @max_pic_width.to_f / image_info.width
    scale = (height_ratio <= width_ratio ? height_ratio : width_ratio) * ratio
    image_width = image_info.width * scale
    image_height = image_info.height * scale
    image_x = @left + (@cell_width - image_width).to_f / 2
    image_y = @top + ((@max_pic_height - image_height).to_f / 2)

    @pdf.add_image(image, image_x, image_y, image_width, image_height)
  end

  def section(options={})
    next_page unless not @current_row
    options[:padding] = options[:padding] ? options[:padding] : 0
    @left_padding = options[:left_padding] ? options[:left_padding] : options[:padding]
    @top_padding = options[:top_padding] ? options[:top_padding] : options[:padding]
    @right_padding = options[:right_padding] ? options[:right_padding] : options[:padding]
    @bottom_padding = options[:bottom_padding] ? options[:bottom_padding] : options[:padding]

    options[:columns] = options[:columns] ? options[:columns] : 3
    options[:rows] = options[:rows] ? options[:rows] : 3
    @cell_width = (width - @left_padding).to_f / options[:columns]
    @cell_height = (height - (@bottom_padding + @top_padding)).to_f / options[:rows]

    @max_pic_height = @cell_height - (text_height * 4)
    @max_pic_width = @cell_width - (text_width.to_f / 2)

    @top = top_boundary
    @left = left_boundary
    @current_row = top_boundary
    @current_column = left_boundary
  end

  def cell(cell_objects)
    for cell_object in cell_objects
      if TEXT == cell_object[:type]
        font = cell_object[:font]
        size = cell_object[:size]
      end
    end
  end

  def appendix
  end

  def save(name)
    @pdf.save_as(name + '.pdf')
  end


end

