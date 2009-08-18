require 'rubygems'
require 'ldsorg'
ldsorg = Ldsorg.new('notmyuser', 'notmypassword')
abort 'no login' unless ldsorg.ldslogin
puts ldsorg.user_profile
abort 'init troubles' unless ldsorg.directory_init
puts ldsorg.directory_length, ' '
puts ldsorg.directory_next
