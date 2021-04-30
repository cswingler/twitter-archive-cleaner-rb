# tweet deleter

This was a little thing I wrote up when I hit a bug in Twitter's
website where, after deleting 10 years of tweets using TweetDelete.net, they 
came back a few weeks later.

*WARNING:* This is some super-hacky one-off code I wrote. If you're going to actually 
use it, spend a good amount of time understanding what it does.

This is also the very first thing I wrote using Ruby, so expect a lot of _bizarre_ patterns
if you're an experienced Rubyist.

## the Twitter bug
Old tweets I had deleted would only show up on the Media tab if they had media attached, 
they were otherwise invisible from my main profile.

All tweets that had been deleted _were_ still present, though. If you had the direct link
to a tweet you could still view it, if you asked the API how many tweets I had it'd show
over 5000 (when my profile actually only had about 30 post-deletion), and they all remained
in a requested Twitter Archive.

## what this tool does
This needs the output of a Twitter Account Archive (from https://twitter.com/settings/download_your_data)
* Adds the tweet ID and some metadata into a SQLite table.
* Checks the Twitter API to confirm that the tweet still exists.  
* Stores the timestamp of the last tweet lookup  
  
Then, it re-reads that table and:
* Bangs the Twitter API at https://developer.twitter.com/en/docs/twitter-api/v1/tweets/post-and-engage/api-reference/post-statuses-destroy-id
to delete the offending tweet if it meets a criteria (too old)
* Stores the result of that delete attempt  in the table alongside the original tweet metadata.

## what weird stuff i did here
I'm being super lazy and rather than making a single app that does everything i'm just breaking it up
into a few standalone programs

* `read_archive.rb` reads the archive into a sqlite file called tweets.db
* `read_api.rb` reads the Twitter API and checks if the tweets parsed in the archive are still on Twitter
* `delete_tweets.rb` deletes all the tweets based on some constants.

It's also single-threaded, so it's slow! But you're a lot less likely to get rate-limited that way.