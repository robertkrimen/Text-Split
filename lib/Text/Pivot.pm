package Text::Pivot;
# ABSTRACT: Partition text around a pivot (like 'split' but with more control and flexibility)

=head1 SYNOPSIS

    my $pivot = Text::Pivot->new( ... )

=cut

use Any::Moose;

has data => qw/ reader data writer _data required 1 /;
has [qw/ start head tail mhead mtail /] => qw/ is rw required 1 isa Int default 0 /;
has _previous => qw/ is ro isa Maybe[Text::Pivot] init_arg previous /;

has found => qw/ is ro required 1 isa Str /, default => '';
has _matched => qw/ init_arg matched is ro isa ArrayRef /, default => sub { [] };
sub matched { return @{ $_[0]->matched } }
has matcher => qw/ is ro required 1 /, default => undef;

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

sub is_root {
    my $self = shift;
    return ! $self->_previous;
}

sub find {
    my $self = shift;
    my $matcher = shift;

    my $data = $self->data;
    my $from = $self->_previous ? $self->tail + 1 : 0;
    my $length = length $$data;

    return if $length <= $from; # Was already at end of data

    pos $data = $from;
    return unless my @match = $$data =~ m/\G[[:ascii:]]*?($matcher)/;

    my ( $mhead, $mtail ) = ( $-[1], $+[1] - 1 );
    my $head = _fhead $data, $mhead;
    my $tail = _ftail $data, $mtail;

    my $found = shift @match;
    my @matched = @match;

    return __PACKAGE__->new(
        data => $data, previous => $self, start => $from, mhead => $mhead, mtail => $mtail, head => $head, tail => $tail,
        matcher => $matcher, found => $found, matched => \@matched,
    );
}

sub preceding {
    my $self = shift;

    my $data = $self->data;
    my $length = $self->head - $self->start;
    return '' unless $length;
    return substr $$data, $self->start, $length;
}
sub pre { return shift->preceding( @_ ) }

sub remaining {
    my $self = shift;

    my $data = $self->data;
    return $$data if $self->is_root;

    my $length = length( $$data ) - $self->tail + 1;
    return '' unless $length;
    return substr $$data, $self->tail + 1, $length;
}
sub re { return shift->remaining( @_ ) }

sub match {
    my $self = shift;
    my $ii = shift;
    return $self->found if $ii == -1;
    return $self->_matched->[$ii];
}

sub is {
    my $self = shift;
    my $ii = shift;
    my $is = shift;

    return unless defined ( my $match = $self->match( $ii ) );
    if ( ref $is eq 'Regexp' )  { $match =~ $is }
    else                        { return $match eq $is }
}

1;
