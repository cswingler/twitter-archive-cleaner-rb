#!/usr/bin/env ruby
#
# This is the script that takes the db created by read_archive.rb, and then populates
# the metadata on if a tweet still exists.

require 'json'
require 'logger'
require 'sqlite3'
require 'twitter'
require_relative 'twitter_client'

db_file='data/twitter_archive.sqlite3'
$logger = Logger.new('log/read_api.log')
$logger.info("read_api launched")

# looks up the tweets from tweet_ids. This can only take a maximum of 100,
# if you give more than 100, it raises an exception.
def get_tweet_statuses(twitter_client, tweet_ids)
  $logger.debug("looking up #{tweet_ids.length} tweets")
  if tweet_ids.length > 100
    raise "got more than 100 tweets!"
  end
  statuses = twitter_client.statuses(tweet_ids)
  $logger.info("Asked for #{tweet_ids.length} tweets, got #{statuses.length} back.")
  return statuses
end

# Heads into the database file, gets all the tweet IDs in there, and slices them into <100
# status blocks
def get_ids(db_file)
  db = SQLite3::Database.new db_file
  all_ids = []
  db.execute("select id from tweets") do |row|
    all_ids.append(row[0])
  end
  $logger.debug("all_ids length is #{all_ids.length}")
  all_ids_bucketed = all_ids.each_slice(100).to_a
  all_ids_bucketed.each do |aib|
    $logger.debug("This bucket is #{aib.length} elements long")
  end
  return all_ids_bucketed
end

# Updates the database with the read_attempt_timestamp, read_created_at, read_attempt_last_success
# values.
def populate_db_with_status_info(db_file, expected_statues, status_output)
  # Iterate through each output and grab the stuff we care about:
  db = SQLite3::Database.new db_file
  # We'll need to do a couple passes here. One, we insert everything we've seen.
  # A second one, we see if everything in expected_statuses is in status_output,
  # and for the missing one, populate the table.
  # This var is used to hold every status we insert
  updated_statuses = []
  status_output.each do |status|
    tweet_id = status.id
    read_created_at = status.created_at.strftime('%s')
    read_attempt_timestamp = Time.now.strftime('%s')
    read_attempt_last_success = 1
    update_sql = <<-SQL
      UPDATE tweets SET
            read_attempt_timestamp = ?,
            read_created_at = ?,
            read_attempt_last_success = ?
        WHERE id = ?
    SQL
    db.execute(update_sql, [read_attempt_timestamp, read_created_at, read_attempt_last_success, tweet_id])
    updated_statuses.append(status.id)
  end
  $logger.info("Updated #{updated_statuses.length} in database successfully.")
  # Calculate the tweet IDs that are missing:
  missing_tweets = expected_statues - updated_statuses
  if missing_tweets.length > 0
    $logger.warn("Found these #{missing_tweets.length} tweets missing from the lookup from Twitter: #{missing_tweets}")
    missing_tweets.each do |tweet_id|
      read_attempt_timestamp = Time.now.strftime('%s')
      read_attempt_last_success = 0
      update_sql = <<-SQL
        UPDATE tweets SET
          read_attempt_timestamp = ?,
          read_attempt_last_success = ?
        WHERE id = ?
      SQL
      db.execute(update_sql, [read_attempt_timestamp, read_attempt_last_success, tweet_id])
    end
  end
end


client = setup_client()
$logger.info("Set up twitter client #{client}")
$logger.info("Getting tweets from database file #{db_file}...")
tweets_from_db = get_ids(db_file)
tweet_set_number = 0
tweets_from_db.each do |tweet_list|
  tweet_set_number += 1
  $logger.info("Processing tweet set #{tweet_set_number} / #{tweets_from_db.length} (#{tweet_list.length} tweets)")
  statuses_from_twitter = get_tweet_statuses(client, tweet_list)
  $logger.info("Updating database...")
  populate_db_with_status_info(db_file, tweet_list, statuses_from_twitter)
end
$logger.info("all done!")