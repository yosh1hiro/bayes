
require "rubygems"
require "sequel"

DB = Sequel.connect('mysql2://intern:livesense@10.26.2.77/jobtalk_dump')
# a = DB[:comments].where(libel:1).order{id.desc}.limit(3581).select(:comment).map(&:values)
# libels = DB[:comments].where(approved:1, member_career_post_id:1297552..1379231).order{id.desc}.limit(2).select(:comment).map(&:values)
#
# File.write("approval_learning.txt", libels.join(", "))

# a = DB[:comments].where(libel:1).order{id.asc}.limit(100).select(:comment).map(&:values)

b = DB[:comments].where(libel:1).count
p b
# a.each do |l|
#   p "1: #{l.join(" ")}"
# end
