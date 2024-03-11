<link rel=stylesheet href="<!--{$app_js_path}-->/codemirror/addon/merge/merge.css">
<link rel="stylesheet" href="<!--{$app_js_path}-->/codemirror/theme/lucario.css">
<link rel="stylesheet" href="./css/mod_templates_reports.css">
<script src="<!--{$app_js_path}-->/diff-match-patch/diff-match-patch.js"></script>
<script src="<!--{$app_js_path}-->/codemirror/addon/merge/merge.js"></script>

<div class="leaf-center-content">
    <div class="page-title-container">
        <h2>LEAF Programmer</h2>
        <button type="button" id="mobileToolsNavBtn" onclick="applyRightNavShowClass(true)">
            Template Tools
        </button>
    </div>
    <div class="page-main-content">
        <div class="leaf-left-nav">
            <aside class="sidenav" id="fileBrowser">
                <button type="button" class="new-report usa-button" onclick="newReport();">
                    New File
                </button>
                <button type="button" id="btn_history" class="usa-button usa-button--outline" onclick="viewHistory()">
                    View History
                </button>
                <div id="fileList"></div>
            </aside>
        </div>

        <main id="codeArea" class="main-content">
            <div id="codeContainer" class="leaf-code-container">
                <div id="filename"></div>
                <div id="reportURL"></div>
                <div>
                    <div class="compared-label-content">
                        <div class="CodeMirror-merge-pane-label-left">(Old File)</div>
                        <div class="CodeMirror-merge-pane-label-right">(Current File)</div>
                    </div>
                    <textarea id="code"></textarea>
                    <div id="codeCompare"></div>
                </div>
                <div class="keyboard_shortcuts">
                    <h3 class="keboard_shortcuts_main_title">Keyboard Shortcuts within the Code Editor:</h3>
                    <div class="keyboard_shortcuts_section">
                        <div class="keboard_shortcuts_box">
                            <div class="keyboard_shortcuts_title">
                                <h3>Save: </h3>
                            </div>
                            <div class="keyboard_shortcut">
                                <p>Ctrl + S </p>
                            </div>
                        </div>
                        <div class="keboard_shortcuts_box">
                            <div class="keyboard_shortcuts_title">
                                <h3>Undo: </h3>
                            </div>
                            <div class="keyboard_shortcut">
                                <p>Ctrl + Z </p>
                            </div>
                        </div>
                    </div>
                    <div class="keyboard_shortcuts_section">
                        <div class="keboard_shortcuts_box">
                            <div class="keyboard_shortcuts_title">
                                <h3>Full Screen: </h3>
                            </div>
                            <div class="keyboard_shortcut">
                                <p>F11 </p>
                            </div>
                        </div>
                        <div class="keboard_shortcuts_box"></div>
                    </div>
                </div>

                <div class="keyboard_shortcuts_merge">
                    <h3 class="keboard_shortcuts_main_title">Keyboard Shortcuts For Compare Code:</h3>
                    <div class="keyboard_shortcuts_section_merge">
                        <div class="keboard_shortcuts_box_merge">
                            <div class="keyboard_shortcuts_title_merge">
                                <h3>Merge Changes: </h3>
                            </div>
                            <div class="keyboard_shortcut_merge">
                                <p>Ctrl + M </p>
                            </div>
                        </div>
                        <div class="keboard_shortcuts_box_merge">
                            <div class="keyboard_shortcuts_title_merge">
                                <h3>Exit Compare: </h3>
                            </div>
                            <div class="keyboard_shortcut_merge">
                                <p>Ctrl + E </p>
                            </div>
                        </div>

                    </div>
                </div>
            </div>
        </main>

        <div class="leaf-right-nav">
            <button type="button" id="closeMobileToolsNavBtn" aria-label="close"
                    onclick="applyRightNavShowClass(false)">X</button>
            <aside class="filesMobile">
            </aside>
            <aside class="sidenav-right" id="controls">
                <button type="button" id="save_button" class="usa-button"
                    onclick="save();">Save Changes<span class="saveStatus"></span>
                </button>
                <button type="button" id="open_file_button"
                    class="usa-button usa-button--accent-cool leaf-btn-med" onclick="
                    runReport();">Open File</button>
                <button type="button" class="new-report mobile_new_report_btn usa-button" onclick="newReport();">
                    New File
                </button>
                <button type="button" id="deleteButton"
                    class="usa-button usa-button--secondary" onclick="
                    deleteReport();">Delete File
                </button>
                <button type="button"
                    class="usa-button usa-button--outline mobileHistory"
                    id="btn_history_mobile" onclick="viewHistory()">
                    View History
                </button>
                <button type="button"
                    class="usa-button usa-button--secondary"
                    id="btn_compareStop" style="display: none" onclick="stop_comparing();">
                    Stop Comparing
                </button>
            </aside>
            <aside class="sidenav-right-compare">
                <div class="controls-compare">
                    <button type="button" class="file_replace_file_btn usa-button usa-button--secondary">Use Old File</button>
                    <button type="button" type="button" onclick="exitExpandScreen()"
                        class="close_expand_mode_screen usa-button usa-button--outline">Stop Comparing</button>
                </div>
            </aside>
            <div class="file-history">
                <h3>File History</h3>
                <div class="file-history-res"></div>
            </div>
        </div>
    </div>

</div>


<!--{include file="site_elements/generic_xhrDialog.tpl"}-->
<!--{include file="site_elements/generic_confirm_xhrDialog.tpl"}-->
<!--{include file="site_elements/generic_dialog.tpl"}-->


<script>
    function applyRightNavShowClass(showNav = false) {
        let nav = $('.leaf-right-nav');
        showNav ? nav.addClass('show') : nav.removeClass('show');
    }

    // saves current file content changes
    function save() {
        let data = '';
        if (typeof codeEditor.edit !== 'undefined' && typeof codeEditor.edit.getValue === 'function') {
            data = codeEditor.edit.getValue();
        } else if (typeof codeEditor.getValue === 'function') {
            data = codeEditor.getValue();
        }

        if (data === currentFileContent) {
            alert('There are no changes to save.');
            return;
        }

        $.ajax({
            type: 'POST',
            data: {
                CSRFToken: '<!--{$CSRFToken}-->',
                file: data
            },
            url: '../api/applet/_' + currentFile,
            success: function(res) {
                $('.modifiedTemplate').css('display', 'block');
                if ($('#btn_compareStop').css('display') != 'none') {
                    $('#btn_compare').css('display', 'none');
                }

                var time = new Date().toLocaleTimeString();
                $('.saveStatus').html('<br /> Last saved: ' + time);
                currentFileContent = data;
                if (res != null) {
                    alert(res);
                }
                saveFileHistory();
            },
            error: function() {
                alert('An error occurred while saving the file.');
            }
        });
    }
    // creates a copy of the current file content
    function saveFileHistory() {
        $.ajax({
            type: 'POST',
            data: {
                CSRFToken: '<!--{$CSRFToken}-->',
                file: codeEditor.getValue()
            },
            url: '../api/applet/fileHistory/_' + currentFile,
            success: function(res) {
                getFileHistory(currentFile);
            }
        });
    }

    // Retreave URL to display comparison of files
    function initializePage() {
        let urlParams = new URLSearchParams(window.location.search);
        let fileName = urlParams.get('fileName');
        let parentFile = urlParams.get('parentFile');
        let templateFile = urlParams.get('file');

        if (fileName && parentFile != undefined) {
            loadContent(templateFile);
            compareHistoryFile(fileName, parentFile, false);
        } else if (templateFile != undefined) {
            loadContent(templateFile);
        } else {
            loadContent('example');
        }
        // A shortcut for changing the theme
        $(document).on('keydown', function(event) {
            if (event.ctrlKey && event.key === 'b' && typeof codeEditor.setOption === 'function') {
                const newTheme = codeEditor.options.theme === 'default' ? 'lucario' : 'default';
                codeEditor.setOption('theme', newTheme);
            }
        });
    }
    // Expands the current and history file to compare both files
    function editorExpandScreen() {
        $('.page-title-container > .file_replace_file_btn').show();
        $('.page-title-container > .close_expand_mode_screen').show();
        $('.sidenav-right').hide();
        $('.filesMobile').hide();
        $('.sidenav-right-compare').show();
        $('.page-title-container > h2').css({
            'text-align': 'left'
        });
        $('.page-title-container>h2').html('LEAF Programmer > Compare Code');
        applyRightNavShowClass(false);
        $('.usa-table').hide();
        $('.leaf-left-nav').css({
            position: 'fixed',
            left: '-100%',
            transition: 'all .5s ease'
        });
        $('.page-title-container').css({
            'flex-direction': 'row'
        });
        $('.keyboard_shortcuts').css('display', 'none');
        $('.keyboard_shortcuts_merge').show();
    }
    // exits the current and history comparison
    function exitExpandScreen() {
        $('.compared-label-content').css('display', 'none');
        $('.page-title-container > .file_replace_file_btn').hide();
        $('.page-title-container > .close_expand_mode_screen').hide();
        $('#save_button_compare').css('display', 'none');
        $('.sidenav-right-compare').hide();
        $('.sidenav-right').show();
        $('.page-title-container > h2').css({
            width: '100%',
            'text-align': 'left'
        });
        $('.page-title-container>h2').html('LEAF Programmer');
        applyRightNavShowClass(false);
        $('#codeContainer').css({
            display: 'block'
        });
        $('.usa-table').show();

        $('.leaf-left-nav').css({
            position: 'relative',
            left: '0'
        });
        $('.page-title-container').css({
            'flex-direction': 'row'
        });

        $('.keyboard_shortcuts').css('display', 'flex');
        $('.keyboard_shortcuts_merge').hide();
        $('#save_button').css('display', 'block');


        // Will reset the URL
        const url = new URL(window.location.href);
        url.searchParams.delete('fileName');
        url.searchParams.delete('parentFile');
        window.history.replaceState(null, null, url.toString());

        loadContent(currentFile);
    }
    // creates a new report
    function newReport() {
        dialog.setTitle('New File');
        dialog.setContent('<label for="newFilename">Filename: </label><input type="text" id="newFilename">');

        $('#newFilename').on('keyup', function(e) {
            $(this).val($(this).val().replace(/[^a-z0-9\.\/]/gi, '_'));
        });

        dialog.setSaveHandler(function() {
            let file = $('#newFilename').val();
            $.ajax({
                type: 'POST',
                url: '../api/applet',
                data: {
                    CSRFToken: '<!--{$CSRFToken}-->',
                    filename: file
                },
                success: function(res) {
                    if (res === 'CreateOK') {
                        updateFileList();
                        loadContent(file);
                    } else {
                        alert(res);
                    }
                }
            });
            dialog.hide();
        });

        dialog.show();
    }
    // deletes the report
    function deleteReport() {
        dialog_confirm.setTitle('Are you sure?');
        dialog_confirm.setContent('This will irreversibly delete this report.');

        dialog_confirm.setSaveHandler(function() {
            $.ajax({
                type: 'DELETE',
                url: '../api/applet/_' + currentFile + '?' +
                    $.param({'CSRFToken': '<!--{$CSRFToken}-->'}),
                    success: function() {
                        location.reload();
                    }
            });
            deleteHistoryFileReport(currentFile);
            dialog_confirm.hide();
        });

        dialog_confirm.show();
        // Will reset the URL
        const url = new URL(window.location.href);
        url.searchParams.delete('file');
        window.history.replaceState(null, null, url.toString());
    }
    // deletes the history file report when the original report has been deleted
    function deleteHistoryFileReport(templateFile) {
        $.ajax({
            type: 'DELETE',
            url: '../api/applet/deleteHistoryFileReport/_' + templateFile + '?' +
                $.param({'CSRFToken': '<!--{$CSRFToken}-->'}),
                success: function() {
                    location.reload();
                }
        });
    }
    // opens the report on a new page
    function runReport() {
        window.open('../report.php?a=' + currentFile);
    }

    function isExcludedFile(file) {
        if (file === 'example' || file.substr(0, 5) === 'LEAF_') {
            return true;
        }
        return false;
    }
    // gloabal variables
    var codeEditor;
    var currentFile = '';
    var unsavedChanges = false;
    var currentFileContent = '';
    var dialog, dialog_confirm;

    var ignoreUnsavedChanges = false;
    var ignorePrompt = true;

    // request's copies of the current file content in an accordion layout
    function getFileHistory(template) {
        console.log(template)
        $.ajax({
            type: 'GET',
            url: '../api/templateFileHistory/_' + template,
            dataType: 'json',
            success: function(res) {
                if (res.length === 0) {
                    var contentMessage = '<p class="contentMessage">There are no history files.</p>';
                    $('.file-history-res').html(contentMessage);
                    return;
                }

                var fileNames = res.map(function(template) {
                    return template.file_parent_name;
                });

                if (fileNames.indexOf(template) === -1) {
                    alert('Template file not found in directory');
                    return;
                }

                var accordion = '<div id="file_history_container">' +
                    '<div class="file_history_titles">' +
                    '<div class="file_history_date">Date:</div>' +
                    '<div class="file_history_author">Author:</div>' +
                    '</div>' +
                    '<div class="file_history_options_container">';
                for (var i = 0; i < res.length; i++) {
                    var fileParentName = res[i].file_parent_name;
                    var fileName = res[i].file_name;
                    var whoChangedFile = res[i].file_modify_by;
                    var fileCreated = res[i].file_created;
                    ignoreUnsavedChanges = false;

                    accordion +=
                        '<div class="file_history_options_wrapper" onclick="compareHistoryFile(\'' +
                        fileName + '\', \'' + fileParentName + '\', true)">' +
                        '<div class="file_history_options_date">' + fileCreated + '</div>' +
                        '<div class="file_history_options_author">' + whoChangedFile + '</div>' +
                        '</div>';
                }
                accordion += '</div>' +
                    '</div>';
                $('.file-history-res').html(accordion);

            },
            error: function(xhr, status, error) {
                console.log('Error getting file history: ' + error);
            },
            cache: false,
        });
    }
    // compares current file content with history file from getFileHistory()
    function compareHistoryFile(fileName, parentFile, updateURL) {
        $('.CodeMirror').remove();
        $('#codeCompare').empty();
        $('#btn_compare').css('display', 'none');
        $('#save_button').css('display', 'none');
        $('#btn_compareStop').css('display', 'none');
        $('#btn_merge').css('display', 'block');
        $('.save_button').css('display', 'none');
        $('.file_replace_file_btn').css('display', 'block');

        $.ajax({
            type: 'GET',
            url: '../api/templateCompareFileHistory/_' + fileName,
            dataType: 'json',
            cache: false,
            success: function(res) {
                $(".compared-label-content").css("display", "flex");
                var filePath = '';
                var fileParentFile = '';
                for (var i = 0; i < res.length; i++) {
                    filePath = res[i].file_path;
                    fileParentFile = res[i].file_parent_name;
                    $.ajax({
                        type: 'GET',
                        url: filePath,
                        dataType: 'text',
                        cache: false,
                        success: function(fileContent) {
                            codeEditor = CodeMirror.MergeView(document.getElementById(
                                "codeCompare"), {
                                value: currentFileContent.replace(/\r\n/g, "\n"),
                                origLeft: fileContent.replace(/\r\n/g, "\n"),
                                lineNumbers: true,
                                mode: 'htmlmixed',
                                collapseIdentical: true,
                                lineWrapping: false, // initial value
                                autoFormatOnStart: true,
                                autoFormatOnMode: true,
                                leftTitle: "Current File",
                                rightTitle: "Comparison File"
                            });
                            updateEditorSize();
                            $('.CodeMirror-linebackground').css({
                                'background-color': '#8ce79b !important'
                            });

                            // Add a shortcut for exit from the merge screen
                            $(document).on('keydown', function(event) {
                                if (event.ctrlKey && event.key === 'm') {
                                    mergeFile();
                                }
                                if (event.ctrlKey && event.key === 'w') {
                                    toggleWordWrap();
                                }
                            });

                            function mergeFile() {
                                ignoreUnsavedChanges = true;
                                let changedLines = codeEditor.leftOriginal().lineCount();
                                let mergedContent = "";
                                for (let i = 0; i < changedLines; i++) {
                                    let mergeLine = codeEditor.leftOriginal().getLine(
                                        i);
                                    if (mergeLine !== null && mergeLine !== undefined) {
                                        mergedContent += mergeLine + "\n";
                                    }
                                }
                                saveMergedChangesToFile(fileParentFile, mergedContent);
                            }



                            $('.file_replace_file_btn').click(function() {
                                ignoreUnsavedChanges = true;
                                let changedLines = codeEditor.leftOriginal()
                                    .lineCount();
                                let mergedContent = "";
                                for (let i = 0; i < changedLines; i++) {
                                    let mergeLine = codeEditor.leftOriginal().getLine(
                                        i);
                                    if (mergeLine !== null && mergeLine !== undefined) {
                                        mergedContent += mergeLine + "\n";
                                    }
                                }

                                saveMergedChangesToFile(fileParentFile, mergedContent);
                            });

                            function toggleWordWrap() {
                                let lineWrapping = codeEditor.editor().getOption(
                                    'lineWrapping');
                                codeEditor.editor().setOption('lineWrapping', !lineWrapping);
                                codeEditor.leftOriginal().setOption('lineWrapping', !
                                    lineWrapping);
                            }
                        }
                    });
                }
                editorExpandScreen();
            }
        });

        if (updateURL !== null) {
            let url = new URL(window.location.href);
            url.searchParams.set('fileName', fileName);
            url.searchParams.set('parentFile', parentFile);
            window.history.replaceState(null, null, url.toString());
        }
    }

    // Add a shortcut for exit from the merge screen
    $(document).on('keydown', function(event) {
        if (event.ctrlKey && event.key === 'e') {
            exitExpandScreen();
        }
    });

    // overrites current file content after merge
    function saveMergedChangesToFile(fileParentName, mergedContent) {
        $.ajax({
                type: 'POST',
                url: '../api/applet/mergeFileHistory/saveReportMergeTemplate/_' + fileParentName,
                data: {CSRFToken: '<!--{$CSRFToken}-->',
                file: mergedContent
            },
            dataType: 'json',
            cache: false,
            success: function(res) {
                exitExpandScreen();
            },
            error: function(xhr, status, error) {
                console.log(xhr.responseText);
            }
        });
    }
    // This function displays a prompt if there are unsaved changes before leaving the page
    function editorCurrentContent() {
        $(window).on('beforeunload', function(e) {
            if (!ignoreUnsavedChanges && !ignorePrompt) { // Check if ignoring unsaved changes and prompt
                // Bypass the prompt if the file name contains "LEAF_"
                if (currentFile && currentFile.includes('LEAF_')) {
                    return;
                }

                let data = '';
                if (codeEditor.getValue === undefined) {
                    data = codeEditor.edit.getValue();
                } else {
                    data = codeEditor.getValue();
                }
                if (currentFileContent !== data) {
                    let confirmationMessage = 'You have unsaved changes. Are you sure you want to leave this page?';
                    return confirmationMessage;
                }
            }
        });
    }
    //loads all files and retreave's them
    function loadContent(file) {
        if (file === undefined) {
            console.error('No file specified. File cannot be loaded.');
            $('#codeContainer').html('Error: No file specified. File cannot be loaded.');
            return;
        }

        // Check if the file name contains "LEAF_"
        const isLeafFile = file.includes('LEAF_');

        if (ignorePrompt) {
            ignorePrompt = false; // Reset ignorePrompt flag
        } else {
            // If the file is not a "LEAF_" file, and there are unsaved changes, show the prompt
            if (!isLeafFile && !ignoreUnsavedChanges && hasUnsavedChanges() && !confirm('You have unsaved changes. Are you sure you want to leave this page?')) {
                return;
            }
        }

        $('.CodeMirror').remove();
        $('#codeCompare').empty();
        $('#btn_compareStop').css('display', 'none');
        $('.keyboard_shortcuts_merge').hide();

        currentFile = file;
        initEditor();
        $('#codeContainer').css('display', 'none');
        $('#controls').css('visibility', 'visible');
        $('#filename').html(file.replace('.tpl', ''));
        let reportURL = `${window.location.origin}${window.location.pathname.replace('admin/', '')}report.php?a=${file.replace('.tpl', '')}`;
        $('#reportURL').html(`URL: <a href="${reportURL}" target="_blank">${reportURL}</a>`);
        $('#controls').css('visibility', isExcludedFile(file) ? 'hidden' : 'visible');
        $.ajax({
            type: 'GET',
            url: `../api/applet/_${file}`,
            success: function(res) {
                $('#codeContainer').fadeIn();

                // Check if codeEditor is already defined and has a setValue method
                if (codeEditor && typeof codeEditor.setValue === 'function') {
                    codeEditor.setValue(res.file);
                } else {
                    console.error('codeEditor is not properly initialized.');
                }
                currentFileContent = codeEditor.getValue();

                if (res.modified === 1) {
                    $('.modifiedTemplate').css('display', 'block');
                } else {
                    $('.modifiedTemplate').css('display', 'none');
                }

                getFileHistory(file);
            },
            error: function(xhr, status, error) {
                console.log('Error loading file: ' + error);
            },
            cache: false
        });
        $('.saveStatus').html('');

        editorCurrentContent();

        codeEditor.on('change', function() {
            unsavedChanges = true;
        });

        // Shortcuts for undo, save, and full screen functionality
        codeEditor.setOption('extraKeys', {
            'Ctrl-Z': function(cm) {
                cm.undo();
            },
            'Ctrl-S': function(cm) {
                save();
            },
            'Ctrl-W': function(cm) {
                cm.setOption('lineWrapping', !cm.getOption('lineWrapping'));
            },
            'F11': function(cm) {
                cm.setOption('fullScreen', !cm.getOption('fullScreen'));
            }
        });

        function hasUnsavedChanges() {
            let data = '';
            if (codeEditor.getValue === undefined) {
                data = codeEditor.edit.getValue();
            } else {
                data = codeEditor.getValue();
            }
            return currentFileContent !== data;
        }

        if (!isLeafFile && file !== undefined) {
            let url = new URL(window.location.href);
            url.searchParams.set('file', file);
            window.history.replaceState(null, null, url.toString());
        }
    }
    // initiates  the loadContent()
    function initEditor() {
        codeEditor = CodeMirror.fromTextArea(document.getElementById("code"), {
            mode: "htmlmixed",
            lineNumbers: true,
            indentUnit: 4,
            extraKeys: {
                "F11": function(cm) {
                    cm.setOption("fullScreen", !cm.getOption("fullScreen"));
                },
                "Esc": function(cm) {
                    if (cm.getOption("fullScreen")) cm.setOption("fullScreen", false);
                },
                "Ctrl-S": function(cm) {
                    save();
                },
                "Ctrl-W": function(cm) {
                    cm.setOption("lineWrapping", !cm.getOption("lineWrapping"));
                }
            }
        });
        updateEditorSize();
    }

    function updateEditorSize() {
        codeWidth = $('#codeArea').width() - 30;
       // $('#codeContainer').css('width', codeWidth + 'px');
        $('.CodeMirror, .CodeMirror-merge').css('height', $(window).height() - 160 + 'px');
    }
    // example report templates
    function updateFileList() {

        $.ajax({
            type: 'GET',
            url: '../api/applet',
            success: function (res) {
                let buffer = '<ul class="leaf-ul reports">';
                let bufferExamples = '<div class="leaf-bold">Examples</div><ul class="leaf-ul">';
                let filesMobile = '<label for="template_file_select">Template Files:</label><select id="template_file_select">';
                
                for (let i in res) {
                    let file = res[i].replace('.tpl', '');
                    
                    if (!isExcludedFile(file)) {
                        buffer += '<li><a href="#" data-file="' + file + '">' + file + '</a></li>';
                        filesMobile += '<option value="' + file + '"><div class="template_files">' + file + '</div></option>';
                    } else {
                        bufferExamples += '<li><a href="#" data-file="' + file + '">' + file + '</a></li>';
                    }
                }
                
                buffer += '</ul>';
                bufferExamples += '</ul>';
                filesMobile += '</select>';
                
                $('#fileList').html(buffer + bufferExamples);
                $('.filesMobile').html(filesMobile);
                
                // Attach click event handler to template links in the buffer
                $('#fileList a').on('click', function(e) {
                    e.preventDefault();
                    let selectedFile = $(this).data('file');
                    loadContent(selectedFile);
                    window.scrollTo(0,0);
                });
                
                $('#template_file_select').on('change', function () {
                    let selectedFile = event.currentTarget.value
                    loadContent(selectedFile);
                });
            },
            cache: false
        });

    }
    // Displays  user's history when creating, merge, and so on
    function viewHistory() {
        dialog_message.setContent('');
        dialog_message.setTitle('Access Template History');
        dialog_message.show();
        dialog_message.indicateBusy();
        applyRightNavShowClass(false);
        $.ajax({
            type: 'GET',
            url: 'ajaxIndex.php?a=gethistory&type=applet&id=' + currentFile,
            dataType: 'text',
            success: function(res) {
                dialog_message.setContent(res);
                dialog_message.indicateIdle();
                dialog_message.show();
            },
            fail: function() {
                dialog_message.setContent('Loading failed.');
                dialog_message.show();
            },
            cache: false
        });
    }

    // loads components when the document loads
    $(document).ready(function() {
        initEditor();
        $('.sidenav-right-compare').hide();
        dialog = new dialogController('xhrDialog', 'xhr', 'loadIndicator', 'button_save',
            'button_cancelchange');
        dialog_confirm = new dialogController('confirm_xhrDialog', 'confirm_xhr', 'confirm_loadIndicator',
            'confirm_button_save', 'confirm_button_cancelchange');

        initializePage();
        updateFileList();

        dialog_message = new dialogController('genericDialog', 'genericDialogxhr', 'genericDialogloadIndicator',
            'genericDialogbutton_save', 'genericDialogbutton_cancelchange');
    });
</script>