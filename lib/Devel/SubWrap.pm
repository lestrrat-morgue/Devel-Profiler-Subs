package Devel::SubWrap;
use strict;
use Carp ();
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(subwrap subunwrap subrewrap wrapped);
our %EXPORT_TAGS = ( all => [ qw(subwrap subunwrap subrewrap wrapped) ] );

our %REGISTRY;

sub subwrap (@) {
    my ($subname, $code) = @_;

    {
        no strict 'refs';
        my $original = \&{$subname};
        no warnings 'redefine';
        *{$subname} = sub { $code->($original, @_) };

        $REGISTRY{ $subname } = {
            original => $original,
            wrapper  => $code,
        };
    }

}

sub wrapped ($) { $REGISTRY{$_[0]} }
sub subrewrap ($) {
    my $subname = shift;

    my $h = wrapped($subname) or
        Carp::croak("$subname was not wrapped, cannot rewrap");
    subwrap $subname, $h->{wrapper};
}

sub subunwrap ($;$) {
    my ($subname, $anihilate) = @_;
    my $h = $anihilate ? delete $REGISTRY{ $subname } : $REGISTRY{ $subname };

    {
        no strict 'refs';
        no warnings 'redefine';
        *{$subname} = $h->{original};
    }
}

1;

__END__

=head1 NAME

Devel::SubWrap - Simple API To Wrap Subroutines

=head1 SYNOPSIS

    use Devel::SubWrap;

    subwrap 'DBI::connect' => sub {
        my ($orig, $class, $dsn, $user, $pass, $attr) = @_
    };

    my ($original) = wrapped 'DBI::connect';

    subunwrap 'DBI::connect';

    subrewrap 'DBI::connect'; # re-enable wrapping

=head1 DESCRIPTION

Devel::SubWrap is a simple wrapper for subroutines:

=over 4

=item Wraps subroutines by fully qualified name

=item Effect is global

=item Can enable/disable the same wrappers

=item Is very thin

=cut