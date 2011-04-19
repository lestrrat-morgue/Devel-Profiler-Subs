package Devel::Profile::Subs;
use strict;
use Class::Load ();
use Devel::SubWrap;
use Scalar::Util ();
use Term::ANSIColor ();
use Time::HiRes ();
use Class::Accessor::Lite
    rw  => [ qw(
        colors
        output
        profilers
    ) ]
;

my $_INSTANCE;

sub new {
    my ($class, @args) = @_;

    my $self = bless {
        colors => {
            time   => 'red',
            module => 'cyan',
            info   => 'blue',
            caller => 'green',
        },
        @args
    }, $class;
    return $self;
}

sub mute {
    my ($self, $pkg, @methods) = @_;
    foreach my $method ( @methods ) {
        my $subname = "$pkg:\:$method";
        Devel::SubWrap::subunwrap($subname);
    }
}

sub DESTROY {
    my $self = shift;
    foreach my $profiler ( @{ $self->profilers || [] } ) {
        foreach my $sub ( @{ $profiler->subs || [] } ) {
            Devel::SubWrap::subunwrap($sub);
        }
    }
}

sub global {
    my ($class, @profilers) = @_;

    $_INSTANCE ||= $class->new( profilers => [] );
    if (@profilers) {
        $_INSTANCE->add_profilers(@profilers);
    }
    return $_INSTANCE;
}

sub add_profiler {
    my ($self, $klass, @args) = @_;

    if ($klass !~ s/^\+//) {
        $klass = sprintf '%s::%s', ref $self, $klass;
    }

    if (! Class::Load::is_class_loaded($klass) ) {
        Class::Load::load_class($klass);
    }

    push @{ $self->{profilers} }, $klass->start_profile($self, @args);
    return $self;
}

sub add_profilers {
    my ($self, @profilers) = @_;
    foreach my $profilers (@profilers) {
        my ($klass, @args);
        if (ref $profilers eq 'ARRAY') {
            ($klass, @args) = @$profilers;
        } else {
            $klass = $profilers;
        }
        $self->add_profiler( $klass, @args );
    }
    return $self;
}


sub profile {
    my ($class, @profilers) = @_;
    my $self = $class->new( profilers => [] );
    $self->add_profilers(@profilers);
    return $self;
}

sub enable {
    my ($self, $pkg, $subname, $info) = @_;

    my $weak_self = $self;
    Scalar::Util::weaken $weak_self;
    Devel::SubWrap::subwrap( sprintf('%s::%s', $pkg, $subname), sub {
        my ($orig, @args) = @_;

        my $wantarray = wantarray;
        my (@res, $res);
        my $start_t = [ Time::HiRes::gettimeofday ];
        if ($wantarray) {
            @res = $orig->(@args);
        } elsif (defined $wantarray) {
            $res = $orig->(@args);
        } else {
            $orig->(@args);
        }
        my $ns = Time::HiRes::tv_interval($start_t) * 1000;


        my ($package, $line) = @_;
        for my $i (1..30) {
            my ($p, $f, $l) = caller($i) or next;
            if ($p !~ /^(?:$pkg)\b/) {
                ($package, $line) = ($p, $l);
                last;
            }
        }
        if (! $package) {
            ($package, undef, $line) = caller;
        }

        if (! $weak_self) {
            Carp::confess("Devel::Profile::Subs instance has already gone out of scope");
        }
        $weak_self->_output( 
            $ns,
            (ref $args[0] || $args[0] || ''),
            $info->(@args),
            $package,
            $line
        );

        return $wantarray ? @res :
            defined $wantarray ? $res : ();
    } );
}

sub _output {
    my $self = shift;

    my $output = $self->{output};
    if (ref $output eq 'CODE') {
        $output->( @_ );
    } else {
        $output ||= \*STDERR;

        my @pieces = (
            time   => sprintf( "% 9.3f ms ", $_[0] ),
            module => sprintf( " [%s] ", $_[1] ),
            info   => sprintf( " %s ", $_[2] ),
            NONE   => ' | ',
            caller => sprintf( "%s:%d", $_[3], $_[4] )
        );

        my $message = '';
        my $colors = $self->colors;
        while ( my ($key, $str) = splice @pieces, 0, 2 ) {
            $message .= $colors->{$key} ?
                Term::ANSIColor::colored( $str, $colors->{$key} ) :
                $str
            ;
        }
        print $output $message, "\n";
    }
}

1;

__END__

=head1 NAME

Devel::Profile::Subs - Dead Simple Profiler For Sets Of Subroutines

=head1 SYNOPSIS

    # Globally enable 
    use Devel::Profiler::Subs
        ( 'DBI', 'Cache::Memcached::Fast' );

    # Act upon global instance
    Devel::Profiler::Subs
        ->global()
        ->mute( 'DBI::st', 'execute' );

    # Enable profiler in this scope only
    {
        my $guard = Devel::Profile::Subs->profile( 'LWP' );
        my $ua = LWP::UserAgent->new;
        $ua->get( '...' ); # profiled

    }
    # not profiled
    my $ua = LWP::UserAgent->new;
    $ua->get( '...' ); # not profiled

=head1 DESCRIPTION

Devel::Profile::Subs was inspired by a tool called Devel::KYTProf, which
has never been released to CPAN as of this writing.

=over 

=item Subroutine wrapping is done via Devel::SubWrap

This module is currently bundled together, but will be removed later.

=cut
