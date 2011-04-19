package Devel::Profile::Subs::LWP;
use strict;
use parent qw(Devel::Profile::Subs::Profiler);
use LWP::UserAgent;

sub start_profile {
    my ($class, $parent) = @_;

    $parent->enable( 'LWP::UserAgent' => 'request' => sub {
        my($self, $request, $arg, $size, $previous) = @_;
        return sprintf '%s %s', $request->method, $request->uri;
    });

    return $class->new(subs => [ qw(LWP::UserAgent::request) ] );
}

1;

__END__

=head1 HOOKS

=head2 LWP::UserAgent->request

=cut