class Contacts
  def import_directory 
    @records = []
    #... get names and photo urls
    @records << [:name => 'abc']
    @records << [:name => 'jkl']
    @records << [:name => 'xyz']
    return true
  end

  def next_contact
    if not @gen
      create_generator
    end
    return @gen.next
  end

  private
  def create_generator
    require 'generator'
    @gen = Generator.new do |g|
      for record in @records
        g.yield record
      end
      g.yield nil
    end
  end
end

contacts = Contacts.new
if not contacts.import_directory
  abort 'Invalid Import'
end

while record = contacts.next_contact
  puts record
end
