$(document).on('turbolinks:load', function() {

	$("#pictures-wrapper a").filter(function() {
		return $(this).siblings("input.checkbox").length > 0;
	}).each(function(index) {
		$(this).on("click", function() {
			var checkbox = $($(this).parent().children().filter("input").get(0));
			checkbox.prop("checked", !checkbox.prop("checked"));
			return false;
		});
	});

});
