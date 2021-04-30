#!/usr/bin/env ruby
#
# This is the app that reads in the log file and stuffs it into the database file.
# If the DB already exists, this will just quit and say so.

require 'logger'
require 'json'
require 'sqlite3'
require_relative 'archive_tweet'

infile='data/cswingler/data/tweet.js'
db_file='data/twitter_archive.sqlite3'
$logger = Logger.new('log/read_archive.log')
$logger.info("read_archive launched")

# Reads in the tweet file json and reutnrs tha
def read_tweet_file(infile)
  $logger.debug("reading in tweet file")
  r = File.read(infile).sub(/^window.*= /){}
  json_in = JSON.parse(r)
  $logger.warn("Read in #{json_in.length} tweets")
  return json_in
end

# Creates the empty DB file, and returns the db object
def create_database_file(db_file)
  $logger.debug("creating database file")
  if File.file?(db_file)
    $logger.error("database file #{db_file} already exists, quitting.")
    STDERR.puts("database file #{db_file} already exists, quitting")
    exit(1)
  end
  db = SQLite3::Database.new db_file
  table = db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS tweets(
    id INTEGER PRIMARY KEY,
    created_at INTEGER, 
    retweeted INTEGER,
    retweet_count INTEGER,
    favorite_count INTEGER,

    read_attempt_timestamp INTEGER DEFAULT -1,
    read_created_at INTEGER DEFAULT -1,
    read_attempt_last_success INTEGER DEFAULT 0,

    delete_id INTEGER DEFAULT 0,
    delete_timestamp INTEGER DEFAULT -1
  )
  SQL
  return db
end

# Stores the tweets in the DB. Needs the tweet json and db object as parameters.
def store_tweets(tweet_json, db)
  tweets_stored = 0
  total_tweets = tweet_json.length
  tweet_json.each do |tweet|
    aTweet = ArchiveTweet.new(tweet)
    $logger.debug("inserting tweet id #{aTweet.tweet_id}")
    tweets_stored += 1
    db.execute(
      "INSERT OR IGNORE INTO tweets (id, created_at, retweeted, retweet_count, favorite_count) VALUES (?,?,?,?,?)",
      [aTweet.tweet_id, aTweet.created_at.strftime('%s'), aTweet.retweeted ? 1: 0, aTweet.retweet_count, aTweet.favorite_count]
      )
    $logger.debug("inserted #{tweets_stored}/#{total_tweets}")
  end
end

# "if name == '__main__'" isn't a paradigm in Ruby, executable code and libraries are intended
# to be kept seperate.
j = read_tweet_file(infile)
db = create_database_file(db_file)
store_tweets(j, db)