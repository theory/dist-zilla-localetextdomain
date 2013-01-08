#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More 0.90;
use Test::DZil;
use IPC::Cmd 'can_run';
use Path::Class;
use Test::File;
use Test::File::Contents;
use Dist::Zilla::App::Tester;
use App::Cmd::Tester::CaptureExternal;

plan skip_all => 'msgfmt not found' unless can_run 'msgfmt';

require_ok 'Dist::Zilla::App::Command::msg_compile';

my $result = test_dzil('t/dist', [qw(msg-compile)]);
is($result->exit_code, 0, "dzil would have exited 0");
my $i = 0;
for my $lang (qw(de fr)) {
    like $result->log_messages->[$i++], qr/(?:po.$lang[.]po: )?19/m,
        "$lang.po message should have been logged";
    my $mo = file $result->tempdir,
        qw(source LocaleData), $lang, qw(LC_MESSAGES DZT-Sample.mo);
    my $t = $result->tempdir;
    file_exists_ok $mo, "$lang mo file should now exist";
    file_contents_like $mo, qr/^Language: $lang$/m,
        "Compiled $lang .mo should have language content";
}

done_testing;
