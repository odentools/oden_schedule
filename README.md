# oden_schedule (Odensuke)

based on: perl + Mojolicious + MongoDB + IMAP + Google Calendar API...

## Libraries
Many thanks :)

### Mojolicious

https://github.com/kraih/mojo

### Data::Model

http://github.com/yappo/p5-Data-Model/

### Data::Model::Driver::MongoDB

https://github.com/ytnobody/Data-Model-Driver-MongoDB/

(C) ytnobody <ytnobody@gmail.com>

> This library is free software; you can redistribute it and/or modify it　under the same terms as Perl itself.

### Digest::SHA1

http://search.cpan.org/~gaas/Digest-SHA1/

### Net::OAuth2

https://github.com/keeth/Net-OAuth2

Copyright (C) 2010 Keith Grennan

> This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

It was included, modified a little from [original](https://github.com/keeth/Net-OAuth2) version.

### Encode::IMAPUTF7

http://search.cpan.org/~pmakholm/Encode-IMAPUTF7/

### Mail::IMAPClient

http://search.cpan.org/~plobbes/Mail-IMAPClient/

### MIME::Base64

http://search.cpan.org/~gaas/MIME-Base64/

### MongoDB (mongo-perl-driver)

https://github.com/mongodb/mongo-perl-driver

### URI::Escape

http://search.cpan.org/dist/URI/URI/Escape.pm

### Time::Piece

http://search.cpan.org/~msergeant/Time-Piece/

### Twitter Bootstrap

https://github.com/twitter/bootstrap

Copyright 2012 Twitter, Inc.

> Apache License 2.0 https://github.com/twitter/bootstrap/blob/master/LICENSE

### jQuery

https://github.com/jquery/jquery

Copyright 2012 jQuery Foundation and other contributors. http://jquery.com/

> MIT License https://github.com/jquery/jquery/blob/master/MIT-LICENSE.txt

### Glyphicons Free

http://glyphicons.com/

> GLYPHICONS FREE are released under the Creative Commons Attribution 3.0 Unported (CC BY 3.0).
	The GLYPHICONS FREE can be used both commercially and for personal use, 
	but you must always add a link to glyphicons.com in a prominent place (e.g. the footer of a website), 
	include the CC-BY license and the reference to glyphicons.com on every page using GLYPHICONS.

### etc...

## Environment configuration

site/config/config.conf

	{
		base_url				=>	'http://hoge.com/oden_schedule',
        base_path				=>	'/oden_schedule',
		social_google_key		=>	'GOOGLE_OAUTH_CONSUMER_KEY',
		social_google_secret	=>	'GOOGLE_OAUTH_CONSUMER_SECRET',
		social_google_apikey	=>	'GOOGLE_API_KEY',
		session_name			=>	'odenschedule',
		session_secret		=>	'COOKIE_SIGNATURE_KEY',
		session_expires 		=>	604800, # 604800 = 7day * 24hour * 60min * 60sec
		batch_interval			=>	43200, # 43200 = 12hour * 60min * 60sec (MINIMUM: 120sec)
		db_host	=>	'localhost', # MongoDB host
		db_port	=>	'27017', # MongoDB port (default: 27017)
		db_name	=>	'odenschedule' # MongoDB db name
	}

## License and Copyright

Copyright (C) 2012 OdenTools Project (https://sites.google.com/site/odentools/), Masanori Ohgita (http://ohgita.info/).

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License version 3 (GPL v3).
