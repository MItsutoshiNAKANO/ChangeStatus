=encoding utf8

=head1 NAME

StatusChanger.pm - Change the status.

=head1 SYNOPSIS

    use StatusChanger;
    StatusChanger->new()->change();

=head1 DESCRIPTION

This class changes the ticket status.

=cut

package StatusChanger;
use v5.32.1;
use strict;
use warnings;
use utf8;
use CGI;
use DBI;
use Mojo::Log;

=head1 CONSTANTS 

=head2 PARAMS # CGI parameters.

=cut

use constant PARAMS => {
    id => 'INTEGER',
    subject => 'VARCHAR(997)',
    reporter => 'VARCHAR(126)',
    address => 'VARCHAR(126)',
    status => 'VARCHAR(126)',
    description => 'VARCHAR(10485760)',
    updater => 'VARCHAR(126)'
};

=head2 RESULT # Results.

=cut

use constant RESULT => {
    OK => { status => 200, code => 200000000, message => 'OK' },
    PARAMETER_ERROR => {
        status => 400, code => 400000000, message => 'Parameter Error'
    },
    NOT_FOUND => {
        status => 404, code => 404000000, message => 'Not Found'
    },
    DB_ERROR => {
        status => 500, code => 500000000, message => 'Database Error'
    },
    DB_CONNECTION_ERROR => {
        status => 500, code => 500000001,
        message => 'Database Connection Error'
    },
    DB_NOT_PREPARED => {
        status => 500, code => 500000002,
        message => 'Database Statement Not Prepared'
    },
    DB_NOT_EXECUTED => {
        status => 500, code => 500000003,
        message => 'Database Statement Not Executed'
    },
    NOT_IMPLEMENTED_YET => {
        status => 500, code => 500999999, message => 'Not Implemented'
    }
};

=head1 CONSTRUCTOR

=head2 $changer = StatusChanger->new(); Create new Changer.

=cut

sub new($) {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

=head1 FUNCTIONS

=head2 ($err, $state, $msg) = _db_error($obj); 

Return the database error.

=cut

sub _db_error($) {
    my $obj = shift;
    return ($obj->err, $obj->state, $obj->errstr);
}

=head1 METHODS

=head2 $self->_ng($result); # Return the result as NG.

=head3 See Also

=over 4

=item 1. @see https://man.freebsd.org/cgi/man.cgi?query=sysexits

=item 2. @see https://nxmnpg.lemoda.net/ja/3/sysexits

=back

=cut

sub _ng($$) {
    my $self = shift;
    my $result = shift;
    $self->{_log}->error(
        $result->{status}, $result->{code}, $result->{message}
    );
    say(
        $self->{_cgi}->header(
            -status => $result->{status},
            -type => 'text/plain', -charset => 'us-ascii'
        ), $result->{code}
    ) or do {
        $self->{_log}->error('Failed to respond, because', $!);
        exit(74);
    };
    exit(69);
}

=head2 $self->_ok($result); # Return the result as OK.

=cut

sub _ok($$) {
    my $self = shift;
    my $result = shift;
    $self->{_log}->info(
        $result->{status}, $result->{code}, $result->{message}
    );
    say(
        $self->{_cgi}->header(
            -status => $result->{status},
            -type => 'text/plain', -charset => 'us-ascii'
        ), $result->{code}
    ) or do {
        $self->{_log}->error('Failed to respond, because', $!);
        exit(74);
    };
    exit(0);
}

=head2 $changer->change(); # Change the tickets status.

=cut

sub change($$) {
    my $self = shift;
    my $opts = shift;
    $self->{_log} = $opts->{log} || Mojo::Log->new(
        path => '../logs/StatusChanger.log', level => 'info'
    );
    unless ($self->{_log}) { die 'Log is not defined', $! }
    $self->{_cgi} = $opts->{cgi} || CGI->new;
    $self->{_log}->info('begin change()');
    $self->{_dbh} = $opts->{dbh} || DBI->connect(
        'dbi:Pg:dbname=' . $ENV{PGDATABASE}
    );
    unless ($self->{_dbh}) {
        $self->{_log}->error(
            'Database connection error', db_error(qw(DBI)), $!
        );
        $self->_ng(RESULT->{DB_CONNECTION_ERROR});
    }
    # TODO: Implement the response
    $self->_ng(RESULT->{NOT_IMPLEMENTED_YET});

    $self->_ok(RESULT->{OK});
}

1;

__END__
