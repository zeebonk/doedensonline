$(document).on('turbolinks:load', function() {
  tinymce.init({
    selector: 'textarea',
    license_key: 'gpl',
    language: 'nl',
    language_url: 'https://cdn.jsdelivr.net/npm/tinymce-i18n@26.10.19/langs8/nl.js',
    plugins: 'lists advlist link wordcount emoticons',
    toolbar: 'bold italic underline strikethrough | link | bullist numlist | emoticons',
    menubar: false,
    branding: false,
    paste_as_text: true,
    content_css: 'https://cdn.jsdelivr.net/npm/tinymce@8.10.0/skins/ui/tinymce-5/content.min.css'
  });
});

$(document).on('turbolinks:before-cache', function() {
  tinymce.remove();
});
