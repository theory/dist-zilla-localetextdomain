package Dist::Zilla::Plugin::LocaleTextDomain;
use strict;
use warnings;
use Moose;
use Path::Class;
use Capture::Tiny;
use IPC::Cmd qw(can_run);
use MooseX::Types::Path::Class;
use Moose::Util::TypeConstraints;

with 'Dist::Zilla::Role::FileGatherer';

our $VERSION = 0.001;

use IPC::Cmd qw(can_run);
BEGIN {
    subtype 'App', as 'Str', where {
        if (my $path = can_run $_) {
            $_ = $path;
            return 1;
        }
        return 0;
    }, message {
        qq{Cannot find "$_": Are the Unix gettext utilities installed?};
    };
}

has lang_dir => (
    is      => 'ro',
    isa     => 'Path::Class::Dir',
    default => sub { dir 'po' },
);

has msgfmt => (
    is      => 'ro',
    isa     => 'App',
    default => sub { 'msgfmt' }
);

has lang_file_suffix => (
    is      => 'ro',
    isa     => 'Str',
    default => 'mo',
);

has bin_file_suffix => (
    is      => 'ro',
    isa     => 'Str',
    default => 'po',
);

sub gather_files {
    my ($self, $arg) = @_;
    require Dist::Zilla::File::InMemory;

    my $dir = $self->lang_dir;
    my $mo  = $self->lang_file_suffix;
    my $po  = $self->bin_lang_stuffix;
    my @cmd = (
        $self->msgfmt,
        '--check',
        '--statistics',
        '--verbose',
        '--output-file' => '-',
    );

    for my $file ( $dir->lang_dir->children ) {
        next if $file->is_dir || $file !~ /[.]$mo\z/;
        (my $lang = $file->basename) =~ s/[.]$mo\z//;
        my $dest = file 'lib', 'LocaleData', $lang, 'LC_MESSAGES', "$lang.$po";
        $self->add_file(
            Dist::Zilla::File::InMemory->new({
                name    => $dest,
                content => capture_stdout {
                    system(@cmd, $file) == 0 or do {
                        require Carp;
                        Carp::confess("Cannot compile $file");
                    };
                }
            })
        );
    }
}

1;
