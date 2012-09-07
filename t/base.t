#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

require_ok 'Dist::Zilla::Plugin::LocaleTextDomain';
is_deeply [Dist::Zilla::Plugin::LocaleTextDomain->mvp_multivalue_args],
    [qw(language)], 'Should have mvp_multivalue_args';

require_ok 'Dist::Zilla::App::Command::add_lang';
isa_ok 'Dist::Zilla::App::Command::add_lang', 'App::Cmd::Command';
can_ok 'Dist::Zilla::App::Command::add_lang' => qw(
    command_names
    abstract
    usage_desc
    opt_spec
    validate_args
    execute
);
