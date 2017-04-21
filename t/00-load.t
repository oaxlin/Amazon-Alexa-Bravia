#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;

use_ok('Net::Amazon::Alexa::Dispatch');
use_ok('Net::Amazon::Alexa::Dispatch::Bravia');

my $json = {};
$json->{'request'}->{'timestamp'} = `date --utc '+%FT%H:%M:%SZ'`; chomp($json->{'request'}->{'timestamp'});
$json->{'request'}->{'intent'}->{'name'} = 'BraviaMuteIntent';
$json->{'request'}->{'intent'}->{'slots'} = {};
$json->{'session'}->{'user'}->{'accessToken'} = 'testing';



my $alexa = Net::Amazon::Alexa::Dispatch->new({
    skillName=>'YourSkillName',
    "Net::Amazon::Alexa::Dispatch" => {
        "alexa_token" => "testing",
        dispatch => ["Net::Amazon::Alexa::Dispatch::Bravia"],
    },
    "Net::Amazon::Alexa::Dispatch::Bravia" => {
        ip => {
            test => '127.0.0.1',
        },
        default_ip => 'test',
        'X-Auth-PSK' => '0000',
    },
});
isa_ok($alexa,'Net::Amazon::Alexa::Dispatch');



my $ret = $alexa->run_method($json);
ok($ret->{'response'}->{'outputSpeech'}->{'text'},'BraviaMuteIntent worked') or diag explain $ret;
