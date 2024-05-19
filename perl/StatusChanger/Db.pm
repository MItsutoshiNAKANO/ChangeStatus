package StatusChanger::Db;
use v5.32.1;
use strict;
use warnings;
use utf8;
use DBI;

=encoding utf8

=head1 NAME

StatusChanger::Db - Database wrapper.

=head1 SYNOPSIS

    use StatusChanger::Db;
    my $db = StatusChanger::Db->connect(
        $data_source, $user, $password, \%attrs
    );
    $sth = $db->prepare($sql, \%attrs);
    $rv = $db->do($sql, \%attrs, @binds);
    $rc = $db->commit;
    $rc = $db->rollback;
    $rv = $db->err;
    $rv = $db->state;
    $rv = $db->errstr;
    $db->setattr($attr, $value);
    $rc = $db->disconnect;

=head1 DESCRIPTION

This class is a database wrapper.

=head1 CONSTRUCTOR

=head2 $db = StatusChanger::DbWrapper->new(\%props);

Create a new instance.

=cut

sub new($;$) {
    my $class = shift;
    my $props = shift;
    my $self = {};
    bless $self, $class;
    if (defined $props) {
        foreach my $key (keys %$props) { $self->{$key} = $props->{$key} }
    }
    return $self;
}

=head2 $rc = $db->connect($source, $user, $auth, \%attr); # Connect to a database.

=cut

sub connect($$$$\%) {
    my $self = shift;
    my $source = shift;
    my $user = shift;
    my $auth = shift;
    my $attr = shift;
    my @params = @_;
    my $log = $self->log;
    $log->trace(join(' ', __LINE__, __PACKAGE__ . '->connect():', @params));
    $self->{dbh} = DBI->connect(@params);
    unless ($self->{dbh}) { return undef }
    $log->trace(join(' ', __LINE__, __PACKAGE__ . '->connect(): connected'));
    $self->{dbh}->{AutoCommit} = 0;
    $self->{dbh}->{RaiseError} = 1;
    return $self;
}

=head1 PROPERTIES

=head2 $log = $db->log($a_log); # Log.

=cut

sub log($;$) {
    my $self = shift;
    my $log = shift;
    $self->{log} = $log if defined $log;
    return $self->{log};
}

=head1 METHODS


=head2 $rv = $db->do($sql, \%attrs, @binds); # Execute a statement.

=cut

sub do($@) {
    my $self = shift;
    return $self->{dbh}->do(@_);
}

=head2 sub $rv = $db->err; # Return the database error.

=cut

sub err($) {
    my $self = shift;
    return $self->{dbh}->err;
}

=head2 sub $rv = $db->state; # Return the database state.

=cut

sub state($) {
    my $self = shift;
    return $self->{dbh}->state;
}

=head2 sub $rv = $db->errstr; # Return the database error string.

=cut

sub errstr {
    my $self = shift;
    return $self->{dbh}->errstr;
}

=head2 $rc = $db->commit; # Commit a transaction.

=cut

sub commit($) {
    my $self = shift;
    return $self->{dbh}->commit;
}

=head2 $rc = $db->rollback; # Rollback a transaction.

=cut

sub rollback($) {
    my $self = shift;
    return $self->{dbh}->rollback;
}

=head2 $rc = $db->disconnect; # Disconnect from a database.

=cut

sub disconnect($) {
    my $self = shift;
    return $self->{dbh}->disconnect;
}

1;
__END__
