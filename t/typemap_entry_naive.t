#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use Scalar::Util qw(refaddr reftype blessed);

use ok 'KiokuDB::TypeMap::Entry::Naive';
use ok 'KiokuDB::Collapser';
use ok 'KiokuDB::LiveObjects';
use ok 'KiokuDB::Resolver';
use ok 'KiokuDB::Backend::Hash';

{
    package Foo;
    use Moose;

    has foo => ( is => "rw" );
}

my $obj = Foo->new( foo => "HALLO" );

my $n = KiokuDB::TypeMap::Entry::Naive->new();

my $tr = KiokuDB::TypeMap::Resolver->new(
    typemap => KiokuDB::TypeMap->new(
        entries => {
            Foo => $n,
        },
    ),
);

my $v = KiokuDB::Collapser->new(
    resolver => KiokuDB::Resolver->new(
        live_objects => KiokuDB::LiveObjects->new
    ),
    typemap_resolver => $tr,
);

my $l = KiokuDB::Linker->new(
    backend => KiokuDB::Backend::Hash->new,
    live_objects => KiokuDB::LiveObjects->new,
    typemap_resolver => $tr,
);

my ( $entries ) = $v->collapse( objects => [ $obj ],  );
is( scalar(keys %$entries), 1, "one entry" );

my $entry = ( values %$entries )[0];

isnt( refaddr($entry->data), refaddr($obj), "refaddr doesn't equal" );
ok( !blessed($entry->data), "entry data is not blessed" );
is( reftype($entry->data), reftype($obj), "reftype" );
is_deeply( $entry->data, {%$obj}, "is_deeply" );

my $expanded = $l->expand_object($entry);

isa_ok( $expanded, "Foo", "expanded object" );
isnt( refaddr($expanded), refaddr($obj), "refaddr doesn't equal" );
isnt( refaddr($expanded), refaddr($entry->data), "refaddr doesn't entry data refaddr" );
is_deeply( $expanded, $obj, "is_deeply" );
