package OdenSchedule::Controller::Session;
use Mojo::Base 'Mojolicious::Controller';

use utf8;

sub login {
	my $self = shift;

	my $message = "";
	my $uid = $self->param("id");
	my $upw = $self->param("pw");
	if ( defined($uid) && defined($upw) ) {

		# ログイン処理
		my $oecu = Net::OECUMail->new( 'username' => $uid, 'password' => $upw );
		my $flg = 0;
		eval{
			$flg = $oecu->login();
		};
		if ($@ || $flg ne 1) {
			# ログイン失敗時
			$message = q(<strong>認証に失敗しました。</strong> <a href="http://ent.oecu.jp/">OECUMail</a>がメンテナンス中でないか確認してください。);
		} else {
			# ログイン成功時
			
			
			
			$self->session('sid', );
			$self->redirect_to("/?logined");
		} 

	}

	$self->render( message => $message );
}

1;
