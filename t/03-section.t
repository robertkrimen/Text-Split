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

my $pattern = qr/^#[^\S\n]*---[^\S\n]*(\S+)?/m;

$t0 = $t0->find( $pattern );
is( $t0->match( 0 ), 'IGNORE' );
cmp_deeply( [ $t0->slurp( '@[)', chomp => 1 ) ], [ '', qw/ M1 M2 M3 /, '' ] );

$t0 = $t0->find( $pattern );
is( $t0->match( 0 ), 'SKIP' );
is( $t0->slurp( '()' ), <<_END_ );

I1
I2
I3

_END_

$t0 = $t0->find( $pattern );
is( $t0->match( 0 ), undef );
is( $t0->slurp(), <<_END_ );
# --- SKIP efgh

S1
S2
S3

ijkl

_END_

is( $t0->remaining, <<_END_ );

_END_

#my ( $section, @m0, @i0 );
#$section = \@m0;
#while( $t0 = $t0->find( qr/^#\s*---\s*(\S+)?/m ) ) {
#    diag '<', $t0->content, '>';
#    if ( $t0->is( 0 => 'IGNORE' ) ) {
#        push @$section, $t0->slurp( '@[)', chomp => 1 );
#        $section = \@i0;
#    }
#    elsif ( $t0->is( 0 => 'SKIP' ) ) {
#        push @$section, $t0->slurp( '()' );
#    }
#}

#diag scalar @m0;
#diag scalar @i0;
#diag "[", join( '/', @m0 ), "]";
#diag "[@i0]";
