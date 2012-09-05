# ABSTRACT: Compile Local::TextDomain language files

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
    subtype 'App', as 'Str', where { !!can_run $_ },  message {
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
    coerce  => 1,
    default => sub { dir 'po' },
);

has share_dir => (
    is      => 'ro',
    isa     => 'Path::Class::Dir',
    coerce  => 1,
    default => sub { dir 'share' },
);

has msgfmt => (
    is      => 'ro',
    isa     => 'App',
    default => sub { 'msgfmt' }
);

has lang_file_suffix => (
    is      => 'ro',
    isa     => 'Str',
    default => 'po',
);

has bin_file_suffix => (
    is      => 'ro',
    isa     => 'Str',
    default => 'mo',
);

sub gather_files {
    my ($self, $arg) = @_;

    require Dist::Zilla::File::InMemory;

    my $lang_dir = $self->lang_dir;
    my $lang_ext = $self->lang_file_suffix;
    my $bin_ext  = $self->bin_file_suffix;
    my $txt_dom  = $self->textdomain;
    my $shr_dir  = $self->share_dir;

    my @cmd = (
        $self->msgfmt,
        '--check',
        '--statistics',
        '--verbose',
        '--output-file' => '-',
    );

    unless (-d $lang_dir) {
        require Carp;
        Carp::croak("Cannot search $lang_dir: no such directory");
    }

    binmode STDOUT, ':raw' or die "Cannot set binmode on STDOUT: $!\n";
    for my $file ( $lang_dir->children ) {
        next if $file->is_dir || $file !~ /[.]$lang_ext\z/;
        (my $lang = $file->basename) =~ s/[.]$lang_ext\z//;
        my $dest = file $shr_dir, 'LocaleData', $lang, 'LC_MESSAGES',
            "$txt_dom.$bin_ext";
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

=head1 Name

Dist::Zilla::Plugin::LocaleTextDomain - Compile Local::TextDomain language files

=head1 Synopsis

In F<dist.ini>

  [ShareDir]
  [@LocaleTextDomain]
  textdomain = My-App
  lang_dir = po
  share_dir = share

=head1 Description

This plugin compiles GNU gettext language files and adds them into the
distribution for use by L<Locale::TextDomain>. This is useful if your
distribution maintains gettext language files in a directory, with each file
named for a language.

=head2 Attributes

=head3 C<textdomain>

The textdomain to use for your language files, as defined by the
L<Locale::TextDomain> documentation. Defaults to the name of your
distribution.

=head3 C<lang_dir>

The directory containing your language files. Defaults to F<po>.

=head3 C<share_dir>

The name of the distribution directory into which compiled language files
should be added. Defaults to C<share>.

=head3 C<msgfmt>

The location of the C<msgfmt> program, which is distributed with
L<GNU gettext|http://www.gnu.org/software/gettext/>.

=head3 C<lang_file_suffix>

Suffix used in the language file names. These are the files your translators
maintain in your repository. Defaults to C<po>.

=head3 C<bin_file_suffix>

Suffix to use for the compiled language file. Defaults to C<mo>.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

This software is copyright (c) 2012 by David E. Wheeler.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
