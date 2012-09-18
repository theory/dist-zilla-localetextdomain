package Dist::Zilla::App::Command::msg_init;

# ABSTRACT: Add a language translation file to a dist

use Dist::Zilla::App -command;
use strict;
use warnings;
use Path::Class;
use Dist::Zilla::Plugin::LocaleTextDomain;
use Carp;
use Moose;
use File::Find::Rule;
use namespace::autoclean;

our $VERSION = '0.11';

with 'Dist::Zilla::Role::PotWriter';

sub command_names { qw(msg-init) }

sub abstract { 'add language translation files to a distribution' }

sub usage_desc { '%c %o <language_code> [<langauge_code> ...]' }

sub opt_spec {
    return (
        [ 'xgettext|x=s'         => 'location of xgttext utility'      ],
        [ 'msginit|x=s'          => 'location of msginit utility'      ],
        [ 'encoding|e=s'         => 'character encoding to be used'    ],
        [ 'pot-file|pot|p=s'     => 'pot file location'                ],
        [ 'copyright-holder|c=s' => 'name of the copyright holder'     ],
        [ 'bugs-email|b=s'       => 'email address for reporting bugs' ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    require IPC::Cmd;
    my $xget = $opt->{xgettext} ||= 'xgettext' . ($^O eq 'MSWin32' ? '.exe' : '');
    die qq{Cannot find "$xget": Are the GNU gettext utilities installed?}
        unless IPC::Cmd::can_run($xget);

    my $init = $opt->{msginit} ||= 'msginit' . ($^O eq 'MSWin32' ? '.exe' : '');
    die qq{Cannot find "$init": Are the GNU gettext utilities installed?}
        unless IPC::Cmd::can_run($init);

    if (my $enc = $opt->{encoding}) {
        require Encode;
        die qq{"$enc" is not a valid encoding\n}
            unless Encode::find_encoding($enc);
    } else {
        $opt->{encoding} = 'UTF-8';
    }

    $self->usage_error('dzil msg-init takes one or more arguments')
        if @{ $args } < 1;

    require Locale::Codes::Language;
    require Locale::Codes::Country;

    for my $lang ( @{ $args } ) {
        my ($name, $enc) = split /[.]/, $lang, 2;
        if ($enc) {
            require Encode;
            die qq{"$enc" is not a valid encoding\n}
                unless Encode::find_encoding($enc);
        }

        my ($lang, $country) = split /[-_]/, $name;
        die qq{"$lang" is not a valid language code\n}
            unless Locale::Codes::Language::code2language($lang);
        if ($country) {
            die qq{"$country" is not a valid country code\n}
                unless Locale::Codes::Country::code2country($country);
        }
    }
}

sub pot_file {
    my ( $self, $opt ) = @_;
    my $dzil = $self->zilla;
    my $pot  = $self->{potfile} ||= $opt->{pot_file};
    if ($pot) {
        die "Cannot initialize language file: Template file $pot does not exist\n"
            unless -e $pot;
        return $pot;
    }

    require File::Temp;
    my $tmp = $self->{tmp} = File::Temp->new(SUFFIX => '.pot', OPEN => 0);
    $pot = file $tmp->filename;
    $self->log('extracting gettext strings');
    $self->write_pot(
        to               => $pot,
        xgettext         => $opt->{xgettext},
        encoding         => $opt->{encoding},
        copyright_holder => $opt->{copyright_holder},
        bugs_email       => $opt->{bugs_email},
    );
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

    my @cmd = (
        $opt->{msginit},
        '--input=' . $pot_file,
        '--no-translator',
    );

    for my $lang (@{ $args }) {
        # Strip off encoding.
        (my $name = $lang) =~ s/[.].+$//;
        my $dest = $lang_dir->file( $name . $lang_ext );
        die "$dest already exists\n" if -e $dest;
        system(@cmd, "--locale=$lang", '--output-file=' . $dest) == 0
            or die "Cannot generate $dest\n";
    }
}

1;
