use strict;
use Test::More;
use Test::Requires 'DBD::SQLite';
use Devel::Profile::Subs;

subtest 'dbi profile' => sub {
    my $buf;
    open my $output, '>', \$buf;
    my $guard = Devel::Profile::Subs->profile( 'DBI' );
    $guard->output( $output );

    my $dbh = DBI->connect( 'dbi:SQLite:' );
    my $sth = $dbh->prepare("SELECT 1");
    $sth->execute();

    $buf =~ s/\e\[(?:\d+;)*\d*m//g;
    like $buf, qr/\[DBI\]\s+connect\s+dbi:SQLite:/;
    like $buf, qr/\[DBI::st\]\s+SELECT 1\s+\(0 rows\)/;

    $buf = '';
    seek( $output, 0, 0 );

    $guard->mute( "DBI" => "connect" );
    $dbh = DBI->connect('dbi:SQLite:' );
    $sth = $dbh->prepare("SELECT 1");
    $sth->execute();

    $buf =~ s/\e\[(?:\d+;)*\d*m//g;
    unlike $buf, qr/\[DBI\]\s+connect\s+dbi:SQLite:/;
    like $buf, qr/\[DBI::st\]\s+SELECT 1\s+\(0 rows\)/;
};

done_testing;