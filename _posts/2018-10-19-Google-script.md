---
layout: post
title: Tweet when donation received
description: My first google script
---

Last month I met Adam Shimoni, who is
[running for Flagstaff city council](http://shimoniforcouncil.com/). I
helped with his campaign by writing the Google Script below which
posts a status update on his Twitter account whenever he gets a
donation. That helps encourage transparency in his campaign
finances. All of the donations are eventually made public on the city
web site, but this script helps people see that info in real time.

How does the script work? The key idea is that every time Adam
receives a donation on a web site, that web site sends him an
automatic email. The Google Script extracts the name of the donor and
the amount of the donation, and then uses that info to do a Twitter
status update.

If you want to adapt this script to tweet to your account, you will
first need to create a new Google Script, copy the code below, and
paste it into your Google Script.

You should then read the
[blog post](https://ctrlq.org/code/19995-google-script-to-twitter)
which explains how to tweet from a Google Script. Basically you have
to set up a Twitter developer account and ask for API keys. You will
need to paste four alphanumeric API key strings in your Google script
(`TWITTER_CONSUMER_KEY`, `TWITTER_CONSUMER_SECRET`,
`TWITTER_ACCESS_TOKEN`, `TWITTER_ACCESS_SECRET`). Also make sure to
enable the Twitterlib library, which implements a JavaScript interface
to the Twitter API, and call it `Twitter`, which is used in the
`sendTweet` function below (`var service = new Twitter.OAuth(props)`).

The script only processes email messages that have been labeled as
"toProcess" so you will have to setup Gmail filters that make the
donation emails end up with that label. We did that by just filtering
on the sender, e.g. if sender is notifications@gofundme.com, then add
"toProcess" label. To deal with labels we use the following helper
function:

```
//create label if it does not yet exist
function getOrCreateLabel(name){
  var label_or_null = GmailApp.getUserLabelByName(name);
  if(label_or_null === null){
    label_or_null = GmailApp.createLabel(name);
  }
  return label_or_null;
}
```

The main body of the script is in the `processNewMessages`
function. Adam has several different donation provider web sites,
which each send emails in a different format. So I wrote a function to
extract to the info for each format:

```
  var fun_array = [
    function(txt){ //gofundme
      var regex = /(.*?) donated [$]([^ ]+)/;
      var match_array = txt.match(regex)
      if(match_array === null){
        return null;
      }else{
        return match_array[0];
      }
    },
    function(txt){//paypal
      var regex = /you have received a donation of ?([$][0-9.]+) USD from ([^(]*) /;
      var match_array = txt.match(regex);
      if(match_array === null){
        return null;
      }else{
        return match_array[2] + " donated " + match_array[1];
      }
    },
    function(txt){//big cartel
      var donor_regex = /=============[\s]+Customer Information[\s]+[=]+[\s]+([A-Za-z ]*$)/m;
      var donor_match = txt.match(donor_regex);
      if(donor_match === null){
        return null;
      }
      var donor_name = donor_match[1];
      var amount_regex = /Total: (.*)/;
      var amount_match = txt.match(amount_regex);
      var amount = amount_match[1];
      return donor_name + " donated " + amount;
    }
    ];
```

If you use one of these web sites (gofundme, paypal, bigcartel) then I
suppose you could just use the code above exactly as I have
written. If you use another web site you will have to adapt the code,
probably by adding a new function to `fun_array`. It should be easy to
support a new format using regular expressions as I have done
above. The idea is that each of those functions is run on every new
email message:

* if there is no match to the expected email pattern/format, then the
  function returns null, and there is no tweet.
* if there is a match, then the function returns a string such as
  "Toby donated $5" which will be used for the tweet.
  
The `processNewMessages` function below is set to run every minute
using a Google Script Trigger.


```
// read and parse gmail messages
function processNewMessages(){
  var toProcess_label = getOrCreateLabel("toProcess");
  var processed_label = getOrCreateLabel("processed");
  var thread_array = toProcess_label.getThreads();
  var total = 0.0;
  var n_messages = 0;
  for (var thread_i = 0; thread_i < thread_array.length; thread_i++) {
    var thread = thread_array[thread_i];
    thread.addLabel(processed_label).removeLabel(toProcess_label).refresh();
    var msg_array = thread.getMessages();
    for(var msg_i=0; msg_i<msg_array.length; msg_i++){ 
      var msg = msg_array[msg_i];
      var subject = msg.getSubject();
      var body = msg.getPlainBody();
      for(var fun_i=0; fun_i<fun_array.length; fun_i++){ 
        var fun = fun_array[fun_i];
        var modified_body = body.replace(/from \n/, "from ");
        //Logger.log(modified_body);
        var tweet_or_null = fun(modified_body);
        if(tweet_or_null === null){
          Logger.log("fun " + fun_i + " did not match message "+ msg_i);
        }else{          
          var tweet = "LIVE Campaign Transparency Report: " + tweet_or_null + " -- Thanks for your support!";
          Logger.log(tweet);
          sendTweet(tweet);
        }
      }
    }
  }
}
```

For debugging the regular expressions, I was just using the Google
Script log instead of twitter -- comment out the `sendTweet(tweet)`
line above.

Note that the code above is a bit wasteful since it runs every
function in `fun_array` on every email message. An improvement would
be to choose the function to use based on the sender of the email (and
not run the other functions). For example, if sender is
notifications@gofundme.com then run the first function in `fun_array`
which is meant for parsing those emails. Anyway the current code runs
in less than a second so it is not a big deal.

Note that you can customize the twitter status update message by
editing the `var tweet` line, which defines the text string that is
sent using the `sendTweet` function:

```
// Send a tweet to the account specified in twitterKeys.
function sendTweet(status) {
  status = status || "another tweet";
  var twitterKeys= { // REPLACE THESE VALUES WITH YOUR TWITTER API KEYS.
    TWITTER_CONSUMER_KEY: "FOO", 
    TWITTER_CONSUMER_SECRET: "BAR",
    TWITTER_ACCESS_TOKEN: "BAZ",
    TWITTER_ACCESS_SECRET: "SARS"
  };
  var props = PropertiesService.getScriptProperties();
  props.setProperties(twitterKeys);
  var service = new Twitter.OAuth(props);
  if ( service.hasAccess() ) {
    var response = service.sendTweet(status);
    if (response) {
      Logger.log("Tweet ID " + response.id_str);
    } else {
      Logger.log("Tweet failed.");
      // Tweet could not be sent
      // Go to View -> Logs to see the error message
    }
  }
}
```

Maybe this code will be useful in someone else's campaign?
