#!/usr/bin/perl
#
#  Load the contents of a Wordpress blog into Tumblr.
#
#
#  Copyright (C) 2012 by James A. Chappell (rlrrlrll@gmail.com)
#
#  Permission is hereby granted, free of charge, to any person
#  obtaining a copy of this software and associated documentation
#  files (the "Software"), to deal in the Software without
#  restriction, including without limitation the rights to use,
#  copy, modify, merge, publish, distribute, sublicense, and/or
#  sell copies of the Software, and to permit persons to whom the
#  Software is furnished to do so, subject to the following
#  condition:
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
#  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#  OTHER DEALINGS IN THE SOFTWARE.

use Net::OAuth;
$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

use XML::Simple;
use LWP::UserAgent;

use strict;

#
# Go to http://www.tumblr.com/oauth/apps to obtain a consumer_key and
# consumer secret.
#
my $consumer_key = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
my $consumer_secret = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';

#
# set $blog to your Tumblr site
#
my $blog = '';

#
# One must authorize the app and obtain a oauth_token and
# oauth_token_secret. One can us the  Python script found
# here: https://gist.github.com/2296339
#
my $oauth_token = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
my $oauth_token_secret = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";

my %oauth_api_params =
    ('consumer_key' => $consumer_key,
     'consumer_secret' => $consumer_secret,
     'token' => $oauth_token,
     'token_secret' => $oauth_token_secret,
     'signature_method' =>
        'HMAC-SHA1',
     request_method => 'POST'
);

#
# Input is the .xml file exported from Wordpress
#
my $infile = $ARGV[0];

my $url = 'http://api.tumblr.com/v2/blog/' . $blog . '/post';

my $xml = new XML::Simple;

my $data = $xml->XMLin($infile);

my $base_url = $data->{channel}->{link};
my $base_url_len = length($base_url);

my $ua = LWP::UserAgent->new;
$ua->agent('Wordpress2Tumplr/0.1');

foreach my $item (@{$data->{channel}->{item}})
{
  my $title = $item->{title};
  my $date = $item->{'wp:post_date'};
  my $content = $item->{'content:encoded'};

  my $request = Net::OAuth->request("protected resource")->new
        (request_url => $url,
         %oauth_api_params,
         timestamp => time(),
         nonce => rand(1000000),
         extra_params => {
             'type' => 'text',
             'body' => $content,
             'title' => $title,
             'date' => $date,
         });

  $request->sign;

  my $response = $ua->post($url, Content => $request->to_post_body);

  if ( $response->is_success )
  {
    print $item->{link} . "|" . $response->as_string . "\n" ;
  }
  else
  {
#
#   assume a failure is not recoverable and exit
#
    print "Cannot create Tumblr entry: " . $response->as_string . "\n";
    exit;
  }

#
#  Tumblr limits the number of posts per day, so...
#
  sleep(3600);
}
