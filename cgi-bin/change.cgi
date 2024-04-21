#! /usr/bin/env perl

use v5.32.1;
use strict;
use warnings;
use utf8;
use lib '../perl';
use StatusChanger;

$ENV{PGDATABASE} ||= 'vagrant';
$ENV{PGPASSWORD} ||= 'vagrant';
StatusChanger->new()->change();

__END__

=encoding utf8

=head1 NAME

change.cgi - CGI to change a ticket status

=head1 SYNOPSIS

    $ ./change.cgi

=head1 DESCRIPTION

This is CGI to change a ticket status.
