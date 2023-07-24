package UNIVERSAL::FatalImport;
our $VERSION = '0.001000';

my $def_import;
my $def_unimport;
my $def_version;

sub import {
  require 'UNIVERSAL.pm';

  my $no_exporter;
  my $allow_version;
  for my $arg (@_[1 .. $#_]) {
    if ($arg eq '-no-exporter') {
      $no_exporter = 1;
    }
    elsif ($arg eq '-allow-version') {
      $allow_version = 1;
    }
    else {
      die "Invalid option $arg!";
    }
  }

  if (!defined $def_import) {
    $def_import = defined &{"UNIVERSAL::import"} && \&{"UNIVERSAL::import"};
    delete ${"UNIVERSAL::"}{import};
    eval '#line '.(__LINE__+1).' "'.__FILE__.qq["\n] . <<'END_CODE' or die $@;
      package UNIVERSAL;
      sub import {
        return
          if $_[0] eq "_charnames";
        if (@_ > 1) {
          if (@_ == 2 && $allow_version && $_[1] =~ /\A[0-9]/) {
            $_[0]->VERSION($_[1]);
            return;
          }
          die sprintf "Unhandled arguments passed to %s->import(%s) at %s line %s\n",
            $_[0], join(', ', @_[1 .. $#_]), (caller)[1,2];
        }
        goto &$def_import if $def_import;
      }
      1;
END_CODE
  }

  if (!defined $def_unimport) {
    $def_unimport = defined &{"UNIVERSAL::unimport"} && \&{"UNIVERSAL::unimport"};
    delete ${"UNIVERSAL::"}{unimport};
    eval '#line '.(__LINE__+1).' "'.__FILE__.qq["\n] . <<'END_CODE' or die $@;
      package UNIVERSAL;
      sub unimport {
        return
          if $_[0] eq "_charnames";
        if (@_ > 1) {
          die sprintf "Unhandled arguments passed to %s->unimport(%s) at %s line %s\n",
            $_[0], join(', ', @_[1 .. $#_]), (caller)[1,2];
        }
        goto &$def_unimport if defined $def_unimport;
      }
      1;
END_CODE
  }

  if ($no_exporter && !defined $def_version) {
    $def_version = defined &{"UNIVERSAL::VERSION"} && \&{"UNIVERSAL::VERSION"};
    delete ${"UNIVERSAL::"}{VERSION};
    eval '#line '.(__LINE__+1).' "'.__FILE__.qq["\n] . <<'END_CODE' or die $@;
      package UNIVERSAL;
      sub VERSION {
        if (caller eq "Exporter::Heavy") {
          my $caller_level = 0;
          while(1) {
            $caller_level++;
            my $caller = caller($caller_level);
            last
              if $caller ne 'Exporter' && $caller ne 'Exporter::Heavy';
          }
          die sprintf "Refusing to check VERSION via Exporter at %s line %d.\n", (caller($caller_level))[1,2];
        }
        goto &$def_version if defined $def_version;
      }
      1;
END_CODE
  }
}

1;
__END__

=head1 NAME

UNIVERSAL::FatalImport - Make UNIVERSAL::import fatal when called with arguments

=head1 SYNOPSIS

  PERL5OPT=-MUNIVERSAL::FatalImport prove -l
  PERL5OPT=-MUNIVERSAL::FatalImport=-allow-version prove -l
  PERL5OPT=-MUNIVERSAL::FatalImport=-no-exporter prove -l

=head1 DESCRIPTION

This module is meant to assist testing for bad import arguments, which will be
fatal in perl in a future version.

=head1 OPTIONS

Options can be passed as arguments to import.

=over 4

=item C<-allow-version>

If specified, C<< Module->import('1.0') >> and C<< use Module '1.0'; >> will be
allowed, and will perform a version check. This is similar to the behavior of
L<Exporter>.

=item C<-no-exporter>

L<Exporter> allows passing version numbers as arguments, and will perform a
version check rather than throwing an error about an unhandled import. If this
option is specified, this will always throw an error rather than performing a
version check.

=back

=cut
