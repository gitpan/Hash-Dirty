#!perl -T

use Test::More qw/no_plan/;
use Test::Deep;

use Hash::Dirty;

my %hash;
tie %hash, qw/Hash::Dirty/, { a => 1 };

ok(!(tied %hash)->is_dirty); # Nope, not dirty yet.

$hash{a} = 1;
ok(!(tied %hash)->is_dirty); # Still not dirty yet.

$hash{b} = 2;
ok((tied %hash)->is_dirty); # Yes, now it's dirty

cmp_bag([(tied %hash)->dirty_keys], [qw/b/]); # ( b )

$hash{a} = "hello";
cmp_bag([(tied %hash)->dirty_keys], [qw/a b/]); # ( a, b )

cmp_bag([(tied %hash)->dirty_values], [qw/hello 2/]); # ( "hello", 2 )

cmp_deeply({ (tied %hash)->dirty }, { a => 1, b => 1 });

(tied %hash)->reset;
ok(!(tied %hash)->is_dirty); # Nope, not dirty anymore.

$hash{c} = 3;

ok((tied %hash)->is_dirty); # Yes, now it's dirty
cmp_deeply({ (tied %hash)->dirty_slice }, { c => 3 });

my $hash = Hash::Dirty->new;

