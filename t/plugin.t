#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More 0.90;
use Test::DZil;
use IPC::Cmd 'can_run';
use Capture::Tiny 'capture_stderr';

plan skip_all => 'msgfmt not found' unless can_run 'msgfmt';

sub tzil {
    Builder->from_config(
        { dist_root => 't/dist' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    # By default, source/dist.ini inherits the parent module's dist.ini.
                    # This hashref can override them, if desired.
                    {
                        # author => "Some Other Author",
                    },
                    # Subsequent arguments define imported plugins:
                    # [GatherDir]
                    'GatherDir',
                    ['LocaleTextDomain', @_],
                ),
            },
        },
    );
}

ok my $tzil = tzil(), 'Create tzil';;

my $stderr = capture_stderr { ok $tzil->build, 'Build it' };

for my $lang (qw(de fr)) {
    like $stderr, qr/^po.$lang[.]po: /m, "STDERR should have $lang.po message";
    ok my $contents = $tzil->slurp_file(
        "build/share/LocaleData/$lang/LC_MESSAGES/DZT-Sample.mo",
    ), "Read in $lang .mo file";
    like $contents, qr/^Language: $lang$/m,
        "Compiled $lang .mo should have language content";
}

# Specify the attributes.
ok $tzil = tzil({
    textdomain       => 'org.imperia.simplecal',
    lang_dir         => 'po',
    share_dir        => 'lib',
    msgfmt           => 'msgfmt',
    lang_file_suffix => 'po',
    bin_file_suffix  => 'bo',
    language         => ['fr']
}), 'Create another tzil';

$stderr = capture_stderr { ok $tzil->build, 'Build again' };
ok -e $tzil->tempdir->file("build/lib/LocaleData/fr/LC_MESSAGES/org.imperia.simplecal.bo"),
    'Should have fr .bo file';
ok !-e $tzil->tempdir->file("build/lib/LocaleData/de/LC_MESSAGES/org.imperia.simplecal.bo"),
    'Should not have de .bo file';
for my $lang (qw(fr)) {
    like $stderr, qr/^po.$lang[.]po: /m, "STDERR should have $lang.bo message";
    ok my $contents = $tzil->slurp_file(
        "build/lib/LocaleData/$lang/LC_MESSAGES/org.imperia.simplecal.bo",
    ), "Read in $lang .bo file";
    like $contents, qr/^Language: $lang$/m,
        "Complied $lang .bo file should have language content";
}

done_testing;
