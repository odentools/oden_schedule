use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  VERSION   => '0.01',
  PREREQ_PM => {
	'Mojolicious' => '3.50',
	'Data::Model' => 0,
	'Encode::IMAPUTF7' => 0,
	'Mail::IMAPClient' => 0,
	'MIME::Base64' => 0,
	'MongoDB' => 0,
	'URI::Escape' => 0,
	'JSON' => 0,
	'LWP::UserAgent' => 0,
	'Digest::SHA1' => 0
  },
  test      => {TESTS => 't/*.t'}
);
