#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
plan 'no_plan';

use Text::Pivot;

my ( $t0, $p0, $p1, $p2 );

sub o0 ($) {
    my $p0 = $_[0];
    diag $p0->start, " ", $p0->head, " ", $p0->tail, " m ", $p0->mhead, " ", $p0->mtail;
}

sub opr ($) {
    my $p0 = $_[0];
    diag 'pr: [', $p0->preceding, ']';
}

sub ore ($) {
    my $p0 = $_[0];
    diag 're: [', $p0->remaining, ']';
}

$p0 = Text::Pivot->new( data => <<_END_ );

{
    abcdefghijklmnopqrstuvwxyz

qwerty
-
1 2 3 4 5 5 6 7 8 9     

    xyzzy

}

_END_

diag $p0->remaining;

$p1 = $p0->find( qr/rty/ );

o0 $p1;
opr $p1;
ore $p1;

$p2 = $p1->find( qr/ 5 6 7 / );

o0 $p2;
opr $p2;
ore $p2;

#$s0->skip_until( qr/rty/ );
#is( $s0->read_until( qr/5 6/ ), <<_END_ );
#qwerty

#1 2 3 4 5 5 6 7 8 9     
#_END_
