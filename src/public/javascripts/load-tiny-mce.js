tinyMCE.init({

  mode   : "textareas",
  language : "nl",
  theme  : "advanced",
  oninit : "setPlainText",
  plugins: "emotions,inlinepopups,paste,wordcount,advlist",
  
  theme_advanced_buttons1: "bold, italic, underline, strikethrough,link,bullist, numlist, emotions",
  theme_advanced_buttons2: "",
  theme_advanced_buttons3: "",
  theme_advanced_buttons4: "",
  
  theme_advanced_toolbar_location: "top",
  theme_advanced_toolbar_align   : "left",
  
  theme_advanced_statusbar_location: "bottom",
  
  theme_advanced_resizing: true,

  content_css : "/stylesheets/tiny-mce.css"
  
});

function setPlainText()
{
  var ed = tinyMCE.get('news_item_message') || tinyMCE.get('news_comment_message');
 
  ed.pasteAsPlainText = true;  
 
  //adding handlers crossbrowser
  if (tinymce.isOpera || /Firefox\/2/.test(navigator.userAgent)) 
  {
    ed.onKeyDown.add(function(ed, e){
      if (((tinymce.isMac ? e.metaKey : e.ctrlKey) && e.keyCode == 86) || (e.shiftKey && e.keyCode == 45))
        ed.pasteAsPlainText = true;
    });
  } 
  else 
  {            
    ed.onPaste.addToTop(function(ed, e){
      ed.pasteAsPlainText = true;
    });
  }
}