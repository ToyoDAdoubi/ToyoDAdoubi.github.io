// Cybermap v2 widget loader
(function() {

    function setup_widget(div) {
        var config = {
            width: div.dataset.width || 640,
            height: div.dataset.height || 640,
            language: div.dataset.language || 'en',
            theme: div.dataset.theme || 'dark',
            type: div.dataset.type || 'dynamic'
        };
        console.log("config.language >> " + config.language);
        var iframe = document.createElement('iframe');

        // todo remove https://cybermap.kaspersky.com
        var baseURI = 'https://cybermap.kaspersky.com/widget/';
        iframe.src = baseURI + (config.type == 'dynamic' ? 'dynamic.html' : 'static.html');

        iframe.style.width = config.width + 'px';
        iframe.style.height = config.height + 'px';
        iframe.style.border = 'none';

        iframe.onload = function() {
            console.log("config.language >> " + config.language);
            var msg = JSON.stringify({ config: config });
            iframe.contentWindow.postMessage(msg, '*');
        };
        console.log("config.language >> " + config.language);
        div.appendChild(iframe);
    }

    var divs = document.querySelectorAll('.kas-cybermap-widget');
    for (var i = 0; i < divs.length; ++i) {
        setup_widget(divs[i]);
    }

}());