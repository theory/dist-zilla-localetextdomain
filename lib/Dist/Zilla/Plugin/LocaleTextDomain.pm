package Dist::Zilla::Plugin::LocaleTextDomain;
use strict;
use warnings;
use Moose;
use Path::Class;
use Capture::Tiny qw(capture_stdout);
use IPC::Cmd qw(can_run);
use MooseX::Types::Path::Class;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

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

has textdomain => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { shift->zilla->name },
);

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
    my $po  = $self->bin_file_suffix;
    my $dom = $self->textdomain;
    my @cmd = (
        $self->msgfmt,
        '--check',
        '--statistics',
        '--verbose',
        '--output-file' => '-',
    );

    unless (-d $dir) {
        require Carp;
        Carp::croak("Cannot search $dir: no such directory");
    }

    for my $file ( $dir->children ) {
        next if $file->is_dir || $file !~ /[.]$po\z/;
        (my $lang = $file->basename) =~ s/[.]$po\z//;
        my $dest = file 'lib', 'LocaleData', $lang, 'LC_MESSAGES', "$dom.$mo";
        $self->add_file(
            Dist::Zilla::File::InMemory->new({
                name    => $dest->stringify,
                content => capture_stdout {
                    system(@cmd, $file) == 0 or do {
                        require Carp;
                        Carp::confess("Cannot compile $file");
                    };
                } || '',
            })
        );
    }
}

__PACKAGE__->meta->make_immutable;
1;

__END__
