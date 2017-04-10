package Amazon::Alexa::Bravia;
use strict;
use warnings;
use lib qw(/home/oaxlin/alexa/lib);
use base 'Amazon::Alexa::Dispatch';

my $me = 'Amazon::Alexa::Bravia';

my $actions = {
    'turn off' => 'AAAAAQAAAAEAAAAvAw==',
    'mute'     => 'AAAAAQAAAAEAAAAUAw==',
    'unmute'   => 'AAAAAQAAAAEAAAAUAw==',
    'netflix'  => 'AAAAAgAAABoAAAB8Aw==',
};

=head2 alexa_intent_BraviaOffIntent( $args, $json )

  Turns off your TV

=head2 alexa_intent_BraviaOffIntent__meta

  See Amazon::Alexa::Dispatch

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
    my $ip = $config->{'ip'}->{$args->{'bravia_location'}} // $config->{'ip'}->{$config->{'default_ip'}//'default'};
    return "Missing television ip\n" unless $ip;
    my $X_Auth_PSK = $config->{'X-Auth-PSK'};
    return "Missing television x auth psk value\n" unless defined $X_Auth_PSK;
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
