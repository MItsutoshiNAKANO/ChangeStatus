package StatusChanger;
use v5.32.1;
use strict;
use warnings;
use utf8;
use CGI;
use DBI;
use Mojo::Log;

=encoding utf8

=head1 NAME

StatusChanger.pm - Change the status.

=head1 SYNOPSIS

    use StatusChanger;

    StatusChanger->new->prepare($opts)->change;

=head1 DESCRIPTION

This class changes the ticket status.

=head1 CONSTANTS

=head2 PARAMS # CGI parameters.

=cut

use constant PARAMS => {
    id => 'INTEGER',
    subject => 'VARCHAR(997)',
    reporter => 'VARCHAR(126)',
    address => 'VARCHAR(126)',
    status => 'VARCHAR(126)',
    description => 'VARCHAR(10485760)'
};

=head2 EXIST # Query to exist.

=cut

use constant EXIST => 'SELECT id FROM tickets WHERE id = ?';

=head2 INSERT # Insert statement.

=cut

use constant INSERT => <<'_END_OF_INSERT_';
INSERT INTO tickets (
        id, subject, reporter, address, status, description, creator, updater
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
_END_OF_INSERT_

=head2 UPDATE # Update statement.

=cut

use constant UPDATE => <<'_END_OF_UPDATE_';
UPDATE tickets
    SET
        subject = COALESCE(?, subject),
        reporter = COALESCE(?, reporter),
        address = COALESCE(?, address),
        status = COALESCE(?, status),
        description = COALESCE(?, description),
        updater = COALESCE(?, updater),
        update_at = CURRENT_TIMESTAMP
    WHERE id = ?
_END_OF_UPDATE_

=head2 RESULT # Results.

=cut

use constant RESULT => {
    OK => { status => 200, code => 200000000, message => 'OK' },
    PARAMETER_ERROR => {
        status => 400, code => 400000000, message => 'Parameter error'
    },
    DB_ERROR => {
        status => 500, code => 500000000, message => 'Database error'
    },
    DB_CONNECTION_ERROR => {
        status => 500, code => 500000001,
        message => 'Database connection error'
    },
    NOT_IMPLEMENTED_YET => {
        status => 500, code => 500999999, message => 'Not implemented yet'
    }
};

=head1 CONSTRUCTOR

=head2 $changer = StatusChanger->new(); # Create new Changer.

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

=head2 $self->_ng($result); # Exit as NG.

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

=head2 $self->_parameter_error(); # Exit as parameter error.

=cut

sub _parameter_error($) {
    my $self = shift;
    $self->_ng(RESULT->{PARAMETER_ERROR});
}

=head2 $self->_ok($result); # Exit as OK.

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

=head2 $self->_validate(); # Validate the parameters.

=cut

sub _validate($) {
    my $self = shift;
    my $params = $self->{_cgi}->Vars or $self->_parameter_error();
    %$params or $self->_parameter_error();
    for my $key (keys %$params) {
        my $type = PARAMS->{$key} or $self->_parameter_error();
        my $value = $params->{$key};
        if ($type eq 'INTEGER') {
            $value =~ m/^\d+$/ or $self->_parameter_error();
        } elsif ($type =~ m{^VARCHAR\((\d+)\)$}) {
            length($value) <= $1 or $self->_parameter_error();
        } else { $self->_parameter_error() }
    }
    $self->{_params} = $params;
}

=head2 $changer->prepare($opts); # Prepare to the changer's options.

=cut

sub prepare($$) {
    my $self = shift;
    my $opts = shift;
    $self->{_log} = $opts->{log} || Mojo::Log->new(
        path => '../logs/StatusChanger.log', level => 'info'
    );
    unless ($self->{_log}) { die 'Log is not defined', $! }
    $self->{_log}->info('begin change()');
    $self->{_cgi} = $opts->{cgi} || CGI->new;
    $self->_validate();
    $self->{_user} = $opts->{user} || $ENV{LOGNAME} || $ENV{USER}
    || getpwuid($<) || getlogin || $ENV{USERNAME} || $<;
    $self->{_dbh} = $opts->{dbh} || DBI->connect(
        'dbi:Pg:dbname=' . $ENV{PGDATABASE}
    );
    unless ($self->{_dbh}) {
        $self->{_log}->error(
            'Database connection error', db_error(qw(DBI)), $!
        );
        $self->_ng(RESULT->{DB_CONNECTION_ERROR});
    }
    return $self;
}

=head2 $changer->change(); # Change the tickets status.

=cut

sub change($) {
    my $self = shift;
    $self->{_dbh}->{AutoCommit} = 0;
    $self->{_dbh}->{RaiseError} = 1;
    my $phase;
    my $sth;
    eval {
        $phase = 1;
        $sth = $self->{_dbh}->prepare(EXIST);
        $phase = 2;
        $sth->execute($self->{_params}->{id});
        $phase = 3;
        my $params = $self->{_params};
        $phase = 4;
        if ($sth->fetch) {
            $phase = 5;
            $self->{_dbh}->do(
                UPDATE, undef, $params->{subject}, $params->{reporter},
                $params->{address}, $params->{status}, $params->{description},
                $self->{_user}, $params->{id}
            );
        } else {
            $phase = 6;
            unless (
                $params->{subject} && $params->{reporter}
                && $params->{address} && $params->{status}
                && $params->{description}
            ) { $self->_ng(RESULT->{PARAMETER_ERROR}) }
            $self->{_dbh}->do(
                INSERT, undef, $params->{id}, $params->{subject},
                $params->{reporter}, $params->{address}, $params->{status},
                $params->{description}, $self->{_user}, $self->{_user}
            );
        }
        $phase = 7;
        $self->{_dbh}->commit;
        $phase = 8;
    };
    if ($@) {
        my $h = ($phase >= 2 && $phase <= 4) ? $sth : $self->{_dbh};
        $self->{_log}->error('Database error', $phase, $@, db_error($h));
        $self->_ng(RESULT->{DB_ERROR});
    }
    $self->_ok(RESULT->{OK});
}

1;

__END__
