#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
plan 'no_plan';

use Text::Split;

my ( $t0, $content, $data );

$data = <<_END_;

M1
M2
M3

# --- IGNORE abcd

I1
I2
I3

# --- SKIP efgh

S1
S2
S3

ijkl

# --- 

_END_

$t0 = Text::Split->new( data => $data );

my ( $section, @m0, @i0 );
$section = \@m0;
while( $t0 = $t0->find( qr/^#\s*---\s*(\S+)?/m ) ) {
    diag '<', $t0->content, '>';
    if ( $t0->is( 0 => 'IGNORE' ) ) {
        push @$section, $t0->slurp( '[)' );
        $section = \@i0;
    }
    elsif ( $t0->is( 0 => 'SKIP' ) ) {
        push @$section, $t0->slurp( '()' );
    }
}

diag scalar @m0;
diag scalar @i0;
#diag "[@m0]";
#diag "[@i0]";
