<br />
<div id="errorText"><span style="color:red">File upload error:</span> Please make sure the file you are uploading is either a PDF, Word Document or similar format.</div>
<iframe id="fileIframe_{$recordID|strip_tags}_{$indicatorID|strip_tags}_{$series|strip_tags}" style="display: none" src="ajaxIframe.php?a=getuploadprompt&amp;recordID={$recordID|strip_tags}&amp;indicatorID={$indicatorID|strip_tags}&amp;series={$series|strip_tags}" frameborder="0" width="500px" height="85px"></iframe>
<button type="button" id="fileError" class="buttonNorm" onclick="$('#errorText').css('display', 'none'); $('#fileIframe_{$recordID|strip_tags}_{$indicatorID|strip_tags}_{$series|strip_tags}').css('display', 'block'); $('#fileError').css('visibility', 'hidden')"><img src="dynicons/?img=edit-redo.svg&amp;w=32" />Try Uploading Again</button>