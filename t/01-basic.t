use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

{
    package MyTestPlugin;
    use Moose;
    with 'Dist::Zilla::Role::MetaProvider',
        'Dist::Zilla::Role::ModuleMetadata';

    sub metadata {
        my $self = shift;
        return +{
            provides => +{
                map {
                    my $file = $_;
                    my $mmd = $self->module_metadata_for_file($file);
                    map {
                        # $modulename => { file => $filename, version => #version }
                        $_ => +{
                            file => $file->name,
                            version => $mmd->version($_),
                        }
                    } grep { $_ ne 'main' } $mmd->packages_inside
                } grep { $_->name =~ /^lib\/.*\.pm$/} @{ $self->zilla->files }
            },
        };
    }
}

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                '=MyTestPlugin',
            ),
            path(qw(source lib Foo.pm)) => <<'FOO',
package Foo;
our $VERSION = '0.001';
FOO
            path(qw(source lib Bar.pm)) => <<'BAR',
package Bar;
our $VERSION = '0.002';

package Bar::Baz;
our $VERSION = '0.003';
BAR
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        provides => {
            'Foo' => {
                file => 'lib/Foo.pm',
                version => '0.001',
            },
            'Bar' => {
                file => 'lib/Bar.pm',
                version => '0.002',
            },
            'Bar::Baz' => {
                file => 'lib/Bar.pm',
                version => '0.003',
            },
        },
    }),
    'plugin metadata contains data from Module::Metadata object',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
