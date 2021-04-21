# tweet deleter

This was a little thing I wrote up when I hit a bug in Twitter's
website where, after deleting 10 years of tweets using TweetDelete.net, they 
came back a few weeks later.

## the tiwtter bug
Old tweets I had deleted would only show up on the Media tab if they had media attached, 
they were otherwise invisible from my main profile.

All tweets that had been deleted _were_ still present though .If you had the direct link
to a tweet you could still view it, if you asked the API how many tweets I had it'd show
over 5000 (when my profile actually only had about 30 post-deletion), and they all remained
in a requested Twitter Archive.

## what this tool does
This needs the output of a Twitter Account Archive (from https://twitter.com/settings/download_your_data)
* Adds the tweet ID and some metadata into a SQLite table.
* Does an un-authenticated HTTP GET against the tweet ID and stores the response in a column (you'll get an 
  `HTTP 404` back if it's been deleted already)
* Stores the timestamp of the last tweet lookup  
  
Then, it re-reads that table and:
* Bangs the Twitter API at https://developer.twitter.com/en/docs/twitter-api/v1/tweets/post-and-engage/api-reference/post-statuses-destroy-id
to delete the offending tweet if it meets a criteria (too old)
* Stores the result of that delete attempt  in the table alongside the original tweet metadata.