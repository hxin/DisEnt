# -*-Perl-*- Test Harness script for Bioperl
# $Id: PodSyntax.t 11525 2007-06-27 10:16:38Z sendu $

use strict;

BEGIN {
	use Test::More;
	eval 'use Test::Pod 1.00';
	plan (skip_all => 'Test::Pod 1.00 required for testing POD' ) if $@;
}

# check pod is syntactically correct
all_pod_files_ok( all_pod_files('.') )
