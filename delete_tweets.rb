#!/usr/bin/env ruby
# Okay, this one does the heavy lifting. This actually _deletes_ the tweets in question.
# After running this, you'll want to run read_api again to verify all the tweets in question
# are actually gone (and, also, go download an archive from Twitter again to confirm.)

require 'json'
require 'logger'
require 'sqlite3'
require 'twitter'
require 'progress_bar'
require_relative 'twitter_client'

db_file='data/twitter_archive.sqlite3'
$logger = Logger.new('log/delete_tweets.log')
$logger.info("delete_tweets launched")

# Here's where you'll want to tweak the query to make sure you're deleting what you want to.
# Gets a list of every tweet to delete. Does not bucket, as the destroy call is a single-status call
def get_tweets_to_delete(db_file)
  db = SQLite3::Database.new db_file
  tweetsBefore = DateTime.new(2020, 12, 31).strftime('%s')
  lookup = <<-SQL
  SELECT id FROM tweets
    WHERE created_at < ? AND
          read_attempt_last_success = 1 AND
          delete_id = 0
  SQL
  tweets_to_delete = []
  db.execute( lookup, [tweetsBefore]) do |row|
    tweets_to_delete.append(row[0])
  end
  all_tweets_len = db.execute("SELECT id FROM tweets").length
  $logger.info("Found #{tweets_to_delete.length} tweets to delete out of a total of #{all_tweets_len}")
  return tweets_to_delete
end

# Deletes the tweet in question, and updates the DB.
def delete_tweet(db_file, twitter_client, tweet_id)
  db = SQLite3::Database.new db_file
  $logger.info("Deleting tweet id #{tweet_id}")
  destroy_output = twitter_client.destroy_status(tweet_id)
  $logger.debug("Deleted tweet id #{tweet_id}, updating DB")
  delete_id = destroy_output.id
  delete_timestamp = Time.now.strftime('%s')
  update_sql = <<-SQL
    UPDATE tweets SET
      delete_id = ?,
      delete_timestamp = ?
    WHERE id = ?
  SQL
  db.execute(update_sql, [delete_id, delete_timestamp, tweet_id])
end

delete_tweets = get_tweets_to_delete(db_file)
puts "You're about to delete #{delete_tweets.length}."
puts "Here's your chance to send a SIGINT and get out!"
gets
puts "okay, here we go!"
client = setup_client()
$logger.info("Set up twitter client #{client}")
bar = ProgressBar.new(delete_tweets.length, :counter, :percentage, :elapsed, :eta, :rate)
delete_tweets.each do |tweet_to_delete|
  bar.increment!
  delete_tweet(db_file, client, tweet_to_delete)
end
$logger.info("all done!")