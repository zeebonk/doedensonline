tinymce.init({
  selector: 'textarea',
  language: 'nl',
  language_url: 'https://cdn.jsdelivr.net/npm/tinymce-i18n@24/langs7/nl.js',
  plugins: 'lists advlist link wordcount emoticons',
  toolbar: 'bold italic underline strikethrough | link | bullist numlist | emoticons',
  menubar: false,
  branding: false,
  paste_as_text: true,
  content_css: '/stylesheets/tiny-mce.css'
});
