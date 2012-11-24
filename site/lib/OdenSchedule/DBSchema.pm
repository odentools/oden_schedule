package OdenSchedule::DBSchema;

# データベース スキーマ定義

use parent qw/ Data::Model /;
use Data::Model::Schema sugar => 'odenschedule';

# Column-sugar
column_sugar 'user.id';
column_sugar 'schedule.date' => int => {
	inflate => sub { # DB -> Object
		return Time::Piece->new($_[0]);
	},
	deflate => sub { # Object -> DB
		ref( $_[0] ) && $_[0]->isa('Time::Piece') ? $_[0]->epoch : $_[0];
	},
};

# Table: user
install_model user => schema {
	key 'id';
	index 'id';
	index 'google_id';
	index 'session_token';
	columns qw/ name student_no type session_token google_id google_token google_reftoken calendar_id_gcal latest_auth_time latest_mail_id /;
	column 'user.id';
};

# Table: schedule
install_model schedule => schema {
	key 'id';
	index 'user_id';
	columns qw/ id hash_id month day time wday subject teacher type room campus gcal_id /;
	column 'user.id';          # -> user_id
	column 'schedule.date';    # -> date
};

1;
