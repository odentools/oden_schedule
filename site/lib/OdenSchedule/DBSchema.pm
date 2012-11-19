package OdenSchedule::DBSchema;
# データベース スキーマ定義 

use parent qw/ Data::Model /;
use Data::Model::Schema;
 
install_model user => schema {
	key 'id';
	columns qw/ id name student_no type google_id google_token latest_auth_time latest_mail_id /;
};

1;