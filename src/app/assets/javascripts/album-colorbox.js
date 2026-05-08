$(document).on('turbolinks:load', function() {
  $("a[rel='album']").colorbox({maxWidth:"85%", maxHeight:"85%"});
});

$(document).on('turbolinks:before-cache', function() {
  $.colorbox.remove()
});
