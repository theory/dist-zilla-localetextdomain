package Dist::Zilla::App::Command::pot;

# ABSTRACT: Add a language translation file to a dist

use Dist::Zilla::App -command;
use strict;
use warnings;
use Carp;
use namespace::autoclean;

our $VERSION = '0.11';

sub command_names { qw(pot) }

sub abstract { 'add a language translation template to a distribution' }

sub usage_desc { '%c %o' }

sub opt_spec {
    return (
        [ 'xgettext|x=s'         => 'location of xgttext utility'      ],
        [ 'encoding|e=s'         => 'charcter encoding to be used'     ],
        [ 'pot-file|pot|p=s'     => 'pot file location'                ],
        [ 'copyright-holder|c=s' => 'name of the copyright holder'     ],
        [ 'bugs-email|b=s'       => 'email address for reporting bugs' ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    require IPC::Cmd;
    my $xget = $opt->{xgettext} ||= 'xgettext';
    die qq{Cannot find "$xget": Are the GNU gettext utilities installed?}
        unless IPC::Cmd::can_run($xget);

    if (my $enc = $opt->{encoding}) {
        require Encode;
        die qq{"$enc" is not a valid encoding\n}
            unless Encode::find_encoding($enc);
    } else {
        $opt->{encoding} = 'UTF-8';
    }
}

sub files_to_scan {
    my $self = shift;
    return @{ $self->{files} || do {
        my $dzil = $self->zilla;
        $dzil->chrome->logger->mute;
        $_->gather_files for @{ $dzil->plugins_with(-FileGatherer) };
        $dzil->chrome->logger->unmute;
        # XXX Consider replacing with a LocaleTextDomain-specific file finder?
        [ grep { /[.]pm\z/ } map { $_->name } @{ $dzil->files } ];
    } };
}

sub plugin {
    my $self = shift;
    $self->{plugin} ||= $self->zilla->plugin_named('LocaleTextDomain')
        or croak 'LocaleTextDomain plugin not found in dist.ini!';
}

sub execute {
    my ( $self, $opt ) = @_;

    require Path::Class;
    my $dzil     = $self->zilla;
    my $pot_file = Path::Class::file($opt->{pot_file} || (
        $self->plugin->lang_dir, $self->zilla->name . '.pot'
    ));

    # Make sure the directory exists.
    unless (-d $pot_file->parent) {
        create_path $pot_file->parent->stringify;
    }

    my $verb = -e $pot_file ? 'update' : 'create';
    $self->log("extracting gettext strings into $pot_file");

    # Need to do this before calling other methods, as they need the
    # files loaded to find various information.
    my @files = $self->files_to_scan;

    my $email = $opt->{bugs_email} || do {
        if (my $author = $dzil->authors->[0]) {
            require Email::Address;
            my ($addr) = Email::Address->parse($author);
            $addr->address if $addr;
        }
    } || '';

    system(
        $opt->{xgettext},
        '--from-code=' . $opt->{encoding},
        '--add-comments=TRANSLATORS:',
        '--package-name=' . $dzil->name,
        '--package-version=' . $dzil->version || 'VERSION',
        '--copyright-holder=' . ($opt->{copyright_holder} || $dzil->copyright_holder),
        ($email ? '--msgid-bugs-address=' . $email : ()),
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
        '--output=' . $pot_file,
        @files,
    ) == 0 or die "Cannot $verb $pot_file\n";
}

1;
