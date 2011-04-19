use strict;
use Test::More;
use Test::Requires 'DBD::SQLite';

use Devel::Profile::Subs;

subtest 'lwp profile' => sub {
    {
        my $buf;
        open my $output, '>', \$buf;
        my $guard = Devel::Profile::Subs->profile( 'LWP' );
        $guard->output( $output );
        $guard->colors( {} );

        my $lwp = LWP::UserAgent->new();
        $lwp->request(HTTP::Request->new(GET => "http://www.livedoor.com"));
        like $buf, qr{\[LWP::UserAgent\]\s+GET http://www\.livedoor\.com};
    }
};

done_testing;