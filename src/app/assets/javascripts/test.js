$(document).ready(function() {

	$("#pictures-wrapper a").each(function(index) {
		$(this).bind("click", function() {
			var checkbox = $($(this).parent().children().filter("input").get(0));
			checkbox.attr("checked", !checkbox.attr("checked"));
			return false;
		});	
	});

});