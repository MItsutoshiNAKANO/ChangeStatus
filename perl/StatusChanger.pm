package StatusChanger;
use v5.32.1;
use strict;
use warnings;
use utf8;
use CGI;
use Data::Dumper;
use StatusChanger::Response;
use StatusChanger::Db;


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
    description => 'VARCHAR(10485760)',
    creator => 'VARCHAR(126)',
    updater => 'VARCHAR(126)',
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

=head2 $params_or_undef = $self->_validate();

Validate the parameters.

=cut

sub _validate($) {
    my $self = shift;
    # $self->{log}->trace(Dumper($self));
    my $params = $self->{cgi}->Vars or die 'No parameters';
    # $self->{log}->trace(Dumper($params));
    %$params or return undef;
    for my $key (keys %$params) {
        my $type = PARAMS->{$key} or die "Invalid parameter $key";
        my $value = $params->{$key};
        if ($type eq 'INTEGER') {
            if ($value =~ m/(\D+)/) { die "Invalid value $1, $key" }
        } elsif (my ($length) = $type =~ m{^VARCHAR\((\d+)\)$}) {
            my $actual = length($value);
            $actual <= $length or die "Length $actual > $length, $key";
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
    my $log = $self->{log} = $opts->{log};
    $log->info('prepare()');
    $self->{cgi} = $opts->{cgi} || CGI->new;
    $self->{resp} = StatusChanger::Response->new->prepare($self);
    eval { $self->_validate };
    if ($@) {
        $log->fatal('Parameter error', $@);
        return $self->{resp}->parameter_error;
    }
    $self->{_user} = $opts->{user} || $ENV{LOGNAME} || $ENV{USER}
    || getpwuid($<) || getlogin || $ENV{USERNAME} || $<;
    $self->{_dbh} = $opts->{dbh} || DBI->connect(
        'dbi:Pg:dbname=' . $ENV{PGDATABASE}
    );
    unless ($self->{_dbh}) {
        $log->error(
            'Database connection error', _db_error(qw(DBI)), $!
        );
        return $self->{resp}->db_connection_error;
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
    my $p = $self->{_params};
    $self->{log}->info('Parameters', %$p);
    my $phase = 1;
    my $sth;
    unless ($sth = $self->{_dbh}->prepare(EXIST)) {
        my @message = db_error($self->{_dbh});
        $self->{log}->fatal('Failed preparing', @message);
        die "@message";
    }
    eval {
        $phase = 2;
        $sth->execute($p->{id});
        $phase = 3;
        if ($sth->fetch) {
            $phase = 4;
            $self->{_dbh}->do(
                UPDATE, undef, $p->{subject}, $p->{reporter}, $p->{address},
                $p->{status}, $p->{description}, $self->{_user}, $p->{id}
            );
        } else {
            $phase = 5;
            unless (
                $p->{subject} && $p->{reporter} && $p->{address}
                && $p->{description}
            ) {
                $self->{resp}->parameter_error;
            }
            $self->{_dbh}->do(
                INSERT, undef, $p->{id}, $p->{subject}, $p->{reporter},
                $p->{address}, $p->{status}, $p->{description},
                $self->{_user}, $self->{_user}
            );
        }
        $phase = 6;
        $self->{_dbh}->commit;
        $phase = 7;
    };
    if ($@) {
        my $h = ($phase >= 2 && $phase <= 3) ? $sth : $self->{_dbh};
        $self->{log}->error('Database error', $phase, db_error($h), $@);
        return $self->{resp}->db_error;
    }
    return $self->{resp}->ok;
}

1;
__END__
