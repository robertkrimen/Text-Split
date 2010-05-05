package Text::Partition;
# ABSTRACT: Partition text like the split builtin, but with more control and flexibility

use strict;
use warnings;

use Any::Moose;

use Scalar::Util qw/ looks_like_number /;

has data => qw/ is ro required 1 isa Str /;
has base => qw/ is ro lazy_build 1 isa Text::Partition::Pivot /;
sub _build_base {
    my $self = shift;
    return Text::Partition::Pivot->new( data => \$self->data, qw/ start 0 head 0 tail 0 mhead 0 mtail 0 /);
}

sub find {
    my $self = shift;
    my $target = shift;

    return $self->base->find( $target );

}

package Text::Partition::Pivot;

use Any::Moose;

has data => qw/ reader data writer _data required 1 /;
has [qw/ start head tail mhead mtail /] => qw/ is rw required 1 isa Int default 0 /;
has _previous => qw/ is ro isa Maybe[Text::Partition::Pivot] init_arg previous /;

sub BUILD {
    my $self = shift;
    my $data = $self->data;
    $self->_data( \$data ) unless ref $data eq 'SCALAR';
}

sub _fhead ($$) {
    my ( $data, $from ) = @_;
    my $i0 = rindex $$data, "\n", $from;
    return $i0 + 1 unless -1 == $i0;
    return 0;
}

sub _ftail ($$) {
    my ( $data, $from ) = @_;
    my $i0 = index $$data, "\n", $from;
    return $i0 unless -1 == $i0;
    return -1 + length $$data;
}

sub previous {
    my $self = shift;
    if ( my $previous = $_[0]->_previous ) { return $previous }
    return $self; # We are the base (root) pivot
}

sub find {
    my $self = shift;
    my $target = shift;

    my $data = $self->data;
    my $from = $self->_previous ? $self->tail + 1 : 0;
    my $length = length $$data;

    return if $length <= $from; # Was already at end of data

    pos $data = $from;
    return unless my @match = $$data =~ m/\G[[:ascii:]]*?($target)/;

    my ( $mhead, $mtail ) = ( $-[1], $+[1] - 1 );
    my $head = _fhead $data, $mhead;
    my $tail = _ftail $data, $mtail;

warn $from;
    return __PACKAGE__->new( data => $data, previous => $self, start => $from, mhead => $mhead, mtail => $mtail, head => $head, tail => $tail );
    
#    $self->cursor( $-[1], $+[1] - 1 );
#    return 1;

}

sub preceding {
    my $self = shift;

    my $data = $self->data;
    my $length = $self->head - $self->start;
    return unless $length;
    return substr $$data, $self->start, $length;
}

sub remaining {
    my $self = shift;

    my $data = $self->data;
    my $length = length( $$data ) - $self->tail + 1;
    return unless $length;
    return substr $$data, $self->tail + 1, $length;
}


1;
