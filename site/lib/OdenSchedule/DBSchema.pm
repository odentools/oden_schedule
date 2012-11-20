package OdenSchedule::DBSchema;
# データベース スキーマ定義 

use parent qw/ Data::Model /;
use Data::Model::Schema;
 
install_model user => schema {
	key 'id';
	columns qw/ id name student_no type google_id google_token google_reftoken calendar_id_gcal latest_auth_time latest_mail_id /;
};

install_model schedule => schema {
	key 'id';
	columns qw/ id user_id month day wday subject teacher gcal_id /;
};

1;