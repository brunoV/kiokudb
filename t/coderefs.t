#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

use ok 'KiokuDB';
use ok 'KiokuDB::Backend::Hash';

my $dir = KiokuDB->new(
    backend => KiokuDB::Backend::Hash->new,
);

{
    package WithCodeRef;
    use KiokuDB::Class;

    has coderef => (
        is      => 'rw',
        isa     => 'CodeRef',
        default => sub { sub { return 'ok' } },
    );

}

TODO: {
    local $TODO =  "CodeRef storage";
    todo_skip $TODO, 3; # Otherwise it dies

    my $id;

    {
        my $obj = WithCodeRef->new;
        my $s   = $dir->new_scope;

        lives_ok { $id = $dir->store($obj) };
    }

    {
        my $s   = $dir->new_scope;
        $id and my $obj = $dir->lookup($id);

        isa_ok $obj,              'WithCodeRef';
        is     $obj->coderef->(), 'ok';
    }
}

TODO: {
    local $TODO = "CodeRef with shared variables";
    todo_skip $TODO, 2; # Otherwise it dies

    sub generate_counter {
        my $i = shift;
        return sub {
            return ++$i;
        }
    }

    my $counter = generate_counter(0);
    my @objs = map { WithCodeRef->new(coderef => $counter) } (1..2);

    # kick the counter once with first object.
    $objs[0]->coderef->();

    my $id;

    {
        my $s = $dir->new_scope;
        lives_ok { $id = $dir->store($objs[1]) };
    }

    {
        my $s = $dir->new_scope;
        $id and my $obj2 = $dir->lookup($id);

        is $obj2->coderef->(), 2;
    }

}
