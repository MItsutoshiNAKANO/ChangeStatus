#! /usr/bin/env perl

use v5.32.1;
use strict;
use warnings;
use utf8;

say "Content-type: text/plain; charset=UTF-8\n";
foreach my $key (keys %ENV) { say join('', $key, '=', $ENV{$key}) }
say '@INC=', "@INC";
