class TestLdsorg
  require 'rubygems'
  require 'ldsorg'

  def initialize
    @ldsorg = Ldsorg.new('user', 'secret')
    abort 'no login' unless @ldsorg.ldslogin
  end

  def test_user_profile
    @ldsorg.user_profile.each {|p| print p, "\n"}
  end

  def test_callings_and_types
    types = @ldsorg.calling_types
    types.each do |t|
      puts t
      callings = @ldsorg.callings_for_type(t)
      callings.each { |c|
        print "\n\n"
        print "calling: ", c[:calling], "\n"
        print "first:   ", c[:first], "\n"
        print "second:  ", c[:second], "\n"
        print "third:   ", c[:third], "\n"
        print "last:    ", c[:last], "\n"
        print "addr_1:  ", c[:address_line_1], "\n"
        print "addr_2:  ", c[:address_line_2], "\n"
        print "city:    ", c[:city], "\n"
        print "state:   ", c[:state], "\n"
        print "zip:     ", c[:zip], "\n"
        print "phone:   ", c[:phone], "\n"
      }
    end
  end
end

test = TestLdsorg.new
test.test_user_profile
test.test_callings_and_types
