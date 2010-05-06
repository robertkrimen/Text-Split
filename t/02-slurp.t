#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
plan 'no_plan';

use Text::Split;

my ( $t0, $content );

my $data = <<_END_;

{
    abcdefghijklmnopqrstuvwxyz

  qwerty
-
1 2 3 4 5 5 6 7 8 9     

    xyzzy

}

_END_

$t0 = Text::Split->new( data => $data );

( $t0, $content ) = $t0->split( qr/rty/, slurp => '[]' );

is( $content, <<_END_ );

{
    abcdefghijklmnopqrstuvwxyz

  qwerty
_END_
