#!/usr/bin/env ruby
require 'test/unit'
class TC_MyTest < Test::Unit::TestCase

  def test_all
    puts "LDSAccount: "
    user = gets.chomp
    puts "Passphrase: "
    pass = gets.chomp

    require 'ldsorg'
    @ldsorg = Ldsorg.new
    abort 'no login' unless @ldsorg.ldslogin user, pass

  #test_user_profile
    pp @ldsorg.stake.name
    pp @ldsorg.ward.name

    pp @ldsorg.user_profile

  #test_wards
    @ldsorg.wards

    @ldsorg.ward
    @ldsorg.ward.page
    pp @ldsorg.ward.directory
    abort "stop"
  #test_callings_and_types
    types = @ldsorg.ward.calling_types
    pp types
    types.each do |t|
      puts t
      tuples = @ldsorg.ward.callings_for_type(t)
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

require 'test/unit/ui/console/testrunner'
Test::Unit::UI::Console::TestRunner.run(TC_MyTest)
