package Amazon::Alexa::Bravia;
use strict;
use warnings;
use Amazon::Alexa::Dispatch;
use JSON;

my $me = 'Amazon::Alexa::Bravia';

my $actions = {
    'turn off' => 'AAAAAQAAAAEAAAAvAw==',
    'mute'     => 'AAAAAQAAAAEAAAAUAw==',
    'unmute'   => 'AAAAAQAAAAEAAAAUAw==',
    'netflix'  => 'AAAAAgAAABoAAAB8Aw==',
};

=head2 alexa_configure

  See Amazon::Alexa::Dispatch

=cut

sub alexa_configure {
    my $class = shift;
    my $config = shift // {};
    $config->{'locations'} = [keys %{$config->{'ip'}}] if ref $config->{'ip'};
    my $node = {
        intentPrefix => 'alexa_intent_',
        %$config,
    };
    return bless $node, $class;
}

=head2 alexa_create_token

  See Amazon::Alexa::Dispatch

=cut

sub alexa_create_token {
    my ($self,$param) = @_;
    my $want = $self->{'alexa_token'};
    return $want if ($param->{'Password'} && $param->{'Password'} eq $want);
    my $fields = {};
    $fields->{$_} = { type=>'hidden', value=> $param->{$_} } foreach keys %$param;
    $fields->{'Password'} = { type=>'password' };
    Amazon::Alexa::Dispatch->alexa_login_helper( 'Alexa Login','Please type your token into the password field.', $fields );
    return '';
}

=head2 alexa_authenticate_token( $method, $token )

  See Amazon::Alexa::Dispatch

=cut

sub alexa_authenticate_token {
    my ($self, $method, $p) = @_;
    my $want = $self->{'alexa_token'};
    return 'nobody' if $p eq $want;
    return '';
}

=head2 alexa_intent_BraviaOffIntent( $user, $json )

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
    my ($self, $cmd, $user, $args, $json) = @_;
    my $ip = $self->{'ip'}->{$args->{'bravia_location'}} // $self->{'ip'}->{$self->{'default_ip'}//'default'};
    return "Missing television ip\n" unless $ip;
    my $X_Auth_PSK = $self->{'X-Auth-PSK'};
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
    my $modifier = '';
    $modifier = '{bravia_location} ' if scalar @{$self->{'locations'}};
    my $ret = {
        utterances => [
            (($modifier && $self->{'default_ip'}) ? ($action.' the tv') : ()),
            (($modifier && $self->{'default_ip'}) ? ($action.' the television') : ()),
            $action.' the '.$modifier.'tv',
            $action.' the '.$modifier.'television',
        ],
    };
    $ret->{'slots'} = [
            {name=>"bravia_location",type=>"bravia_location",values=>$self->{'locations'}},
        ] if scalar @{$self->{'locations'}};
    return $ret;
}

1;
