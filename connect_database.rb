#!/usr/bin/ruby

require "rubygems"
require "sequel"

module ConnectDatabase
  DB = Sequel.connect('mysql2://intern:livesense@10.26.2.77/jobtalk_dump')

  module_function

  def gets_libel_learning(limit, offset)
    DB[:comments].where(libel:1).order{id.desc}.limit(limit, offset).select(:comment).map(&:values)
  end

  def gets_approval_learning(limit, offset)
    DB[:comments].where(approved:1, member_career_post_id:1297552..1379231).order{id.desc}.limit(limit, offset).select(:comment).map(&:values)
  end

  def gets_libel_test
    DB[:comments].where(libel:1).order{id.asc}.limit(400).select(:comment).map(&:values)
  end

  def gets_approval_test
    DB[:comments].where(approved:1, member_career_post_id:1297552..1379231).order{id.asc}.limit(400).select(:comment).map(&:values)
  end
end
