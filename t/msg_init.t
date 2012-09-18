#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More 0.90;
use Test::DZil;
use IPC::Cmd 'can_run';

plan skip_all => 'msginit not found' unless can_run 'msginit';

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

done_testing;


