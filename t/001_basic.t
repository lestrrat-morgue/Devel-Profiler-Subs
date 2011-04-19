use strict;
use Test::More;
BEGIN {
    use_ok "Devel::SubWrap", ':all';
}

my @expected;
sub Random::Package::For::Testing::foo {
    is_deeply( \@_, \@expected );
}

subtest 'basic wrap/unwrap' => sub {
    my $called = 0;
    subwrap 'Random::Package::For::Testing::foo' => sub {
        my ($orig, @args) = @_;
        $called++;
        $orig->(@args, "baz");
    };

    @expected = qw(foo bar baz);
    Random::Package::For::Testing::foo( qw(foo bar) );
    is $called, 1;

    subunwrap 'Random::Package::For::Testing::foo';

    @expected = qw(foo bar);
    Random::Package::For::Testing::foo( qw(foo bar) );
    is $called, 1;

    subrewrap 'Random::Package::For::Testing::foo';

    @expected = qw(foo bar baz);
    Random::Package::For::Testing::foo( qw(foo bar) );
    is $called, 2;
};


done_testing;