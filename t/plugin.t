#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;
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
                    # [Credits]
                    # filename = thanks.txt
                    # thank = E. X. Ample
                    # thank = The Academy
                    @_,
                ),
            },
        },
    );
}

my $tzil = tzil 'LocaleTextDomain';

my $stderr = capture_stderr { ok $tzil->build, 'Build it' };

for my $lang (qw(de fr)) {
    like $stderr, qr/^po.$lang[.]po: /m, "STDERR should have $lang.po message";
    ok my $contents = $tzil->slurp_file(
        "build/lib/LocaleData/$lang/LC_MESSAGES/DZT-Sample.mo",
    ), "Read in $lang.po";
    like $contents, qr/^Language: $lang$/m, "$lang.po should have language content";
}

done_testing;
