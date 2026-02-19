// html2pdf.js CDN loader and print/save logic for forms-viewer.html
(function() {
    // Load html2pdf.js from CDN if not present
    function loadHtml2Pdf(callback) {
        if (window.html2pdf) return callback();
        var script = document.createElement('script');
        script.src = 'https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js';
        script.onload = callback;
        document.head.appendChild(script);
    }
    // Print all forms (native print)
    window.printAllForms = function() {
        window.print();
    };
    // Save all forms as PDF (multi-page)
    window.saveAllFormsAsPDF = function() {
        loadHtml2Pdf(function() {
            var container = document.querySelector('.container');
            var opt = {
                margin:       0.5,
                filename:     'intake-package.pdf',
                image:        { type: 'jpeg', quality: 0.98 },
                html2canvas:  { scale: 2, useCORS: true },
                jsPDF:        { unit: 'in', format: 'letter', orientation: 'portrait' },
                pagebreak:    { mode: ['css', 'legacy'] }
            };
            window.html2pdf().set(opt).from(container).save();
        });
    };
    // Save individual form as PDF (multi-page if needed)
    window.saveFormAsPDF = function(formId) {
        loadHtml2Pdf(function() {
            var form = document.getElementById('form-' + formId);
            var opt = {
                margin:       0.5,
                filename:     formId + '.pdf',
                image:        { type: 'jpeg', quality: 0.98 },
                html2canvas:  { scale: 2, useCORS: true },
                jsPDF:        { unit: 'in', format: 'letter', orientation: 'portrait' },
                pagebreak:    { mode: ['css', 'legacy'] }
            };
            window.html2pdf().set(opt).from(form).save();
        });
    };
})();
