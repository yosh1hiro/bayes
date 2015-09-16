#!/usr/bin/ruby

require "rubygems"
require "sequel"

module ConnectDatabase
  DB = Sequel.connect('mysql2://intern:livesense@10.26.2.77/jobtalk_dump')
  def gets_libel
    DB[:comments].where(libel:1).order{id.asc}.limit(400).select(:comment).map(&:values).flatten
  end
  module_function :gets_libel
  def gets_approval
    DB[:comments].where(approved:1, member_career_post_id:1297552..1379231).order{id.asc}.limit(400).select(:comment).map(&:values).flatten
  end
  module_function :gets_approval
end
