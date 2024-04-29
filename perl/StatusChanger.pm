package StatusChanger;
use v5.32.1;
use strict;
use warnings;
use utf8;
use DBI;
use CGI;

=encoding utf8

=head1 NAME

StatusChanger.pm - Change the status.

=head1 SYNOPSIS

    use StatusChanger;
    my $changer = StatusChanger->new;
    $changer->prepare($opts);
    $changer->change;

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

=head2 $changer->_respond($result); # Respond to the client.

=cut

sub _respond($$) {
    my $self = shift;
    my $result = shift;
    say(
        $self->{_cgi}->header(
            -status => $result->{status},
            -type => 'text/plain', -charset => 'us-ascii'
        ), $result->{code}
    ) or die 'Failed to respond';
    return 1;
}

=head2 $self->_ng($result); # Return NG.

=cut

sub _ng($$) {
    my $self = shift;
    my $result = shift;
    my $r = $result;
    $self->{log}->error($r->{status}, $r->{code}, $r->{message});
    $self->_respond($result);
    return undef;
}

=head2 $self->_ok($result); # Return OK.

=cut

sub _ok($$) {
    my $self = shift;
    my $result = shift;
    my $r = $result;
    $self->{log}->info($r->{status}, $r->{code}, $r->{message});
    return $self->_respond($result);
}

=head2 $params_or_undef = $self->_validate();

Validate the parameters.

=cut

sub _validate($) {
    my $self = shift;
    my $params = $self->{_cgi}->Vars or return undef;
    %$params or return undef;
    for my $key (keys %$params) {
        my $type = PARAMS->{$key} or return undef;
        my $value = $params->{$key};
        if ($type eq 'INTEGER') { $value =~ m/^\d+$/ or return undef }
        elsif (my ($length) = $type =~ m{^VARCHAR\((\d+)\)$}) {
            length($value) <= $length or return undef;
        } else { die "Invalid type $type, $key " }
    }
    return $self->{_params} = $params;
}

=head2 $chager_or_undef = $changer->prepare($opts);

Prepare to the changer's options.

=cut

sub prepare($$) {
    my $self = shift;
    my $opts = shift;
    $self->{log} = $opts->{log};
    $self->{log}->info('prepare()');
    $self->{_cgi} = $opts->{cgi} || CGI->new;
    $self->_validate() or return $self->_ng(RESULT->{PARAMETER_ERROR});
    $self->{_user} = $opts->{user} || $ENV{LOGNAME} || $ENV{USER}
    || getpwuid($<) || getlogin || $ENV{USERNAME} || $<;
    $self->{_dbh} = $opts->{dbh} || DBI->connect(
        'dbi:Pg:dbname=' . $ENV{PGDATABASE}
    );
    unless ($self->{_dbh}) {
        $self->{log}->error(
            'Database connection error', _db_error(qw(DBI)), $!
        );
        return $self->_ng(RESULT->{DB_CONNECTION_ERROR});
    }
    return $self;
}

=head2 $changer->change(); # Change the tickets status.

=cut

sub change($) {
    my $self = shift;
    $self->{log}->info('change()');
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
            ) { return $self->_ng(RESULT->{PARAMETER_ERROR}) }
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
        $self->{log}->error('Database error', $phase, db_error($h), $@);
        return $self->_ng(RESULT->{DB_ERROR});
    }
    return $self->_ok(RESULT->{OK});
}

1;

__END__
