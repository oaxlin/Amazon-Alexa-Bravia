package Net::Amazon::Alexa::Dispatch::Bravia;
use strict;
use warnings;
use lib qw(/home/oaxlin/alexa/lib);
use base 'Net::Amazon::Alexa::Dispatch';

my $me = 'Net::Amazon::Alexa::Dispatch::Bravia';

=head1 NAME

Net::Amazon::Alexa::Dispatch::Bravia - Perl extensions for interacting with a Sony Bravia smart TV

=head1 SYNOPSIS

  use Net::Amazon::Alexa::Dispatch;

  my $alexa = Net::Amazon::Alexa::Dispatch->new({
      skillName=>'YourSkillName',
      "Net::Amazon::Alexa::Dispatch" : {
          "alexa_token" : "some-secret-password"
      },
      "Net::Amazon::Alexa::Dispatch::Bravia" : {
          "ip" : {
              "somename"   : "10.0.0.23",
              "upstairs"   : "10.0.0.23",
              "downstairs" : "10.0.0.24"
          },
          "default_ip" : "upstairs",
          "X-Auth-PSK" : "0000", # can also be a hash with keynames similar to "ip"
      },
  });
  $alexa->run_method($json);

=head1 DESCRIPTION

A Perl module which provides a simple and lightweight interface from the Net::Amazon::Alexa::Dispatch::Bravitch
to your Bravia television.

=head1 METHODS

A list of methods available.

Each method has a corrisponding __meta that provides useful information about the method.
This extra information is used to tell the dispatcher which utternces should trigger
a method.

=cut

my $actions = {
    'turn off' => 'AAAAAQAAAAEAAAAvAw==',
    'mute'     => 'AAAAAQAAAAEAAAAUAw==',
    'unmute'   => 'AAAAAQAAAAEAAAAUAw==',
    'netflix'  => 'AAAAAgAAABoAAAB8Aw==',
};

=head2 alexa_intent_BraviaOffIntent__meta

=head2 alexa_intent_BraviaOffIntent( $json )

  Turns off your TV

=head2 alexa_intent_BraviaMuteIntent__meta

=head2 alexa_intent_BraviaMuteIntent( $json )

=head2 alexa_intent_BraviaUnMuteIntent__meta

=head2 alexa_intent_BraviaUnMuteIntent( $json )

  Toggles the mute/unmute state of the TV.

=head2 alexa_intent_BraviaNetflixIntent__meta

=head2 alexa_intent_BraviaNetflixIntent( $json )

  Opens the Netflix smart TV app

=cut

sub alexa_intent_BraviaOffIntent { shift->_bravia_intent('turn off',@_); }
sub alexa_intent_BraviaOffIntent__meta{ shift->_bravia_intent__meta('turn off'); }
sub alexa_intent_BraviaMuteIntent { shift->_bravia_intent('mute',@_); }
sub alexa_intent_BraviaMuteIntent__meta{ shift->_bravia_intent__meta('mute'); }
sub alexa_intent_BraviaNetflixIntent { shift->_bravia_intent('netflix',@_); }
sub alexa_intent_BraviaNetflixIntent__meta{ {
    utterances => [
        'open netflix',
    ],
} }
sub alexa_intent_BraviaUnMuteIntent { shift->_bravia_intent('unmute',@_); }
sub alexa_intent_BraviaUnMuteIntent__meta{ shift->_bravia_intent__meta('unmute'); }

sub _bravia_intent {
    my ($self, $cmd, $json) = @_;
    my $args = $self->slots_to_hash($json);
    my $config = $self->{'config'}->{ref $self};
    my $ip = $config->{'ip'}->{$args->{'bravia_location'}//''} // $config->{'ip'}->{$config->{'default_ip'}//'default'};
    return "Missing television ip\n" unless $ip && ! ref $ip;
    my $X_Auth_PSK = $config->{'X-Auth-PSK'};
    $X_Auth_PSK = $X_Auth_PSK->{$args->{'bravia_location'} // $config->{'default_ip'} // 'default'} if ref $X_Auth_PSK eq 'HASH';
    return "Missing television x auth psk value\n" unless defined $X_Auth_PSK && ! ref $X_Auth_PSK;
    my $irccode = $actions->{$cmd};
    return "Missing television i r c code\n" unless defined $irccode;
    my $data =<<EOF;
<?xml version="1.0"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
    <u:X_SendIRCC xmlns:u="urn:schemas-sony-com:service:IRCC:1">
      <IRCCCode>$irccode</IRCCCode>
    </u:X_SendIRCC>
  </s:Body>
</s:Envelope>
EOF
    my $exec = "/usr/bin/curl -s http://$ip/sony/IRCC -d '$data' -H 'Content-Type: text/xml; charset=UTF-8' -H 'SOAPACTION: \"urn:schemas-sony-com:service:IRCC:1#X_SendIRCC\"' -H \"X-Auth-PSK: $X_Auth_PSK\" --connect-timeout 2 -v 2>&1";
    my $resp = `$exec`;
    return "Television auth failed.  Please set a valid x auth p s k value in the config" if $resp =~ /<errorCode>606<\/errorCode>/;
    return $resp =~ /X_SendIRCCResponse/ ? "OK" : "T V is not on";
}

sub _bravia_intent__meta {
    my ($self,$action) = @_;
    my $config = $self->{'config'}->{ref $self};
    my $modifier = '';
    $modifier = '{bravia_location} ' if scalar @{$config->{'locations'}};
    my $ret = {
        utterances => [
            (($modifier && $config->{'default_ip'}) ? ($action.' the tv') : ()),
            (($modifier && $config->{'default_ip'}) ? ($action.' the television') : ()),
            $action.' the '.$modifier.'tv',
            $action.' the '.$modifier.'television',
        ],
    };
    $ret->{'slots'} = [
            {name=>"bravia_location",type=>"bravia_location",values=>$config->{'locations'}},
        ] if scalar @{$config->{'locations'}};
    return $ret;
}

1;
