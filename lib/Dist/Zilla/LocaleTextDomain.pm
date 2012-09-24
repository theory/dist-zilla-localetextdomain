# ABSTRACT: Tools for managing Locale::TextDomain language catalogs

package Dist::Zilla::LocaleTextDomain;

our $VERSION = '0.11';

1;

__END__

=head1 Name

Dist::Zilla::LocaleTextDomain - Tools for managing Locale::TextDomain language catalogs

=head1 Synopsis

In F<dist.ini>:

  [ShareDir]
  [@LocaleTextDomain]
  textdomain = My-App
  lang_dir = po
  share_dir = share

Create a language template file, F<po/My-App.pot>:

  dzil msg-scan

Create language translation catalogs:

  dzil msg-init fr de.UTF-8

Update existing catalogs:

  dzil msg-merge

In F<MANIFEST.SKIP>, prevent distribution of ship the F<po> directory:

  ^po/

Binary message catalogs are automatically added to your distribution by the
C<build> and C<releae> commands:

  dzil build
  dzil release

=head1 Description

L<Locale::TextDomain> provides a nice interface for localizing your Perl
applications. The tools for managing translations, however, is a bit arcane.
Fortunately, you can just use this plugin and get all the tools you need to
scan your Perl libraries for localizable strings, create a language template,
and initialize translation catalog files and keep them up-to-date. All this is
assuming that your system has the
L<gettext|http://www.gnu.org/software/gettext/> utilities installed.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

This software is copyright (c) 2012 by David E. Wheeler.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
