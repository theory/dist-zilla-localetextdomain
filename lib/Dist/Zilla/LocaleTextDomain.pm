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

=head1 The Details

I put off learning how to use L<Locale::TextDomain> for quite a while because,
while the L<gettext|http://www.gnu.org/software/gettext/> tools are great for
translators, the tools for the developer were a little more opaque, especially
for Perlers used to L<Locale::Maketext>, which is just Perl. But I put in the
effort to learn how to use it while hacking L<Sqitch|App::Sqitch>. As I had
hoped, using it in my code was easy. Using it for my distribution was harder,
so I decided to write Dist::Zilla::LocaleTextDomain to make life simpler for
developers who manage their distributions with L<Dist::Zilla>.

So what follows is a quick tutorial on using L<Locale::TextDomain> in your
code, and managing it with Dist::Zilla::LocaleTextDomain.

=head1 This is my domain

First thing to do is to start using L<Locale::TextDomain> in your code. Load
it into each module with the name of your distribution, as set by the C<name>
attribute in your F<dist.ini> file. So if your F<dist.ini> looks something
like this:

  name    = My-GreatApp
  author  = Homer Simpson <homer@example.com>
  license = Perl_5

Then, in you Perl libraries, load L<Locale::TextDomain> like this:

  use Locale::TextDomain qw(My-GreatApp);

L<Locale::TextDomain> uses this value to find localization catalogs, so
naturally Dist::Zilla::LocaleTextDomain> will use it to put those catalogs in
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
need to translate those messages, just by doing this you make it easier for
someone else to come along and start translating for you.

=head2 The setup

So now you're localizing your code. Great! What's next? Officially, nothing.
If you never do anything else, your code will always emit the messages as
written. So you can ship it and things will work just as if you had never
done any localization.

But what's the fun in that? Let's set things up so that translation catalogs
will be built and distributed once they're written. Add these lines to your
F<dist.ini>:

  [ShareDir]
  [LocaleTextDomain]
  textdomain = My-GreatApp
  share_dir = share

(Special note until L<this Locale::TextDomain
patch|https://rt.cpan.org/Public/Bug/Display.html?id=79461> is merged: use
C<lib> for the C<share_dir> value instead of C<share>. If you use
L<Module::Build>, you will also need a subclass to do the right thing with the
catalog files; see L<Dist::Zilla::Plugin::LocaleTextDomain/Installation> for
details.)

What does this do? Mostly nothing. You might see this line from C<dzil build>,
though:

  [LocaleTextDomain] Skipping language compilation: directory po does not exist

So then at least you know it was looking for something to compile for
distribution. Let's give it something to find.

=head2 Initialize languages

To add translation files, use the C<dzil msg-init> command:

  dzil msg-init de

At this point, the L<gettext|http://www.gnu.org/software/gettext/> utilities
will need to be installed and visible in your path, or else you'll get errors.

This command scans all of your Perl modules and initializes a German
translation file, named F<po/de.po>. This file is now ready for your
German-speaking public to start translating. Check it into your source code
repository so they can find it. Create as many language catalogs as you like:

  dzil msg-init fr ja.JIS en_US.UTF-8

Each will result in the generation of the appropriate file in the F<po>
directory, although without the encodings:

=over

=item * F<fr.po>

=item * F<ja.po>

=item * F<en_US.po>

=back

Let your translators go wild with all the languages they speak, as well as the
regional dialects. (Don't forget to colour your code with C<en_UK>
translations!)

Once you have translations and they're committed to your repository, when you
build your distribution, the language files will be compiled into binary
catalogs. You'll see this line from C<dzil build>:

  [LocaleTextDomain] Compiling language files in po

You'll then find the catalogs in the shared directory of your distribution:

  > find My-GreatApp-0.01/share -type f
  My-GreatApp-0.01/share/LocaleData/de/LC_MESSAGES/App-Sqitch.mo
  My-GreatApp-0.01/share/LocaleData/fr/LC_MESSAGES/App-Sqitch.mo

These binary catalogs will be installed as part of the distribution just where
C<Locale::TextDomain> can find them.

Here's an optional tweak: add this line to your C<MANIFEST.SKIP>:

  ^po/

This is to prevent the F<po> directory and its contents from being included in
the distribution. Sure, you can include them if you like, but they're not
required for the running of your app; the F<.mo> files are all you need. So
might as well leave them out.

=head2 Mergers and acquisitions



=head2 What's the scan, man



=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

This software is copyright (c) 2012 by David E. Wheeler.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
