#!/usr/bin/perl -w
use strict;

use Test::More tests => 4;

BEGIN{ use_ok( "Test::Without::Module", qw( Digest::MD5 )); };

is_deeply( [sort keys %{Test::Without::Module::get_forbidden_list()}],[ qw[ Digest::MD5 ]],"Module list" );
is( ref $INC[0], 'CODE', "Installed hook" );
eval q{ use Digest::MD5 };
like( $@, qr/did not return a true value at/, "Hid module");
