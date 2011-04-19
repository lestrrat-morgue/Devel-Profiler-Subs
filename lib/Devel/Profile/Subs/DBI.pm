package Devel::Profile::Subs::DBI;
use strict;
use parent qw(Devel::Profile::Subs::Profiler);
use DBI;
use Devel::SubWrap;

sub start_profile {
    my ($class, $parent) = @_;

    $parent->enable( DBI => 'connect' => sub {
        my ($klass, $dsn, $user, $pass, $attr) = @_;
        return sprintf '%s %s',
            ($attr || {})->{dbi_connect_method} || 'connect',
            $dsn
        ;
    });
    $parent->enable( 'DBI::st' => 'execute' => sub {
        my ($sth, @binds) = @_;
        my $sql = $sth->{Database}->{Statement};
        my $bind_info = scalar(@binds) ?
            '(bind: '.join(', ',@binds).')' : '';
        return sprintf '%s %s (%d rows)', $sql, $bind_info, $sth->rows;
    } );

    return $class->new( subs => [ 'DBI::st::execute', 'DBI::connect' ] );
}

1;

__END__

=head1 HOOKS

=head2 DBI->connect

=head2 DBI::st->execute