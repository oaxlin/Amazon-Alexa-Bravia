package Amazon::Alexa::Bravia;
use strict;
use warnings;
use Amazon::Alexa::Dispatch;
use JSON;

my $me = 'Amazon::Alexa::Bravia';

=head2 alexa_configure

  See Amazon::Alexa::Dispatch

=cut

sub alexa_configure {{
    intentPrefix => 'alexa_intent_',
}}

=head2 alexa_create_token

  See Amazon::Alexa::Dispatch

=cut

sub alexa_create_token {
    my ($self,$param) = @_;
    return 'fake' if ($param->{'Password'} && $param->{'Password'} eq 'fake');
    my $fields = {};
    $fields->{$_} = { type=>'hidden', value=> $param->{$_} } foreach keys %$param;
    $fields->{'Password'} = { type=>'password' };
    Amazon::Alexa::Dispatch->alexa_login_helper( 'Fake Alexa Login','Please type "fake" into the password field.', $fields );
    return '';
}

=head2 alexa_authenticate_token( $method, $token )

  See Amazon::Alexa::Dispatch

=cut

sub alexa_authenticate_token {
    my ($class, $method, $p) = @_;
    warn $method,$p;
    return 'nobody' if $p eq 'fake' && $method =~ /^alexa_intent_(HelloIntent|BraviaOffIntent)$/;
    return '';
}

=head2 alexa_intent_BraviaOffIntent( $user, $json )

  Turns off your TV

=cut

sub alexa_intent_BraviaOffIntent {
    my ($class, $user, $json) = @_;
    my $resp = `/usr/bin/curl http://10.0.0.4/sony/IRCC -d \@/home/jter/sony.off.soap -H 'Content-Type: text/xml; charset=UTF-8' -H 'SOAPACTION: "urn:schemas-sony-com:service:IRCC:1#X_SendIRCC"' -H "X-Auth-PSK: 0000" --connect-timeout 2 2>/dev/null`;
    return $resp =~ /X_SendIRCCResponse/ ? "OK" : "T V is not on";
}

=head2 alexa_intent_BraviaOffIntent__meta

  See Amazon::Alexa::Dispatch

=cut

sub alexa_intent_BraviaOffIntent__meta{
    return {
        utterances => [
            'turn off the tv',
        ],
        # slots => [{name=>"someName",type=>"someType"},{name=>"anotherName",type=>"anotherType"}]
    }
}

1;
