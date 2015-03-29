use strict;
use warnings;
package Dist::Zilla::Role::ModuleMetadata;
# ABSTRACT: a role for plugins which Module::Metadata
# KEYWORDS: zilla distribution plugin role metadata cache packages versions
# vim: set ts=8 sts=4 sw=4 tw=78 et :

use Moose::Role;
use Module::Metadata 1.000005;
use Digest::MD5 'md5';
use namespace::autoclean;

our $VERSION = '0.001';

my %CACHE;

sub module_metadata_for_file
{
    my ($self, $file) = @_;

    # handle dzil v4 files by assuming no (or latin1) encoding
    my $encoded_content = $file->can('encoded_content') ? $file->encoded_content : $file->content;

    # We cache on the MD5 checksum to detect if the file has been modified
    # by some other plugin since it was last parsed, making our object invalid.
    my $md5 = md5($encoded_content);
    return $CACHE{$md5} if $CACHE{$md5};

    open(
        my $fh,
        ($file->can('encoding') ? sprintf('<:encoding(%s)', $file->encoding) : '<'),
        \$encoded_content,
    ) or $self->log_fatal('cannot open handle to ' . $file->name . ' content: ' . $!);

    my $mmd = Module::Metadata->new_from_handle($fh, $file->name);
    return ($CACHE{$md5} = $mmd);
}

1;
__END__

=pod

=head1 SYNOPSIS

    package Dist::Zilla::Plugin::YourNewPlugin;
    use Moose;
    with
        'Dist::Zilla::Role::...',
        'Dist::Zilla::Role::ModuleMetadata';
    use namespace::autoclean;

    sub your_method {
        my $self = shift;

        my $file = ...; # perhaps via the :InstallModules filefinder?
        my $version = $self->module_metadata_for_file->($file)->version;
        ...
    }

=head1 DESCRIPTION

This L<role|Moose::Role> provides some common utilities for L<Dist::Zilla>
plugins which use L<Module::Metadata> and the information that it provides.

=head1 METHODS PROVIDED

=head2 C<module_metadata_for_file>

    my $mmd = $self->module_metadata_for_file($file);

Given a dzil file object (anything that does L<Dist::Zilla::Role::File>), this
method returns a L<Module::Metadata> object for that file's content.

=for stopwords reparsing

Internally, this method caches these objects. If multiple plugins want an
object for the same file, this avoids reparsing it.

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Role-ModuleMetadata>
(or L<bug-Dist-Zilla-Role-ModuleMetadata@rt.cpan.org|mailto:bug-Dist-Zilla-Role-ModuleMetadata@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

=for :list
* L<Module::Metadata>

=cut
