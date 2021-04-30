# Save this file as "twitter_client.rb". Get the required keys from the Twitter
# Developer Portal at https://developer.twitter.com/en/portal/petition/use-case
$api_consumer_key = ""
$api_consumer_secret_key = ":
# Warning: So far these are Read Only.
$api_access_token = ""
$api_access_token_secret = ""

def setup_client
  client = Twitter::REST::Client.new do |config|
    config.consumer_key = $api_consumer_key
    config.consumer_secret = $api_consumer_secret_key
    config.access_token = $api_access_token
    config.access_token_secret = $api_access_token_secret
  end
  return client
end

