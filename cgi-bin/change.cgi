#! /usr/bin/env perl

use v5.32.1;
use strict;
use warnings;
use utf8;
use Mojo::Log;
use lib '../perl';
use StatusChanger;


$ENV{PGDATABASE} ||= 'vagrant';
$ENV{PGPASSWORD} ||= 'vagrant';

my $log = Mojo::Log->new(path => '../logs/change.log', level => 'debug')
or die 'Could not create log file';
my $changer = StatusChanger->new;
$changer->prepare({ log => $log }) and $changer->change;

__END__

=encoding utf8

=head1 NAME

change.cgi - CGI to change a ticket status

=head1 SYNOPSIS

    $ ./change.cgi

=head1 DESCRIPTION

This is CGI to change a ticket status.
