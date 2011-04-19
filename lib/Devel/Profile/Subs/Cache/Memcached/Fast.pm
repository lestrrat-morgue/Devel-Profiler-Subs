
sub start_profile {
    my ($self, $parent) = @_;

    my @subs;
    for my $method (qw/add append set get gets delete prepend replace cas incr d
ecr/) {
        $parent->enable( 'Cache::Memcached::Fast', $method, sub {
            my ($self, $key) = @_;
            return sprintf '%s %s', $method, $key;
        } );

        my $multi_method = sprintf '%s_multi', $method;
        $parent->enable( 'Cache::Memcached::Fast', $multi_method, sub {
            my ($self, @args) = @_;
            if (ref $args[0] eq 'ARRAY') {
                return sprintf '%s %s', 
                    $method_multi,
                    join( ', ', map { $_->[0] } @args)
                ;
            } else {
                return sprintf '%s %s',
                    $method_multi, 
                    join( ', ', map {
                        ref( $_) eq 'ARRAY' ? join(', ',@$_) : $_
                    } @args)
                ;
            }
        } );
        push @subs, map { "Caache::Memcached::Fast::$_" } ($method, $method_multi);
    }

    $parent->enable( 'Cache::Memcached::Fast' => 'remove', sub {
        my ($self, $key) = @_;
        return sprintf 'remove %s', $key;
    } );

    return $class->new( subs => [
        'Cache::Memcached::Fast::remove', @subs
    ] );
};

1;
