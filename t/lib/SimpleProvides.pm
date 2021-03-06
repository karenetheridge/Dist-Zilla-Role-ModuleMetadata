package SimpleProvides;
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
                map
                    # $modulename => { file => $filename, version => version }
                    +($_ => +{
                        file => $file->name,
                        version => $mmd->version($_) . '',
                    }),
                    grep $_ ne 'main', $mmd->packages_inside
            } grep $_->name =~ /^lib\/.*\.pm$/, @{ $self->zilla->files }
        },
    };
}

1;
