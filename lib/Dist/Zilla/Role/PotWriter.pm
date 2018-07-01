package Dist::Zilla::Role::PotWriter;

# ABSTRACT: Something that writes gettext language translation template file

use Moose::Role;
use strict;
use warnings;
use IPC::Run3;
use Email::Address::XS 1.01;
use namespace::autoclean;

our $VERSION = '0.92';

sub files_to_scan {
    my $self   = shift;
    my $plugin = shift;
    my $dzil   = $self->zilla;
    $dzil->chrome->logger->mute;
    $_->gather_files for grep {
        ! $_->isa('Dist::Zilla::Plugin::LocaleTextDomain')
    } @{ $dzil->plugins_with(-FileGatherer) };
    $dzil->chrome->logger->unmute;
    return map { $_->name() } @{ $plugin->found_files() };
}

sub write_pot {
    my ($self, %p) = @_;
    my $dzil = $self->zilla;
    my $pot  = $p{to}
        or $dzil->log_fatal('Missing required "to" parameter to write_pot()');
    my $verb = -e $pot ? 'update' : 'create';

    # Make sure the directory exists.
    $pot->parent->mkpath unless -d $pot->parent;

    my $plugin = $dzil->plugin_named('LocaleTextDomain')
        or $dzil->log_fatal('LocaleTextDomain plugin not found in dist.ini!');

    # Need to do this before calling other methods, as they need the
    # files loaded to find various information.
    my @files = $self->files_to_scan($plugin);

    my $email = $p{bugs_email} || do {
        if (my $author = $dzil->authors->[0]) {
            my $addr = Email::Address::XS->parse($author);
            $addr->address if $addr->is_valid;
        }
    } || '';

    my $xgettext_args = $plugin->xgettext_args;
    my $override_args = $plugin->override_args;

    my @cmd = (
        $p{xgettext} || 'xgettext' . ($^O eq 'MSWin32' ? '.exe' : ''),
        '--from-code=' . ($p{encoding} || 'UTF-8'),
        '--add-comments=TRANSLATORS:',
        '--package-name=' . ($p{package} || $dzil->name),
        '--package-version=' . ($p{version} || $dzil->version || 'VERSION'),
        '--copyright-holder=' . ($p{copyright_holder} || $dzil->copyright_holder),
        ($email ? '--msgid-bugs-address=' . $email : ()),
        '--output=' . $pot,
    );
    my @default_keywords = (
        '--language=perl',
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
    );

    my $log = sub { $dzil->log(@_) };
    run3 [
        @cmd,
        $override_args ? () : @default_keywords,
        @$xgettext_args,
        @files,
    ], undef, $log, $log;
    $dzil->log_fatal("Cannot $verb $pot") if $?;

    my $join_existing = $plugin->join_existing;

    my $expand_arg = sub {
        my $arg = shift;
        if (my ($finder) = $arg =~ /^\%\{(.+)\}f$/) {
            my $files = $dzil->find_files($finder);
            return map { $_->name() } @$files;
        }
        return $arg;
    };

    for my $join (@$join_existing) {
        my @args = map { $expand_arg->($_) } @$join;
        run3 [
            @cmd,
            '--join-existing', @args,
        ], undef, $log, $log;
        $dzil->log_fatal("Cannot join existing $pot") if $?;
    }
}

requires 'zilla';

1;
__END__

=head1 Name

Dist::Zilla::Plugin::PotWriter - Something that writes gettext language translation template file

=head1 Synopsis

  with 'Dist::Zilla::Role::PotWriter';

  # ...

  sub execute {
      my $self = shift;
      $self->write_pot(%params);
  }


=head1 Description

This role provides a utility method for generating a
L<GNU gettext|http://www.gnu.org/software/gettext/>-style language translation
template.

=head2 Instance Methods

=head3 C<write_pot>

  $self->write_pot(%params);

Creates or updates a L<GNU gettext|http://www.gnu.org/software/gettext/>-style
language translation file. The supported parameters are:

=over

=item C<to>

L<Path::Tiny> object representing the file to write to. Required.

=item C<scan_files>

Array reference listing the files to scan. Defaults to all F<*.pm> files
gathered by L<Dist::Zilla>.

=item C<xgettext>

Path to the C<xgettext> application. Defaults to just C<xgettext>
(C<xgettext.exe> on Windows), which should work if it's in your path.

=item C<encoding>

Encoding to assume when scanning for localizable strings. Defaults to
C<UTF-8>.

=item C<package>

The name of the localization package. Defaults to the distribution name as
configured for L<Dist::Zilla>.

=item C<version>

The version of the package. Defaults to the version as configured for
L<Dist::Zilla>.

=item C<copyright_holder>

The name of the translation copyright holder. Defaults to the copyright holder
configured for L<Dist::Zilla>.

=item C<bugs_email>

Email address for reporting translation bugs. Defaults to the email address of
the first author known to L<Dist::Zilla>, if available and parseable by
L<Email::Address::XS>.

=back

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Contributor

Charles McGarvey <ccm@cpan.org>

=head1 Copyright and License

This software is copyright (c) 2012-2017 by David E. Wheeler.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
