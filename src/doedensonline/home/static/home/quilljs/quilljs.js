function enableQuill(targetId) {
    var toolbarOptions = [
        ['bold', 'italic', 'underline', 'strike'],
        [{ 'list': 'ordered'}, { 'list': 'bullet' }],
        [{ 'script': 'sub'}, { 'script': 'super' }],
        ['link'],
        ['clean']
    ];
    var target = $("#" + targetId);
    var targetShadowId = targetId + "_quill_shadow";
    var targetShadow = $("<div id='" + targetShadowId + "'></div>");
    targetShadow.insertAfter(target);
    target.hide();
    var quill = new Quill("#" + targetShadowId, {
        theme: 'snow',   // Specify theme in configuration
        placeholder: 'Begin met schrijven...',
        modules: {
            toolbar: toolbarOptions
        },
        formats: [
            'bold', 'italic', 'underline', 'strike', 'code', 'blockquote',
            'code-block', 'list', 'script', 'indent',
        ]
    });
    quill.root.innerHTML = target.text();
    quill.on('text-change', function(delta, oldDelta, source) {
        target.text(quill.root.innerHTML);
    });
}
