$(document).on('page:change', function() {
  $("a[rel='album']").colorbox({maxWidth:"85%", maxHeight:"85%"});
});

$(document).on('page:before-change', function() {
  $.colorbox.remove()
});
