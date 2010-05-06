package Text::Split;
# ABSTRACT: Text splitting with fine-grained control and introspection

=head1 SYNOPSIS

    my $split = Text::Split->new( ... )

=cut

use Any::Moose;

has data => qw/ reader data writer _data required 1 /;
has [qw/ start head tail mhead mtail /] => qw/ is rw required 1 isa Int default 0 /;
has _parent => qw/ is ro isa Maybe[Text::Split] init_arg parent /;

has found => qw/ is ro required 1 isa Str /, default => '';
has content => qw/ is ro required 1 isa Str /, default => '';
has _matched => qw/ init_arg matched is ro isa ArrayRef /, default => sub { [] };
sub matched { return @{ $_[0]->matched } }
has matcher => qw/ is ro required 1 /, default => undef;

has default => qw/  is ro lazy_build 1 isa HashRef /;
sub _build_default { {
    slurp => '[)',
} }

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

sub parent {
    my $self = shift;
    if ( my $parent = $_[0]->_parent ) { return $parent }
    return $self; # We are the base (root) split
}

sub is_root {
    my $self = shift;
    return ! $self->_parent;
}

sub _chomp_or_chomped ($) {
    my $slurp = $_[0];
    $slurp->{chomp} = delete $slurp->{chomped} if
        exists $slurp->{chomped} && not exists $slurp->{chomp};
}

sub _parse_slurp ($@) {
    my $slurp = shift;
    my %slurp = @_; # Can/will be overidden

    _chomp_or_chomped \%slurp;

    if ( ref $slurp eq 'HASH' ) {
        $slurp = { %$slurp };
        _chomp_or_chomped $slurp;
        %slurp = ( %slurp, %$slurp );
    }
    else {
        $slurp =~
            m{^
                ([\@\$])?
                ([\(\[])
                ([\)\]])
                (/)?
            }x or die "Invalid slurp pattern ($slurp)";

        $slurp{wantlist}    = $1 eq '@' ? 1 : 0 if $1;
        $slurp{slurpl}      = $2 eq '[' ? 1 : 0;
        $slurp{slurpr}      = $3 eq ']' ? 1 : 0;
        $slurp{chomp}       = 1 if $4;
    } 

    return %slurp;
}

sub split {
    my $self = shift;
    my $matcher;
    $matcher = shift if @_ % 2; # Odd number of arguments
    my %given = @_;

    my $data = $self->data;
    my $from = $self->_parent ? $self->tail + 1 : 0;
    my $length = length $$data;

    return if $length <= $from; # Was already at end of data

    pos $data = $from;
    return unless my @match = $$data =~ m/\G[[:ascii:]]*?($matcher)/;

    my ( $mhead, $mtail ) = ( $-[1], $+[1] - 1 );
    my $head = _fhead $data, $mhead;
    my $tail = _ftail $data, $mtail;

    my $found = shift @match;
    my @matched = @match;

    my $content = substr $$data, $head, 1 + $tail - $head;

    my $split =  __PACKAGE__->new(
        data => $data, parent => $self,
        start => $from, mhead => $mhead, mtail => $mtail, head => $head, tail => $tail,
        matcher => $matcher, found => $found, matched => \@matched,
        content => $content,
        default => $self->default,
    );

    return $split unless wantarray && ( my $slurp = $given{slurp} );

    my %slurp = _parse_slurp $self->default->{slurp};
    %slurp = _parse_slurp $slurp, %slurp unless $slurp eq 1;

    my @content;
    push @content, $self->content if $slurp{slurpl};
    push @content, $split->preceding;
    push @content, $split->content if $slurp{slurpr};

    if ( $slurp{wantlist} ) {
        @content = grep { $_ ne "\n" } split m/(\n)/, join '', @content;
        @content = map { "$_\n" } @content unless $slurp{chomp};
    }
    else {
        @content = ( join '', @content );
    }

    return ( $split, @content );
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
