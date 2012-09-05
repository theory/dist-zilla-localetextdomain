#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

require_ok 'Dist::Zilla::Plugin::LocaleTextDomain';
is_deeply [Dist::Zilla::Plugin::LocaleTextDomain->mvp_multivalue_args],
    [qw(language)], 'Should have mvp_multivalue_args';

