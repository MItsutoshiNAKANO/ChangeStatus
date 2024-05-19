package StatusChanger::Response;
use v5.32.1;
use strict;
use warnings;
use utf8;

=encoding utf8

=head1 NAME

StatusChanger::Response - Response to the StatusChanger.

=head1 SYNOPSIS

    use StatusChanger::Response;
    my $resp = StatusChanger::Response->new;
    $resp->prepare({ log => $log, cgi => $cgi });
    return $resp->ok;

=head1 DESCRIPTION

=head1 CONSTANTS

=head2 RESULT # Results.

=cut

use constant {
    OK => { status => 200, code => 200000000, exit => 0, message => 'OK' },
    PARAMETER_ERROR => {
        status => 400, code => 400000000, exit => 64,
        message => 'Parameter error'
    }, DB_ERROR => {
        status => 500, code => 500000000, exit => 69,
        message => 'Database error'
    }, DB_CONNECTION_ERROR => {
        status => 500, code => 500000001, exit => 69,
        message => 'Database connection error'
    }, NOT_IMPLEMENTED_YET => {
        status => 500, code => 500999999, exit => 70,
        message => 'Not implemented yet'
    }
};

=head1 CONSTRUCTOR

=head2 $resp = StatusChanger::Response->new; # Create the instance.

=cut

sub new($) {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

=head1 METHODS

=head2 $resp->prepare({ log => $log, cgi => $cgi });

Prepare the instance.

=cut

sub prepare($$) {
    my $self = shift;
    my $opts = shift;
    $self->{log} = $opts->{log};
    $self->{cgi} = $opts->{cgi};
    return $self;
}

=head2 $self->_respond($result); # Respond to the client.

=cut

sub _respond($$) {
    my $self = shift;
    my $result = shift;
    say(
        $self->{cgi}->header(
            -status => $result->{status},
            -type => 'text/plain', -charset => 'us-ascii'
        ), $result->{code}
    ) or die 'Failed to respond';
    return 1;
}

=head2 $resp->ng($result); # Return NG.

=cut

sub _ng($$) {
    my $self = shift;
    my $result = shift;
    my $r = $result;
    $self->{log}->error($r->{status}, $r->{code}, $r->{message});
    $self->_respond($result);
    exit($r->{exit});
}


=head2 $resp->parameter_error(); # Return parameter error.

=cut

sub parameter_error($) {
    my $self = shift;
    return $self->_ng(PARAMETER_ERROR);
}

=head2 $resp->db_error(); # Return database error.

=cut

sub db_error($) {
    my $self = shift;
    return $self->_ng(DB_ERROR);
}

=head2 $resp->db_connection_error(); # Return DB connection error.

=cut

sub db_connection_error($) {
    my $self = shift;
    return $self->_ng(DB_CONNECTION_ERROR);
}

=head2 $resp->not_implemented_yet(); # Return not implemented yet.

=cut

sub not_implemented_yet($) {
    my $self = shift;
    return $self->_ng(NOT_IMPLEMENTED_YET);
}

=head2 $resp->ok($result); # Return OK.

=cut

sub ok($) {
    my $self = shift;
    my $result = OK;
    my $r = $result;
    $self->{log}->info($r->{status}, $r->{code}, $r->{message});
    $self->_respond($r);
    exit(0);
}

1;
__END__
