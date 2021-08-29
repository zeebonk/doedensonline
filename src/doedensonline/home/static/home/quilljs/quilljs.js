function getCookie(name) {
    let cookieValue = null;
    if (document.cookie && document.cookie !== '') {
        const cookies = document.cookie.split(';');
        for (let i = 0; i < cookies.length; i++) {
            const cookie = cookies[i].trim();
            // Does this cookie string begin with the name we want?
            if (cookie.substring(0, name.length + 1) === (name + '=')) {
                cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                break;
            }
        }
    }
    return cookieValue;
}

function selectLocalImage(quill) {
    const input = document.createElement('input');
    input.setAttribute('type', 'file');
    input.setAttribute('multiple', 'true');
    input.click();
    input.onchange = () => saveToServer(input.files, quill);
}

function saveToServer(files, quill) {
    const fd = new FormData();
    console.log(files);
    fd.append('image', files);
    const xhr = new XMLHttpRequest();
    xhr.open('POST', 'http://localhost:8000/posts/46/upload_file', true);
    xhr.setRequestHeader('X-CSRFToken', getCookie('csrftoken'));
    xhr.onload = () => {
        if (xhr.status === 200) {
            const urls = JSON.parse(xhr.responseText).urls;
            console.log(urls);
            urls.forEach(url => insertToEditor(url, quill));
        }
    };
    xhr.send(fd);
}

function insertToEditor(url, quill) {
    const range = quill.getSelection();
    quill.insertEmbed(range.index, 'image', url);
}


function enableQuill(targetId) {
    var toolbarOptions = [
        ['bold', 'italic', 'underline', 'strike'],
        [{ 'list': 'ordered'}, { 'list': 'bullet' }],
        [{ 'script': 'sub'}, { 'script': 'super' }],
        ['link', 'image'],
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
            'code-block', 'list', 'script', 'indent', 'image'
        ],
    });
    quill.root.innerHTML = target.text();
    quill.on('text-change', function(delta, oldDelta, source) {
        target.text(quill.root.innerHTML);
    });
    quill.getModule('toolbar').addHandler('image', () => {
      selectLocalImage(quill);
    });
}
