$(document).on('turbolinks:load', function() {

	$("#pictures-wrapper a").filter(function() {
		return $(this).siblings("input.checkbox").length > 0;
	}).each(function(index) {
		$(this).bind("click", function() {
			var checkbox = $($(this).parent().children().filter("input").get(0));
			checkbox.attr("checked", !checkbox.attr("checked"));
			return false;
		});
	});

});
