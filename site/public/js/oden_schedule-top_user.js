$(function() {
	$('#selectorCalendarName').change(function() {
		var $obj = $("#selectorCalendarName");
		$.ajax({
			type : "POST",
			url : "?",
			data : "set_calendar_id="+$obj.val(),
			success : function(msg) {
				showTooltip($obj,"カレンダー設定を保存しました");
			}
		});
	});
	
	function showTooltip($obj, text){
		$obj.tooltip({
			title : "<i class='icon-ok icon-white'>&nbsp;</i> "+text,
			trigger : "manual"
		}).tooltip('show');
		setTimeout(function() {
			$obj.tooltip('hide');
		}, 3000, $obj)
	};
});