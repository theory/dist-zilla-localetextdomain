package Dist::Zilla::App::Command::msg_init;

# ABSTRACT: Add a language translation file to a dist

use Dist::Zilla::App -command;
use strict;
use warnings;
use Path::Class;
use Dist::Zilla::Plugin::LocaleTextDomain;
use Carp;
use File::Find::Rule;
use namespace::autoclean;

our $VERSION = '0.11';

sub DESTROY {
    my $pot = shift->{potfile} || return;
    $pot->remove;
}

sub command_names { qw(msg-init) }

sub abstract { 'add language translation files to a distribution' }

sub usage_desc { '%c %o <language_code>' }

sub opt_spec {
    [
        'msginit|x=s', 'location of xgttext utility',
        { default => 'msginit' },
    ],
    [
        'xgettext|x=s', 'location of xgttext utility',
        { default => 'xgettext' },
    ],
    [
        'encoding|e=s',  'charcter encoding to be used',
        { default => 'UTF-8' },
    ],
    [
        'pot-file|pot|p=s',  'pot file location',
    ],
    [
        'copyright-holder|c=s',  'name of the copyright holder',
    ],
    [
        'bugs-email|e=s',  'email address for reporting tranlation bugs',
    ],
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    require IPC::Cmd;
    my $xget = $opt->{xgettext};
    $opt->xgettext( IPC::Cmd::can_run($xget) )
        or die qq{Cannot find "$xget": Are the GNU gettext utilities installed?};

    my $msginit = $opt->{msginit};
    $opt->msginit( IPC::Cmd::can_run($msginit) )
        or die qq{Cannot find "$msginit": Are the GNU gettext utilities installed?};

    require Encode;
    my $enc = $opt->{encoding};
    die qq{"$enc" is not a valid encoding\n} if !Encode::find_encoding($enc);

    $self->usage_error('dzil msg-init takes one or more arguments')
        if @$args < 1;

    require Locale::Codes::Language;
    require Locale::Codes::Country;

    for my $name ( @{ $args } ) {
        my ($lang, $country) = split /-_/, $name, 2;
        $self->usage_error("$lang is not a valid language code")
            unless Locale::Codes::Language::code2language($lang);
        if ($country) {
            $self->usage_error("$country is not a valid country code")
            unless Locale::Codes::Country::code2country($country);
        }
    }
}

sub files_to_scan {
    my $self = shift;
    my $dzil = $self->zilla;
    File::Find::Rule->file->name('*.pm')->in('lib');
}

sub pot_file {
    my ( $self, $opt ) = @_;
    my $dzil = $self->zilla;
    my $pot  = $self->{potfile};
    return $pot if $pot;

    $pot = file +File::Spec->tmpdir, $dzil->name . '.pot';

    system(
        $opt->{xgettext},
        '--from-code=' . $opt->{encoding},
        '--add-comments=TRANSLATORS:',
        # '--copyright-holder=' . $opt->{copyright_holder} || $dzil->copyright_holder,
        # '--msgid-bugs-address=' . $opt->{bugs_email} || $dzil->copyright_holder,
        # '--package-name=' . $dzil->name,
        # '--package-version' . $dzil->version,
		'--keyword',
        '--keyword=\'$__\'}',
        '--keyword=__',
        '--keyword=__x',
		'--keyword=__n:1,2',
        '--keyword=__nx:1,2',
        '--keyword=__xn:1,2',
		'--keyword=__p:1c,2',
        '--keyword=__np:1c,2,3',
		'--keyword=__npx:1c,2,3',
        '--keyword=N__',
        '--keyword=N__n:1,2',
		'--keyword=N__p:1c,2',
        '--keyword=N__np:1c,2,3',
        '--keyword=%__',
		'--language=perl',
        $self->files_to_scan,
        '--output=' . $pot,
    ) == 0 or die "Cannot generate $pot\n";

    return $self->{potfile} = $pot;
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $dzil   = $self->zilla;
    my $plugin = $dzil->plugin_named($opt->{plugin_name} || do {
        my @plugins = grep {
            $_->isa("Dist::Zilla::Plugin::LocaleTextDomain")
        } @{ $self->zilla->plugins };
        croak 'LocaleTextDomain plugin not found in dist.ini!' unless @plugins;
        croak 'more than one LocaleTextDomain plugin found, use --plugin-name!'
            if @plugins > 2;
        $plugins[0]->plugin_name;
    });

    my $lang_dir = $plugin->lang_dir;
    my $lang_ext = '.' . $plugin->lang_file_suffix;
    my $pot_file = $self->pot_file($opt);
    my $enc      = $opt->{encoding};

    my @cmd = (
        $opt->{msginit},
        '--input=' . $pot_file,
        '--no-translator',
    );

    for my $lang (@{ $args }) {
        my $dest = $lang_dir->file( $lang . $lang_ext );
        die "$dest already exists\n" if -e $dest;
        system(@cmd, "--locale=$lang.$enc", '--output-file=' . $dest) == 0
            or die "Cannot generate $dest\n";
    }
}

1;
