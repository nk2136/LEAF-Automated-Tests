<style>
body {
    min-width: fit-content;
}
h2, h3 {
    margin: 0.5rem 0;
}
button.buttonNorm {
    font-size: 1rem;
    padding: 0.25rem 0.5rem;
    border-radius: 2px;
}
button.buttonNorm:focus, button.buttonNorm:active {
    border: 1px solid black !important;
}
#bodyarea {
    width: fit-content;
    padding: 1rem;
}
.grid_table {
    margin-bottom: 4rem;
}
.updates_output {
    margin: 1rem 0;
}
#section3 {
    padding: 0.5rem;
    background-color: white;
}
#queue_completed {
    color: #085;
}
div [id^="LeafFormGrid"] {
    max-width: 850px;
}
div [id^="LeafFormGrid"] table {
    background-color: white;
    margin: 0.5rem 0;
    width: 100%;
}
#account_input_area {
    display: flex;
}
.card {
    min-width: 325px;
    width: 50%;
    border: 1px solid rgb(44, 44, 44);
    border-radius: 3px;
    padding: 0.75rem; 
}

#employeeSelector div[id$="_border"], #newEmployeeSelector div[id$="_border"] {
    height: 30px;
}
.card:first-child {
    margin-right: 10px;
}
@media only screen and (max-width: 550px) {
    #account_input_area {
        flex-direction: column;
    }
    .card {
        width: 90%;
    }
    .card:first-child {
        margin-right: 0;
        margin-bottom: 10px;
    }
}
</style>

<h2>New Account Updater</h2>
<p style="max-width: 850px;">
This utility will restore access for people who have been asigned a new Active Directory account.
It can be used to update the initiator of requests created under the old account, update the content of
orgchart employee format questions to refer to the new account, and update group memberships.
</p>
<br/>

<script src="<!--{$orgchartPath}-->/js/nationalEmployeeSelector.js"></script>
<script src="../../libs/js/LEAF/intervalQueue.js"></script>
<link rel="stylesheet" type="text/css" href="<!--{$orgchartPath}-->/css/employeeSelector.css" />

<script>
const CSRFToken = '<!--{$CSRFToken}-->';
const APIroot = '<!--{$APIroot}-->';

function resetEntryFields(empSel, empSelNew) {
    empSel.clearSearch();
    empSelNew.clearSearch();
    $('#oldAccountName').html('');
    $('#newAccountName').html('');

    $('#grid_initiator').html('');
    $('#grid_orgchart_employee').html('');
    $('#grid_groups_info').html('');

    $('#section1').css('display', 'block');
    $('#section2').css('display', 'none');
}
    
function reassignInitiator(item) {
    return new Promise ((resolve, reject) => {
        const { recordID, newAccount } = item;

        let formData = new FormData();
        formData.append('CSRFToken', CSRFToken);
        formData.append('initiator', newAccount);

        fetch(`${APIroot}form/${recordID}/initiator`, {
            method: 'POST',
            body: formData
        }).then(() => {
            $('#section3 #initiators_updated').append(`Request # ${recordID} reassigned to ${newAccount}<br />`);
            resolve('updated')
        }).catch(err => {
            console.log(err);
            reject(err);
        });
    });
}

function updateOrgEmployeeData(item) {
    return new Promise ((resolve, reject) => {
        const { recordID, indicatorID, newEmpUID, newAccount } = item;

        let formData = new FormData();
        formData.append('CSRFToken', CSRFToken);
        formData.append(`${indicatorID}`, newEmpUID);
        
        fetch(`${APIroot}form/${recordID}`, {
            method: 'POST',
            body: formData
        }).then(() => {
            $('#section3 #orgchart_employee_updated').append(`Request # ${recordID}, indicator ${indicatorID} reassigned to ${newAccount}(${newEmpUID})<br />`);
            resolve('updated')
        }).catch(err => {
            console.log(err);
            reject(err);
        });
    });
}

function searchGroupsOldAccount(accountAndTaskInfo, queue) {
    const { oldAccount } = accountAndTaskInfo;
    return new Promise ((resolve, reject) => {
        //all groups and members
        fetch(`${APIroot}group/members`)
            .then(res => res.json())
            .then(data => {
                let groupInfo = {};
                //groups associated with old account
                const selectedAccountGroups = data.filter(g => g.members.some(m => m.userName === oldAccount));
                selectedAccountGroups.forEach(g => {
                    const memberSettings = g.members.find(m => m.userName === oldAccount);
                    if (parseInt(memberSettings.active) === 1) {
                        groupInfo[`group_${g.groupID}`] = {
                            ...g,
                            memberSettings
                        };
                    }
                });

                if (Object.keys(groupInfo).length > 0) {
                    let recordIDs = '';
                    for (let i in groupInfo) {
                        recordIDs += groupInfo[i].groupID + ',';
                    }
                    const formGrid = new LeafFormGrid('grid_groups_info', {});

                    formGrid.setRootURL('../');
                    formGrid.enableToolbar();
                    formGrid.hideIndex();
                    formGrid.setDataBlob(groupInfo);
                    formGrid.setHeaders([
                        {
                            name: 'Group Name',
                            indicatorID: 'groupName',
                            editable: false,
                            callback: function(data, blob) {
                                $('#'+data.cellContainerID).html(blob[`group_${data.recordID}`]?.name);
                            }
                        },
                        {
                            name: 'Current Group Member Username',
                            indicatorID: 'groupMember',
                            editable: false,
                            callback: function(data, blob) {
                                const k = `group_${data.recordID}`;
                                const isLocal = parseInt(blob[k]?.memberSettings?.locallyManaged) === 1;
                                const username = blob[k]?.memberSettings.userName;
                                $('#'+data.cellContainerID).html(`${username}${isLocal ? ' (local)' : ' (non-local)'}`);
                            }
                        }
                    ]);
                    formGrid.loadData(recordIDs);

                    accountAndTaskInfo.taskType = 'update_group_membership';
                    enqueueTask(groupInfo, accountAndTaskInfo, queue);
                    resolve(groupInfo);
                } else {
                    $('#grid_initiator').append('No records found');
                }

        }).catch(err => {
            console.log(err);
            reject(err);
        });
    });
}

function addUserToGroup(item) {
    //NOTE: TODO: regional vs local?  active only?
    //are there groups that should be excluded?  eg group 1?
    return new Promise ((resolve, reject) => {
        const { locallyManaged, userAccountGroupID, newAccount } = item;

        if (parseInt(locallyManaged) === 1) {
            let formData = new FormData();
            formData.append('CSRFToken', CSRFToken);
            formData.append('userID', newAccount);

            fetch(`${APIroot}group/${userAccountGroupID}/members`, {
                method: 'POST',
                body: formData
            }).then((res) => {
                $('#section3 #groups_updated').append(`${newAccount} added to ${userAccountGroupID}<br />`);
                resolve('updated')
            }).catch(err => {
                console.log(err);
                reject(err);
            });
        } else {
            console.log('not locally managed, add to nexus?');
        }
    });
}

function enqueueTask(res = {}, accountAndTaskInfo = {}, queue = {}) {
    let count = 0;
    for(let recordID in res) {
        const item = {
            ...accountAndTaskInfo,
            recordID: /^group_/.test(recordID) ? 0 : recordID,
            indicatorID: res[recordID]?.indicatorID || 0,
            userAccountGroupID: /^group_/.test(recordID) ? res[recordID].groupID : 0,
            locallyManaged: res[recordID]?.memberSettings?.locallyManaged || null,
            regionallyManaged: res[recordID]?.memberSettings?.regionallyManaged || null,
        }
        queue.push(item);
        count += 1;
    }
    console.log(`queued ${count} task${count > 1 ? 's' : ''}`);
}

function processTask(item) {
    switch(item.taskType) {
        case 'update_initiator':
            return reassignInitiator(item);
        case 'update_orgchart_employee_field':
            return updateOrgEmployeeData(item);
        case 'update_group_membership':
            return addUserToGroup(item);
        default:
            console.log('hit default', item);
            return 'default case';
            break;
    }
}

function findAssociatedRequests(empSel, empSelNew) {
    const oldEmpUID = empSel?.selection;
    const newEmpUID = empSelNew?.selection;

    const oldAccount = empSel?.selectionData[oldEmpUID]?.userName || '';
    const newAccount = empSelNew?.selectionData[newEmpUID]?.userName || '';
	if(oldAccount === '' || newAccount === '' || oldAccount === newAccount) {
        alert('Invalid selections');
        return;
    }

    let accountAndTaskInfo = {
        oldAccount,
        newAccount,
        oldEmpUID,
        newEmpUID,
        taskType: ''
    }

    $('#section1').css('display', 'none');
    $('#section2').css('display', 'block');
    $('#oldAccountName').html(oldAccount);
    $('#newAccountName').html(newAccount);

    const queue = new intervalQueue();
    queue.setConcurrency(3);

    let calls = [];

    const queryInitiator = new LeafFormQuery();
    queryInitiator.setRootURL('../');
    queryInitiator.addTerm('userID', '=', oldAccount);
    queryInitiator.onSuccess(function(res) {
        if (res instanceof Object && Object.keys(res).length > 0) {
            let recordIDs = '';
            for (let i in res) {
                recordIDs += res[i].recordID + ',';
            }
            /*Passing empty object 2nd param prevents the formGrid from instantiating a LeafForm class. 
            The class is not needed here, and also has hardcoded references to images in libs, which causes errors*/
            const formGrid = new LeafFormGrid('grid_initiator', {});
            formGrid.setRootURL('../');
            formGrid.enableToolbar();
            formGrid.hideIndex();
            formGrid.setDataBlob(res);
            formGrid.setHeaders([
                {
                    name: 'UID',
                    indicatorID: 'uid',
                    editable: false,
                    callback: function(data, blob) {
                        const link = `<a href="../index.php?a=printview&recordID=${data.recordID}" target="_blank">${data.recordID}</a>`
                        $('#'+data.cellContainerID).html(link);
                    }
                },
                {
                    name: 'Title',
                    indicatorID: 'title',
                    callback: function(data, blob) {
                        $('#'+data.cellContainerID).html(blob[data.recordID].title);
                        $('#'+data.cellContainerID).on('click', function() {
                            window.open('../index.php?a=printview&recordID='+data.recordID, 'LEAF', 'width=800,resizable=yes,scrollbars=yes,menubar=yes');
                        });
                }},
                {
                    name: 'Current Initiator Account',
                    indicatorID: 'initiator',
                    editable: false,
                    callback: function(data, blob) {
                        $('#'+data.cellContainerID).html(blob[data.recordID].userID);
                }}
            ]);
            formGrid.loadData(recordIDs);

            accountAndTaskInfo.taskType = 'update_initiator';
            enqueueTask(res, accountAndTaskInfo, queue);
        } else {
            $('#grid_initiator').append('No records found');
        }
    });
    calls.push(queryInitiator.execute());
    
    /* *********************************************************************************** */
    
    const queryOrgchartEmployee = new LeafFormQuery();
    queryOrgchartEmployee.setRootURL('../');
    queryOrgchartEmployee.importQuery({
        "terms":[
            {"id":"data","indicatorID":"0.0","operator":"=","match": oldEmpUID,"gate":"AND"},
            {"id":"deleted","operator":"=","match":0,"gate":"AND"}
        ],
        "joins":["service"],
        "sort":{}
    });
    queryOrgchartEmployee.onSuccess(function(res) {
        if (res instanceof Object && Object.keys(res).length > 0) {
            let recordIDs = '';
            for (let i in res) {
                recordIDs += res[i].recordID + ',';
            }
            const formGrid = new LeafFormGrid('grid_orgchart_employee', {});
            formGrid.setRootURL('../');
            formGrid.enableToolbar();
            formGrid.hideIndex();
            formGrid.setDataBlob(res);
            formGrid.setHeaders([
                {
                    name: 'UID',
                    indicatorID: 'uid',
                    editable: false,
                    callback: function(data, blob) {
                        const link = `<a href="../index.php?a=printview&recordID=${data.recordID}" target="_blank">${data.recordID}</a>`
                        $('#'+data.cellContainerID).html(link);
                    }
                },
                {
                    name: 'Title', 
                    indicatorID: 'title', 
                    callback: function(data, blob) {
                        $('#'+data.cellContainerID).html(blob[data.recordID].title);
                        $('#'+data.cellContainerID).on('click', function() {
                            window.open('../index.php?a=printview&recordID='+data.recordID, 'LEAF', 'width=800,resizable=yes,scrollbars=yes,menubar=yes');
                    });
                }},
                {
                    name: 'Question to Update',
                    request: 'request',
                    editable: false,
                    callback: function(data, blob) {
                        $('#'+data.cellContainerID).html(`indicator ${blob[data.recordID].indicatorID}`);
                }}
            ]);
            formGrid.loadData(recordIDs);

            accountAndTaskInfo.taskType = 'update_orgchart_employee_field';
            enqueueTask(res, accountAndTaskInfo, queue);
        } else {
            $('#grid_orgchart_employee').append('No records found');
        }
    });
    calls.push(queryOrgchartEmployee.execute());

    /*  ******************************************************************************* */

    calls.push(searchGroupsOldAccount(accountAndTaskInfo, queue));

    Promise.all(calls).then((res)=> {
        queue.setWorker(item => { //queue items added in 'enqueueTask' function
            return processTask(item);
        });
        $('#reassign').on('click', function() {
            $('#section2').css('display', 'none');
            $('#section3').css('display', 'block');
            return queue.start().then((res) => {
                let elStatus = document.getElementById('queue_completed');
                if (elStatus !== null) {
                    elStatus.style.display = 'block';
                }
            });
        });

    }).catch(err => console.log(err));
}

$(function() {
    const empSel = new nationalEmployeeSelector('employeeSelector');
    empSel.apiPath = '<!--{$orgchartPath}-->/api/';
    empSel.rootPath = '<!--{$orgchartPath}-->/';
    empSel.outputStyle = 'micro';
    empSel.setResultHandler(function() {
        if(this.numResults > 0) {
            for(let i in this.selectionData) {
                $(`#${this.prefixID}emp${i} > .employeeSelectorName`).append(`<br /><span style="font-weight: normal">${this.selectionData[i].userName}</span>`);
            }
        }
    });
    empSel.initialize();

    const empSelNew = new nationalEmployeeSelector('newEmployeeSelector');
    empSelNew.apiPath = '<!--{$orgchartPath}-->/api/';
    empSelNew.rootPath = '<!--{$orgchartPath}-->/';
    empSelNew.outputStyle = 'micro';
    empSelNew.setResultHandler(function() {
        if(this.numResults > 0) {
            for(let i in this.selectionData) {
                $(`#${this.prefixID}emp${i} > .employeeSelectorName`).append(`<br /><span style="font-weight: normal">${this.selectionData[i].userName}</span>`);
            }
        }
    });
    empSelNew.initialize();

    $('.employeeSelectorTable > thead > tr').prepend('<td style="color: red">Account Name</td>');

    $('#run').on('click', function() {
        findAssociatedRequests(empSel, empSelNew);
    });
    $('#reset').on('click', function() {
        resetEntryFields(empSel, empSelNew);
    })
});
</script>

<main>
    <div id="section1">
        <div id="account_input_area">
            <div class="card">
                <h2>Old Account</h2>
                <div id="employeeSelector"></div>
            </div>
            <div class="card">
                <h2>New Account</h2>
                <div id="newEmployeeSelector"></div>
            </div>
        </div>
        <br style="clear: both" /><br />
        <button class="buttonNorm" id="run">Preview Changes</button>
        <div id="preview_no_results_found" style="display: none">No associated requests or groups were found for the old account selected</div>
    </div>
    <div id="section2" style="display: none">
        <p>The old account you have selected is "<span id="oldAccountName" style="font-weight: bold"></span>"</p>
        <p>The new account you have selected is "<span id="newAccountName" style="font-weight: bold"></span>".</p>
        <p>Please review the results below. &nbsp;Activate the button to update them to reflect the new account.</p>
        <br />
        <div style="display:flex; margin-bottom:3rem;">
            <button class="buttonNorm" id="reassign" style="margin-right: 1rem">Update These Requests</button>
            <button class="buttonNorm" id="reset">Start Over</button>
        </div>

        <h3>Requests created by the old account</h3>
        <div id="grid_initiator" class="grid_table"></div>
        
        <h3>Orgchart Employee fields containing the old account</h3>
        <div id="grid_orgchart_employee" class="grid_table"></div>

        <h3>Groups for Old Account</h3>
        <div id="grid_groups_info" class="grid_table"></div>
    </div>
    <div id="section3" style="display: none">
        <div id="initiators_updated" class="updates_output">
            <p><b>Initiator Updates</b></p>
        </div>
        <div id="orgchart_employee_updated" class="updates_output">
            <p><b>Orgchart Employee Field Updates</b></p>
        </div>
        <div id="groups_updated" class="updates_output">
            <p><b>Group Updates</b></p>
        </div>
        <div id="queue_completed" style="display: none"><b>Updates Complete</b></div>
    </div>
</main>