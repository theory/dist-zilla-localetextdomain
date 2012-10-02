# ABSTRACT: Tools for managing Locale::TextDomain language catalogs

package Dist::Zilla::LocaleTextDomain;
use v5.8.5;

our $VERSION = '0.82';

1;

__END__

=head1 Name

Dist::Zilla::LocaleTextDomain - Tools for managing Locale::TextDomain language catalogs

=head1 Synopsis

In F<dist.ini>:

  [ShareDir]
  [LocaleTextDomain]
  textdomain = My-App
  share_dir = share

Scan localizable messages from your Perl libraries into a language template
file, F<po/My-App.pot>:

  dzil msg-scan

Initialize language translation files:

  dzil msg-init fr de.UTF-8

Merge changes to localizable messages into existing translation files:

  dzil msg-merge

Binary message catalogs are automatically added to your distribution by the
C<build> and C<release> commands:

  dzil build
  dzil release

=head1 Description

L<Locale::TextDomain> provides a nice interface for localizing your Perl
applications. The tools for managing translations, however, is a bit arcane.
Fortunately, you can just use this plugin and get all the tools you need to
scan your Perl libraries for localizable strings, create a language template,
and initialize translation files and keep them up-to-date. All this is
assuming that your system has the
L<gettext|http://www.gnu.org/software/gettext/> utilities installed.

=head1 The Details

I put off learning how to use L<Locale::TextDomain> for quite a while because,
while the L<gettext|http://www.gnu.org/software/gettext/> tools are great for
translators, the tools for the developer were a little more opaque, especially
for Perlers used to L<Locale::Maketext>. But I put in the effort while hacking
L<Sqitch|App::Sqitch>. As I had hoped, using it in my code was easy. Using it
for my distribution was harder, so I decided to write
Dist::Zilla::LocaleTextDomain to make life simpler for developers who manage
their distributions with L<Dist::Zilla>.

What follows is a quick tutorial on using L<Locale::TextDomain> in your code
and managing it with Dist::Zilla::LocaleTextDomain.

=head1 This is my domain

First thing to do is to start using L<Locale::TextDomain> in your code. Load
it into each module with the name of your distribution, as set by the C<name>
attribute in your F<dist.ini> file. For example, if your F<dist.ini> looks
something like this:

  name    = My-GreatApp
  author  = Homer Simpson <homer@example.com>
  license = Perl_5

Then, in you Perl libraries, load L<Locale::TextDomain> like this:

  use Locale::TextDomain qw(My-GreatApp);

L<Locale::TextDomain> uses this value to find localization catalogs, so
naturally Dist::Zilla::LocaleTextDomain will use it to put those catalogs in
the right place.

Okay, so it's loaded, how do you use it? The documentation of the
L<Locale::TextDomain exported functions|Locale::TextDomain/EXPORTED FUNCTIONS>
is quite comprehensive, and I think you'll find it pretty simple once you get
used to it. For example, simple strings are denoted with C<__>:

  say __ 'Hello';

If you need to specify variables, use C<__x>:

  say __x(
      'You selected the color {color}',
      color => $color
  );

Need to deal with plurals? Use C<__n>

  say __n(
      'One file has been deleted',
      'All files have been deleted',
      $num_files,
  );

And then you can mix variables with plurals with C<__nx>:

  say __nx(
      'One file has been deleted.',
      '{count} files have been deleted.'",
      $num_files,
      count => $num_files,
  );

Pretty simple, right? Get to know these functions, and just make it a habit to
use them in user-visible messages in your code. Even if you never expect to
translate those messages, just by doing this you make it easier for someone
else to come along and start translating for you.

=head2 The setup

Now you're localizing your code. Great! What's next? Officially, nothing. If
you never do anything else, your code will always emit the messages as
written. You can ship it and things will work just as if you had never done
any localization.

But what's the fun in that? Let's set things up so that translation catalogs
will be built and distributed once they're written. Add these lines to your
F<dist.ini>:

  [ShareDir]
  [LocaleTextDomain]

There are actually quite a few attributes you can set here to tell the
plugin where to find language files and where to put them. For example, if
you used a domain different from your distribution name, e.g.,

  use Locale::TextDomain 'com.example.My-GreatApp';

Then you would need to set the C<textdomain> attribute so that the
C<LocaleTextDomain> does the right thing with the language files:

  [LocaleTextDomain]
  textdomain = com.example.My-GreatApp

Consult the
L<C<LocaleTextDomain> configuration docs|Dist::Zilla::Plugin::LocaleTextDomain/Configuration>
for details on all available attributes.

B<(Special note until L<this Locale::TextDomain
patch|https://rt.cpan.org/Public/Bug/Display.html?id=79461> is merged: set the
C<share_dir> attribute to C<lib> instead of the default value, C<share>. If
you use L<Module::Build>, you will also need a subclass to do the right thing
with the catalog files; see
L<Dist::Zilla::Plugin::LocaleTextDomain/Installation> for details.)>

What does this do including the plugin do? Mostly nothing. You might see this
line from C<dzil build>, though:

  [LocaleTextDomain] Skipping language compilation: directory po does not exist

Now at least you know it was looking for something to compile for
distribution. Let's give it something to find.

=head2 Initialize languages

To add translation files, use the
L<C<msg-init>|Dist::Zilla::App::Command::msg_init> command:

  > dzil msg-init de
  Created po/de.po.

At this point, the L<gettext|http://www.gnu.org/software/gettext/> utilities
will need to be installed and visible in your path, or else you'll get errors.

This command scans all of the Perl modules gathered by Dist::Zilla and
initializes a German translation file, named F<po/de.po>. This file is now
ready for your German-speaking public to start translating. Check it into your
source code repository so they can find it. Create as many language files as
you like:

  > dzil msg-init fr ja.JIS en_US.UTF-8
  Created po/fr.po.
  Created po/ja.po.
  Created po/en_US.po.

As you can see, each language results in the generation of the appropriate
file in the F<po> directory, sans encoding (i.e., no F<.UTF-8> in the C<en_US>
file name).

Now let your translators go wild with all the languages they speak, as well as
the regional dialects. (Don't forget to colour your code with C<en_UK>
translations!)

Once you have translations and they're committed to your repository, when you
build your distribution, the language files will automatically be compiled
into binary catalogs. You'll see this line output from C<dzil build>:

  [LocaleTextDomain] Compiling language files in po
  po/fr.po: 10 translated messages, 1 fuzzy translation, 0 untranslated messages.
  po/ja.po: 10 translated messages, 1 fuzzy translation, 0 untranslated messages.
  po/en_US.po: 10 translated messages, 1 fuzzy translation, 0 untranslated messages.

You'll then find the catalogs in the shared directory of your distribution:

  > find My-GreatApp-0.01/share -type f
  My-GreatApp-0.01/share/LocaleData/de/LC_MESSAGES/App-Sqitch.mo
  My-GreatApp-0.01/share/LocaleData/en_US/LC_MESSAGES/App-Sqitch.mo
  My-GreatApp-0.01/share/LocaleData/ja/LC_MESSAGES/App-Sqitch.mo

These binary catalogs will be installed as part of the distribution just where
C<Locale::TextDomain> can find them.

Here's an optional tweak: add this line to your C<MANIFEST.SKIP>:

  ^po/

This prevents the F<po> directory and its contents from being included in the
distribution. Sure, you can include them if you like, but they're not required
for the running of your app; the generated binary catalog files are all you
need. Might as well leave out the translation files.

=head2 Mergers and acquisitions

You've got translation files and helpful translators given them a workover.
What happens when you change your code, add new messages, or modify existing
ones? The translation files need to periodically be updated with those
changes, so that your translators can deal with them. We got you covered with
the L<C<msg-merge>|Dist::Zilla::App::Command::msg_merge> command:

  > dzil msg-merge
  extracting gettext strings
  Merging gettext strings into po/de.po
  Merging gettext strings into po/en_US.po
  Merging gettext strings into po/ja.po

This will scan your module files again and update all of the translation files
with any changes. Old messages will be commented-out and new ones added. Just
commit the changes to your repository and notify the translation army that
they've got more work to do.

If for some reason you need to update only a subset of language files, you can
simply list them on the command-line:

  > dzil msg-merge po/de.po po/en_US.po
  Merging gettext strings into po/de.po
  Merging gettext strings into po/en_US.po

=head2 What's the scan, man

Both the C<msg-init> and C<msg-merge> commands depend on a translation
template file to create and merge language files. Thus far, this has been
invisible: they will create a temporary template file to do their work, and
then delete it when they're done.

However, it's common to also store the template file in your repository and to
manage it directly, rather than implicitly. If you'd like to do this, the
L<C<msg-scan>|Dist::Zilla::App::Command::msg_scan> command will scan the Perl
module files gathered by Dist::Zilla and make it for you:

  > dzil msg-scan
  gettext strings into po/My-GreatApp.pot

The resulting F<.pot> file will then be used by C<msg-init> and C<msg-merge>
rather than scanning your code all over again. This actually then makes C<msg-merge>
a two-step process: You need to update the template before merging. Updating
the template is done by exactly the same command, C<msg-scan>:

  > dzil msg-scan
  extracting gettext strings into po/My-GreatApp.pot
  > dzil msg-merge
  Merging gettext strings into po/de.po
  Merging gettext strings into po/en_US.po
  Merging gettext strings into po/ja.po

=head2 Ship It!

And that's all there is to it. Go forth and localize and internationalize your
Perl apps!

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

This software is copyright (c) 2012 by David E. Wheeler.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
