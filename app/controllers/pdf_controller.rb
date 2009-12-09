class PdfController < ApplicationController
  #TODO slug it! http://stackoverflow.com/questions/1252506/rails-slugs-in-url-using-record-title-instead-of-id
  require 'pdf/writer'
  require 'pdf/simpletable'
  require 'directorypdf'

  def index
    ward_directory
  end

  def stake_directory
  end

  def ward_directory
    dir = DirectoryPDF.new
    @bishopric = bishopric
    dir.section({:columns => 1, :rows =>3, :left_padding => 10})
=begin
    for person in @bishopric
      dir.add_text_element " "

      # Potrait
      dir.add_image_element person.photo.data, 0.8

      # First & Last Name
      text_to_add = person.first + ' '
      text_to_add += person.second ? person.second + ' ' : ''
      text_to_add += person.third ? person.third + ' ' : ''
      text_to_add += person.last
      dir.add_text_element text_to_add

      # Address
      dir.add_text_element person.address_line_1
      dir.add_text_element person.address_line_2 unless not person.address_line_2
      dir.add_text_element "#{person.city} #{person.state} #{person.zip}"
       
      # Phone Number
      dir.add_text_element person.phone

      # E-mail
      dir.add_text_element person.email, font='Times-Roman', size=10

      person.page_number = dir.page_number
      #TODO puts 'info does not fit in cell' unless dir.top >= dir.cell_height
      dir.next_column 
    end
    dir.next_page
=end
      dir.add_text_element ' '
      dir.next_column 
    dir.next_page
    #Leadership Table
    #dir.section({:columns => 10, :rows =>20, :left_padding => 10})
    #leadership_table.render_on(dir.pdf)
    #dir.next_column
    #dir.next_row
    #dir.next_column
    #dir.next_page
    #dir.pdf.start_new_page

    @membership = members
    complexes = []
    complex = @membership.first.address_group.name
    #@membership.each do |member|
    #  if complex != member.address_group.name
    #    complexes << apartments
    #    complex = member.address_group.name
    #    if apartment != member.address_group.name + ' ' + member.address_line_2
    #      apartments << apartment
    #      apartment
    #    end
    #  end
    #end

    dir.section({:columns => 2, :rows =>3, :left_padding => 10})
    dir.print_page_number = true

    complex_name = @membership.first.address_group.name ? @membership.first.address_group.name : 'Error_Group'
    apartment_name = 'Make it be new' #complex_name + (@membership.first.address_line_2 ? @membership.first.address_line_2 : '')
    for person in @membership
      # Complex
      if complex_name != person.address_group.name
        complex_name = person.address_group.name
        #dir.next_page #TODO 
      end
      
      # Apartment
      new_apartment_name = complex_name + (person.address_line_2 ? ' ' + person.address_line_2 : '')
      if apartment_name != new_apartment_name
        apartment_name = new_apartment_name
        dir.next_page 
        dir.add_vertical_text_element new_apartment_name, font='Courier-Bold', size=10
      end
 
      # Person
      # Potrait
      dir.add_image_element person.photo.data

      # First & Last Name
      text_to_add = person.first + ' '
      text_to_add += person.second ? person.second + ' ' : ''
      text_to_add += person.third ? person.third + ' ' : ''
      text_to_add += person.last
      dir.add_text_element text_to_add
       
      # Phone Number
      dir.add_text_element person.phone

      # E-mail
      dir.add_text_element person.email, font='Times-Roman', size=10

      person.page_number = dir.page_number
      #TODO puts 'info does not fit in cell' unless dir.top >= dir.cell_height
      dir.next_column
    end
    
    dir.next_page
    dir.print_page_number = false
    membership_table().render_on(dir.pdf)

    #dir.save('WardDir')
    send_data dir.pdf.render, :filename => 'Ward_Directory.pdf', :type => "application/pdf" 
  end

  private
    def leadership_table
      PDF::SimpleTable.new do |tab|
        tab.title = "Leadership"
        tab.column_order.push(*%w(calling name phone email))

        tab.columns["calling"] = PDF::SimpleTable::Column.new("calling") { |col|
          col.heading = "Calling"
        }
        tab.columns["name"] = PDF::SimpleTable::Column.new("name") { |col|
          col.heading = "Name"
        }
        tab.columns["phone"] = PDF::SimpleTable::Column.new("phone") { |col|
          col.heading = "Phone"
        }
        tab.columns["email"] = PDF::SimpleTable::Column.new("email") { |col|
          col.heading = "Email"
        }

        tab.show_lines    = :none
        tab.show_headings = true
        tab.orientation   = :center
        tab.position      = :center

        data = []
        current_calling_type = ''
        for calling in leadership
          if current_calling_type != calling.calling_type.name
            current_calling_type = calling.calling_type.name
            data << {"calling" => calling.calling_type.name}
          end
          for contact in calling.contacts
            data << {
                      "calling" => calling.name,
                      "name" => "#{contact.first} #{contact.last}",
                      "phone" => contact.phone,
                      "email" => contact.email,
                    }
          end
        end
        tab.data.replace data
        return tab
        #tab.render_on(pdf)
      end
    end

    def membership_table
      PDF::SimpleTable.new do |tab|
        tab.title = "Membership"
        tab.column_order.push(*%w(name phone email page))

        tab.columns["name"] = PDF::SimpleTable::Column.new("name") { |col|
          col.heading = "Name"
        }
        tab.columns["phone"] = PDF::SimpleTable::Column.new("phone") { |col|
          col.heading = "Phone"
        }
        tab.columns["email"] = PDF::SimpleTable::Column.new("email") { |col|
          col.heading = "Email"
        }
        tab.columns["page"] = PDF::SimpleTable::Column.new("page") { |col|
          col.heading = "Page"
        }

        tab.show_lines    = :none
        tab.show_headings = true
        tab.orientation   = :center
        tab.position      = :center

        data = []
        @membership.sort! {|a,b| a.first <=> b.first}
        for contact in @membership
          first = contact.first + (contact.second ? ' ' + contact.second : '')
          last = (contact.third ? contact.third + ' ' : '') + contact.last

          data << {
                    "name" => "#{first} #{last}",
                    "phone" => contact.phone,
                    "email" => contact.email,
                    "page" => contact.page_number.to_s,
                  }
        end
        tab.data.replace data
        return tab
        #tab.render_on(pdf)
      end
    end

    #TODO move to model
    def bishopric
      return Contact.find(:all, :conditions => ["callings.name LIKE ? AND ward_id = ?", 'Bishop%', current_user.contact.ward], :include => [:callings, :photo], :order => 'callings.name') unless @bishopric
    end

    def leadership
      return Calling.find(:all, :conditions => ["callings.name NOT LIKE ? AND wards.id = ?", 'Bishop%', current_user.contact.ward], :include => [{:contacts => :ward}, :calling_type], :order => :calling_type_id) unless @leadership 
      #return Contact.find(:all, :conditions => ["callings.name IS NOT NULL AND callings.name NOT LIKE ? AND ward_id = ?", 'Bishop%', current_user.contact.ward], :include => [:callings]) unless @leadership 
    end

    def members
      #return (current_user.contact.ward.find(:include => [:contacts => :photo], :order => ['contact.address_line_1, contact.address_line_2, contact.first']).contacts - bishopric) unless @membership
      if not @membership
        @membership = Contact.find(:all, :conditions => {:ward_id => current_user.contact.ward}, :include => [:photo, :address_group], :order => ['address_group_id, address_line_1, address_line_2, first']) - @bishopric
      end
      return @membership
    end

    def same_complex?
      puts 'todo'
    end
    def same_apartment?
      puts 'todo'
    end
end
