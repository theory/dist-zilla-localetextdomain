package Dist::Zilla::Role::MsgCompile;

# ABSTRACT: Something that compiles gettext language translation files

use Moose::Role;
use strict;
use warnings;
use Path::Class;
use IPC::Run3;
use File::Path 2.07 qw(make_path remove_tree);
use namespace::autoclean;

with 'Dist::Zilla::Role::PotWriter';
requires 'zilla';

has _tmp_dir => (
    is      => 'ro',
    isa     => 'Path::Class::Dir',
    default => sub {
        require File::Temp;
        dir File::Temp::tempdir(CLEANUP => 1);
    },
);

our $VERSION = '0.84';

sub msg_compile {
    my ( $self, %p) = @_;
    my $dzil     = $self->zilla;
    my $plugin   = $self->zilla->plugin_named('LocaleTextDomain')
        or $dzil->log_fatal('LocaleTextDomain plugin not found in dist.ini!');
    my $lang_dir = $p{lang_dir};
    my $dest_dir = $p{dest_dir};
    my $lang_ext = $plugin->lang_file_suffix;
    my $bin_ext  = $plugin->bin_file_suffix;
    my $txt_dom  = $plugin->textdomain;
    my $tmp_dir  = $self->_tmp_dir;

    my @cmd = (
        $p{msgfmt} || $plugin->msgfmt,
        '--check',
        '--statistics',
        '--verbose',
        '--output-file',
    );

    $plugin->log("Compiling language files in $lang_dir");
    make_path $tmp_dir->stringify;

    for my $lang (@{ $p{languages} || [] } || @{ $plugin->language }) {
        my $file = $lang_dir->file("$lang.$lang_ext");
        my $dest = file $dest_dir, 'LocaleData', $lang, 'LC_MESSAGES',
            "$txt_dom.$bin_ext";
        my $temp = $tmp_dir->file("$lang.$bin_ext");
        my $log = sub { $plugin->log(@_) };
        $plugin->add_file(
            Dist::Zilla::File::FromCode->new({
                name => $dest->stringify,
                code => sub {
                    run3 [@cmd, $temp, $file], undef, $log, $log;
                    $dzil->log_fatal("Cannot compile $file") if $?;
                    scalar $temp->slurp(iomode => '<:raw');
                },
            })
        );
    }
}

1;
__END__

=head1 Name

Dist::Zilla::Plugin::MsgCompile - Something that compiles gettext language translation files

=head1 Synopsis

  with 'Dist::Zilla::Role::MsgCompile';

  # ...

  sub gather_files {
      my $plugin = shift;
      my $pot_file = $plugin->msg_complie(%params);
  }

=head1 Description

This role provides a utility method for compiling
L<GNU gettext|http://www.gnu.org/software/gettext/>-style language translation
files.

=head2 Instance Methods

=head3 C<pot_file>

  $plugin->msg_compile(%params);

Finds and compiles GNU gettext language files. The supported parameters are:

=over

=item C<lang_dir>

A L<Path::Class::Dir> object representing the directory in which to find the
translation files. Defaults to the directory specified for the plugin.

=item C<dest_dir>

The destination directory into which to save the compiled translation files.
Defaults to F<./LocaleData>.

=item C<langauges>

List of language codes for languages to compile. Compiles all translation
files in C<lang_dir> by default.

=item C<msgfmt>

Path to the C<msgfmt> utility. Defaults to that specfied for the plugin.

=back

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

This software is copyright (c) 2012 by David E. Wheeler.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
