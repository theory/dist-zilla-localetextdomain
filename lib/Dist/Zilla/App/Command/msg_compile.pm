package Dist::Zilla::App::Command::msg_compile;

# ABSTRACT: Add language translation catalogs to a dist

use Dist::Zilla::App -command;
use strict;
use warnings;
use Path::Class;
use Dist::Zilla::Plugin::LocaleTextDomain;
use Moose;
use namespace::autoclean;

our $VERSION = '0.84';

with 'Dist::Zilla::Role::MsgCompile';

sub command_names { qw(msg-compile) }

sub abstract { 'compmile language translation files' }

sub usage_desc { '%c %o <language_code> [<langauge_code> ...]' }

sub opt_spec {
    return (
        [ 'lang-dir|l=s' => 'location in which to find translation files' ],
        [ 'dest-dir|d=s' => 'location in which to save complied files'    ],
        [ 'msgfmt|m=s'   => 'location of msgfmt utility'                   ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    if ( my $msgfmt = $opt->{msgfmt} ) {
        require IPC::Cmd;
        $self->log_fatal(
            qq{Cannot find "$msgfmt": Are the GNU gettext utilities installed?}
        ) unless IPC::Cmd::can_run($msgfmt);
    }

    if ( my $dir = $opt->{lang_dir} ) {
        $self->log_fatal(qq{Directory "$dir" does not exist}) unless -e $dir;
        $self->log_fatal(qq{"$dir" is not a directory}) unless -d $dir;
        $opt->{lang_dir} = dir $dir;
    }
}

sub execute {
    my ($self, $opt, $args) = @_;
    my $plugin = $self->zilla->plugin_named('LocaleTextDomain')
        or $self->zilla->log_fatal('LocaleTextDomain plugin not found in dist.ini!');

    $self->msg_compile(
        msgfmt    => $opt->{msgfmt},
        languages => $args,
        lang_dir  => $opt->{lang_dir} || $plugin->lang_dir,
        dest_dir  => $opt->{dest_dir} || dir 'LocaleData',
    );
}

1;
__END__

=head1 Name

Dist::Zilla::App::Command::msg_compile - Add language translation catalogs to a dist

=head1 Synopsis

In F<dist.ini>:

  [LocaleTextDomain]
  textdomain = My-App
  lang_dir = po

On the command line:

  dzil msg-compile fr

=head1 Description

This command compileializes and adds one or more
L<GNU gettext|http://www.gnu.org/software/gettext/>-style language catalogs to
your distribution. It can either use an existing template file (such as can be
created with the L<C<msg-scan>|Dist::Zilla::App::Command::msg_compile> command)
or will scan your distribution's Perl modules directly to create the catalog.
It relies on the settings from the
L<C<LocaleTextDomain> plugin|Dist::Zilla::Plugin::LocaleTextDomain> for its
settings, and requires that the GNU gettext utilities be available.

=head2 Options

=head3 C<--msgfmt>

The location of the C<msgfmt> program, which is distributed with
L<GNU gettext|http://www.gnu.org/software/gettext/>. Defaults to just
C<msgfmt> (or C<msgfmt.exe> on Windows), which should work if it's in your
path. Not used if C<--pot-file> points to an existing template file.

=head3 C<--msgcompile>

The location of the C<msgcompile> program, which is distributed with L<GNU
gettext|http://www.gnu.org/software/gettext/>. Defaults to just C<msgcompile>
(or C<msgcompile.exe> on Windows), which should work if it's in your path.

=head3 C<--encoding>

The encoding to assume the Perl modules are encoded in. Defaults to C<UTF-8>.

=head3 C<--pot-file>

The name of the template file to use to generate the message catalogs. If not
specified, C<$lang_dir/$textdomain.pot> will be used if it exists. Otherwise,
a temporary template file will be created by scanning the Perl sources.

=head3 C<--copyright-holder>

Name of the application copyright holder. Defaults to the copyright holder
defined in F<dist.ini>. Used only to generate a temporary template file.

=head3 C<--bugs-email>

Email address to which translation bug reports should be sent. Defaults to the
email address of the first distribution author, if available. Used only to
generate a temporary template file.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

This software is copyright (c) 2012 by David E. Wheeler.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
