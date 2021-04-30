# This defines the ArchiveTweet object. Use "require_relative 'archive_tweet'" to use it.
class ArchiveTweet
  @@tweet_id
  @@created_at
  @@retweeted
  @@retweet_count
  @@favorite_count

  def initialize(archive_tweet_json)
    tweet = archive_tweet_json['tweet']
    @tweet_id = tweet['id']
    @created_at = DateTime.parse(tweet['created_at'])
    @retweeted = tweet['retweeted']
    @retweet_count = tweet['retweet_count']
    @favorite_count = tweet['favorite_count']
  end

  def sql_tuple()
    # Returns a list whatever it is in ruby? that can be inserted.
    ret_list = []
    ret_list.append(@tweet_id)
    ret_list.append(@created_at.strftime('%s'))
    ret_list.append(@retweeted ? 1: 0)
    ret_list.append(@retweet_count)
    ret_list.append(@favorite_count)
    return ret_list
  end

  # And here's a bunch of classic getters:
  def tweet_id
    @tweet_id
  end
  def created_at
    @created_at
  end
  def retweeted
    @retweeted
  end
  def retweet_count
    @retweet_count
  end
  def favorite_count
    @favorite_count
  end
end