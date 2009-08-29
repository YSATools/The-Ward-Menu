class TestLdsorg
  require 'rubygems'
  require 'ldsorg'

  def initialize
    #@ldsorg = Ldsorg.new('user', 'secret')
    abort 'no login' unless @ldsorg.ldslogin
  end

  def test_user_profile
    @ldsorg.user_profile.each {|p| print p, "\n"}
  end

  def test_directory_next 
    @ldsorg.directory_init
    while c = @ldsorg.directory_next
      #print c, "\n"
      #print c.inspect
      if c[:address_line_2]
        puts c[:address_line_2].inspect
        #abort 'stop'
      end
    end
  end

  def test_callings_and_types
    types = @ldsorg.calling_types
    types.each do |t|
      puts t
      tuples = @ldsorg.callings_for_type(t)
      tuples.each { |t|
        calling_name = t[:calling_name]
        c = t[:contact]
        print "\n\n"
        print "calling: ", calling_name, "\n"
        #print "\tfirst:   ", c[:first], "\n"
        #print "\tsecond:  ", c[:second], "\n"
        #print "\tthird:   ", c[:third], "\n"
        #print "\tlast:    ", c[:last], "\n"
        #print "\taddr_1:  ", c[:address_line_1], "\n"
        print "\taddr_2:  ", c[:address_line_2], "\n"
        #print "\tcity:    ", c[:city], "\n"
        #print "\tstate:   ", c[:state], "\n"
        #print "\tzip:     ", c[:zip], "\n"
        #print "\tphone:   ", c[:phone], "\n"
      }
    end
  end
end

test = TestLdsorg.new
test.test_user_profile
#test.test_directory_next
test.test_callings_and_types
