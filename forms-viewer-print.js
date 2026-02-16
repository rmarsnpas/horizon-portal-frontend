// jsPDF CDN loader and print/save logic for forms-viewer.html
(function() {
    // Load jsPDF from CDN if not present
    function loadJsPDF(callback) {
        if (window.jspdf) return callback();
        var script = document.createElement('script');
        script.src = 'https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js';
        script.onload = callback;
        document.head.appendChild(script);
    }
    // Print all forms
    window.printAllForms = function() {
        window.print();
    };
    // Save all forms as PDF
    window.saveAllFormsAsPDF = function() {
        loadJsPDF(function() {
            const { jsPDF } = window.jspdf;
            const doc = new jsPDF();
            const container = document.querySelector('.container');
            doc.html(container, {
                callback: function (doc) {
                    doc.save('intake-package.pdf');
                },
                x: 10,
                y: 10,
                width: 180
            });
        });
    };
    // Save individual form as PDF
    window.saveFormAsPDF = function(formId) {
        loadJsPDF(function() {
            const { jsPDF } = window.jspdf;
            const doc = new jsPDF();
            const form = document.getElementById('form-' + formId);
            doc.html(form, {
                callback: function (doc) {
                    doc.save(formId + '.pdf');
                },
                x: 10,
                y: 10,
                width: 180
            });
        });
    };
})();
