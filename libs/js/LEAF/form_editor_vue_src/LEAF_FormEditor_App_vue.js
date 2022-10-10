import LeafFormDialog from "./components/LeafFormDialog.js";
import IndicatorEditing from "./components/dialog_content/IndicatorEditing.js";
import AdvancedOptionsDialog from "./components/dialog_content/AdvancedOptionsDialog.js";
import NewFormDialog from "./components/dialog_content/NewFormDialog.js";
import ImportFormDialog from "./components/dialog_content/ImportFormDialog.js";
import FormHistoryDialog from "./components/dialog_content/FormHistoryDialog.js";
import StapleFormDialog from "./components/dialog_content/StapleFormDialog.js";
import EditCollaboratorsDialog from "./components/dialog_content/EditCollaboratorsDialog.js";
import ConfirmDeleteDialog from "./components/dialog_content/ConfirmDeleteDialog.js";

import ModFormMenu from "./components/ModFormMenu.js";
import CategoryCard from "./components/CategoryCard.js";
import FormViewController from "./components/form_view/FormViewController.js";

import RestoreFields from "./components/RestoreFields.js";
import './LEAF_FormEditor.scss';

export default {
    data() {
        return {
            APIroot: '../api/',
            CSRFToken: CSRFToken,
            siteSettings: {},
            showCertificationStatus: false,
            dialogTitle: '',
            dialogFormContent: '',
            dialogButtonText: {confirm: 'Save', cancel: 'Cancel'},
            showFormDialog: false,
            //this sets the method associated with the save btn to the onSave method of the modal's current component
            formSaveFunction: ()=> {
                if(this.$refs[this.dialogFormContent]) {
                    this.$refs[this.dialogFormContent].onSave();
                } else { console.log('got something unexpected')}
            },
            isEditingModal: false,

            appIsLoadingCategoryList: true,
            appIsLoadingCategoryInfo: false,
            currCategoryID: null,          //null or string
            currSubformID: null,           //null or string
            currIndicatorID: null,         //null or number
            newIndicatorParentID: null,    //null or number
            categories: {},                //obj with keys for each catID, values an object with 'categories' and 'workflow' tables fields
            currentCategorySelection: {},  //current record from categories object
            ajaxFormByCategoryID: [],      //form tree with information about indicators for each node
            selectedFormNode: null,
            indicatorCountSwitch: true,    //TEST toggle to trigger form view controller remount if the total count changes
            selectedNodeIndicatorID: null,
            currentCategoryIsSensitive: false,
            currentCategoryIndicatorTotal: 0,
            formsStapledCatIDs: [],  //cat IDs of forms stapled to anything
            ajaxSelectedCategoryStapled: [],
            ajaxWorkflowRecords: [],       //array of all 'workflows' table records
            ajaxIndicatorByID: {},         //'indicators' table record for a specific indicatorID
            orgSelectorClassesAdded: { group: false, position: false, employee: false },
            restoringFields: false        //TODO:?? there are a few pages that could be view here, page_views: [restoringFields: false, leafLibrary: false etc]
        }
    },
    provide() {
        return {
            CSRFToken: Vue.computed(() => this.CSRFToken),
            currCategoryID: Vue.computed(() => this.currCategoryID),
            currSubformID: Vue.computed(() => this.currSubformID),
            currIndicatorID: Vue.computed(() => this.currIndicatorID),
            newIndicatorParentID: Vue.computed(() => this.newIndicatorParentID),
            isEditingModal: Vue.computed(() => this.isEditingModal),
            ajaxIndicatorByID: Vue.computed(() => this.ajaxIndicatorByID),
            categories: Vue.computed(() => this.categories),
            currentCategorySelection: Vue.computed(() => this.currentCategorySelection),
            selectedNodeIndicatorID: Vue.computed(() => this.selectedNodeIndicatorID),
            selectedFormNode: Vue.computed(() => this.selectedFormNode),
            currentCategoryIsSensitive: Vue.computed(() => this.currentCategoryIsSensitive),
            currentCategoryIndicatorTotal: Vue.computed(() => this.currentCategoryIndicatorTotal),
            ajaxFormByCategoryID: Vue.computed(() => this.ajaxFormByCategoryID),
            appIsLoadingCategoryInfo: Vue.computed(() => this.appIsLoadingCategoryInfo),
            ajaxSelectedCategoryStapled: Vue.computed(() => this.ajaxSelectedCategoryStapled),
            formsStapledCatIDs: Vue.computed(() => this.formsStapledCatIDs),
            ajaxWorkflowRecords: Vue.computed(() => this.ajaxWorkflowRecords),
            showFormDialog: Vue.computed(() => this.showFormDialog),
            dialogTitle: Vue.computed(() => this.dialogTitle),
            dialogFormContent: Vue.computed(() => this.dialogFormContent),
            dialogButtonText: Vue.computed(() => this.dialogButtonText),
            formSaveFunction: Vue.computed(() => this.formSaveFunction),
            restoringFields: Vue.computed(() => this.restoringFields),
            orgSelectorClassesAdded: Vue.computed(() => this.orgSelectorClassesAdded),
            //static values
            APIroot: this.APIroot,
            newQuestion: this.newQuestion,
            editQuestion: this.editQuestion,
            getStapledFormsByCurrentCategory: this.getStapledFormsByCurrentCategory,
            setCurrCategoryStaples: this.setCurrCategoryStaples,
            editIndicatorPrivileges: this.editIndicatorPrivileges,
            selectIndicator: this.selectIndicator,
            selectNewCategory: this.selectNewCategory,
            selectNewFormNode: this.selectNewFormNode,
            updateCategoriesProperty: this.updateCategoriesProperty,
            updateFormsStapledCatIDs: this.updateFormsStapledCatIDs,
            addNewCategory: this.addNewCategory,
            closeFormDialog: this.closeFormDialog,
            openAdvancedOptionsDialog: this.openAdvancedOptionsDialog,
            openNewFormDialog: this.openNewFormDialog,
            openImportFormDialog: this.openImportFormDialog,
            openFormHistoryDialog: this.openFormHistoryDialog,
            openConfirmDeleteFormDialog: this.openConfirmDeleteFormDialog,
            openStapleFormsDialog: this.openStapleFormsDialog,
            openEditCollaboratorsDialog: this.openEditCollaboratorsDialog,
            addOrgSelector: this.addOrgSelector,
            truncateText: this.truncateText,
            showRestoreFields: this.showRestoreFields,
            toggleIndicatorCountSwitch: this.toggleIndicatorCountSwitch
        }
    },
    components: {
        LeafFormDialog,
        IndicatorEditing,
        AdvancedOptionsDialog,
        NewFormDialog,
        ImportFormDialog,
        FormHistoryDialog,
        StapleFormDialog,
        EditCollaboratorsDialog,
        ConfirmDeleteDialog,
        ModFormMenu,
        CategoryCard,
        FormViewController,
        RestoreFields
    },
    beforeMount() {
        this.getCategoryListAll().then(res => {
            this.setCategories(res);
            this.appIsLoadingCategoryList = false;
        }).catch(err => console.log('error getting category list', err));

        this.getWorkflowRecords().then(res => {
            this.ajaxWorkflowRecords = res;
        }).catch(err => console.log('error getting workflow records', err));
    },
    mounted() {
        this.getSiteSettings().then(res => {
            this.siteSettings = res;
            if (res.leafSecure >=1) {
                this.getSecureFormsInfo();
            }
        }).catch(err => console.log('error getting site settings', err));
    },
    computed: {
        activeCategories() {
            let active = [];
            for (let c in this.categories) {
                if (this.categories[c].parentID==='' && parseInt(this.categories[c].workflowID)!==0) {
                    active.push({...this.categories[c]});
                }
            }
            return active;
        },
        inactiveCategories() {
            let inactive = [];
            for (let c in this.categories) {
                if (this.categories[c].parentID==='' && parseInt(this.categories[c].workflowID)===0) {
                    inactive.push({...this.categories[c]});
                }
            }
            return inactive;
        }
    },
    methods: {
        truncateText(str, maxlength = 40, overflow = '...') {
            return str.length <= maxlength ? str : str.slice(0, maxlength) + overflow;
        },
        addOrgSelector(selectorType) {
            this.orgSelectorClassesAdded[selectorType] = true;
        },
        toggleIndicatorCountSwitch() {
            this.indicatorCountSwitch = !this.indicatorCountSwitch;
        },
        getCategoryListAll() {
            this.appIsLoadingCategoryList = true;
            return new Promise((resolve, reject)=> {
                $.ajax({
                    type: 'GET',
                    url: `${this.APIroot}formStack/categoryList/all`,
                    success: (res)=> resolve(res),
                    error: (err)=> reject(err)
                });
            });
        },
        getWorkflowRecords() {
            return new Promise((resolve, reject)=> {
                $.ajax({
                    type: 'GET',
                    url: `${this.APIroot}workflow`,
                    success: (res) => resolve(res),
                    error: (err) => reject(err)
                });
            });
        },
        getSiteSettings() {
            return new Promise((resolve, reject)=> {
                $.ajax({
                    type: 'GET',
                    url: `${this.APIroot}system/settings`,
                    success: (res) => resolve(res),
                    error: (err) => reject(err),
                    cache: false
                })
            });
        },
        fetchLEAFSRequests(searchResolved) {
            return new Promise((resolve, reject)=> {
                let query = new LeafFormQuery();
                query.setRootURL('../');
                query.addTerm('categoryID', '=', 'leaf_secure');
            
                if (searchResolved === true) {
                    query.addTerm('stepID', '=', 'resolved');
                    query.join('recordResolutionData');
                } else {
                    query.addTerm('stepID', '!=', 'resolved');
                }
                query.onSuccess((data) => {
                    resolve(data);
                });
                query.execute();
            });
        },
        getSecureFormsInfo() {
            let secureCalls = [
                $.ajax({
                    type: 'GET',
                    url: `${this.APIroot}form/indicator/list`, //all non DELETED ind and headers
                    success: (res)=> {},
                    error: (err) => console.log(err),
                    cache: false,
                }),

                this.fetchLEAFSRequests(true)
            ];

            Promise.all(secureCalls)
            .then((res)=> {
                const indicatorList = res[0];
                const leafSecureRecords = res[1];
                this.checkLeafSRequestStatus(indicatorList, leafSecureRecords);
            });

        },
        checkLeafSRequestStatus(indicatorList, leafSRequests) {
            let mostRecentID = null;
            let newIndicator = false;
            let mostRecentDate = 0;

            for(let i in leafSRequests) {
                if(leafSRequests[i].recordResolutionData.lastStatus.toLowerCase() === 'approved'
                    && leafSRequests[i].recordResolutionData.fulfillmentTime > mostRecentDate) {
                    mostRecentDate = leafSRequests[i].recordResolutionData.fulfillmentTime;
                    mostRecentID = i;
                }
            }
            document.getElementById('secureBtn').setAttribute('href', '../index.php?a=printview&recordID=' + mostRecentID);
            const mostRecentTimestamp = new Date(parseInt(mostRecentDate)*1000); // converts epoch secs to ms
            for(let i in indicatorList) {
                if(new Date(indicatorList[i].timeAdded).getTime() > mostRecentTimestamp.getTime()) {
                    newIndicator = true;
                    break;
                }
            }
            if (newIndicator === true) {
                this.showCertificationStatus = true;
                this.fetchLEAFSRequests(false).then(unresolvedLeafSRequests => {
                    if (unresolvedLeafSRequests.length === 0) { // if no new request, create one
                        document.getElementById('secureStatus').innerText = 'Forms have been modified.';
                        document.getElementById('secureBtn').innerText = 'Please Recertify Your Site';
                        document.getElementById('secureBtn').setAttribute('href', '../report.php?a=LEAF_start_leaf_secure_certification');
                    } else {
                        const recordID = unresolvedLeafSRequests[Object.keys(unresolvedLeafSRequests)[0]].recordID;
                        document.getElementById('secureStatus').innerText = 'Re-certification in progress.';
                        document.getElementById('secureBtn').innerText = 'Check Certification Progress';
                        document.getElementById('secureBtn').setAttribute('href', '../index.php?a=printview&recordID=' + recordID);
                    }
                })
            }
        },
        getFormByCategoryID(catID = this.currCategoryID) {
            this.appIsLoadingCategoryInfo = true;
            return new Promise((resolve, reject)=> {
                $.ajax({
                    type: 'GET',
                    url: `${this.APIroot}form/_${catID}`,
                    success: (res)=> {
                        this.appIsLoadingCategoryInfo = false;
                        resolve(res)
                    },
                    error: (err)=> reject(err)
                });
            });
        },
        getStapledFormsByCurrentCategory(formID) {
            return new Promise((resolve, reject)=> {
                $.ajax({
                    type: 'GET',
                    url: `${this.APIroot}formEditor/_${formID}/stapled`,
                    success: (res) => {
                        resolve(res);
                    },
                    error: (err) => reject(err)
                });
            });
        },
        getIndicatorByID(indID) { //get specific indicator info
            return new Promise((resolve, reject)=> {
                $.ajax({
                    type: 'GET',
                    url: `${this.APIroot}formEditor/indicator/${indID}`,
                    success: (res)=> resolve(res),
                    error: (err) => reject(err)
                });
            });
        },
        //builds categories object from getCatListAll res on success, for local data use
        setCategories(obj) {
            for(let i in obj) {
                this.categories[obj[i].categoryID] = obj[i];
            }
        },
        setCurrCategoryStaples(stapledForms) {
            this.ajaxSelectedCategoryStapled = stapledForms;
        },
        updateCategoriesProperty(catID, keyName, keyValue) {
            this.categories[catID][keyName] = keyValue;
            this.currentCategorySelection = this.categories[catID];
            console.log('updated curr cat selection', keyName, this.currentCategorySelection);
        },
        updateFormsStapledCatIDs(stapledCatID, removeCatID = false) {
            if(removeCatID === true) {
                if(this.formsStapledCatIDs.includes(stapledCatID)) {
                    const index = this.formsStapledCatIDs.indexOf(stapledCatID);
                    this.formsStapledCatIDs = [...this.formsStapledCatIDs.slice(0, index), ...this.formsStapledCatIDs.slice(index + 1)];
                }
            } else {
                if(!this.formsStapledCatIDs.includes(stapledCatID)) {
                    this.formsStapledCatIDs = [...this.formsStapledCatIDs, stapledCatID];
                } 
            }
        },
        addNewCategory(catID, record = {}) {
            this.categories[catID] = record;
        },
        //categoryID of the form to select, whether it is a subform, indicatorID associated with the current selection in the form index 
        selectNewCategory(catID, isSubform = false, subnodeIndID = null) {
            this.restoringFields = false;  //nav from Restore Fields subview

            if(!isSubform) {
                console.log('setting new currCatID and setting subformID to null', catID);
                this.currCategoryID = catID; //set main form catID
                this.currSubformID = null;   //clear the subform ID
            } else {
                console.log(`currCatID remains ${this.currCategoryID} setting new subCatID`, catID);
                this.currSubformID = catID;  //update the subformID, but keep the main form ID
            }
            console.log('RESET: currentCategorySelection, ajaxFormByCategoryID, staples, selectednode, nodeIndID, indicatorTotal');
            this.currentCategorySelection = {};
            this.ajaxFormByCategoryID = [];
            this.ajaxSelectedCategoryStapled = [];
            this.selectedFormNode = null;
            this.selectedNodeIndicatorID = null;
            this.currentCategoryIndicatorTotal = 0;

            vueData.formID = catID || ''; //NOTE: update of other vue app TODO: mv?
            document.getElementById('btn-vue-update-trigger').dispatchEvent(new Event("click"));

            //switch to specified record, get info for the newly selected form, update sensitive, total values, get staples
            if (catID !== null) {
                this.currentCategorySelection = { ...this.categories[catID]};
                this.selectedNodeIndicatorID = subnodeIndID;
                this.currentCategoryIsSensitive = false;

                this.getFormByCategoryID(catID).then(res => {
                    this.ajaxFormByCategoryID = res;
                    this.ajaxFormByCategoryID.forEach(section => {
                        this.currentCategoryIndicatorTotal = this.getIndicatorCountAndNodeSelection(section, this.currentCategoryIndicatorTotal);
                        this.currentCategoryIsSensitive = this.checkSensitive(section, this.currentCategoryIsSensitive);
                    });
                    document.getElementById(catID).focus(); //focus the button for the main form
                }).catch(err => console.log('error getting form info: ', err));

                const formID = this.currSubformID || this.currCategoryID;
                this.getStapledFormsByCurrentCategory(formID).then(res => this.ajaxSelectedCategoryStapled = res);

            } else {  //nav to form card browser.
                this.appIsLoadingCategoryList = true;
                this.categories = {};

                this.getCategoryListAll().then(res => {
                    this.setCategories(res);
                    this.appIsLoadingCategoryList = false;
                }).catch(err => console.log('error getting category list', err));

                this.getWorkflowRecords().then(res => {
                    this.ajaxWorkflowRecords = res;
                }).catch(err => console.log('error getting workflow records', err));
            }
        },
        selectNewFormNode(event, node) {
            if (event.target.classList.contains('icon_move') || event.target.classList.contains('sub-menu-chevron')) {
                return //prevents enter/space activation from move and menu toggle buttons
            }
            this.selectedFormNode = node;
            this.selectedNodeIndicatorID = node?.indicatorID || null;
            console.log('setting form node and indID from list selection', this.selectedNodeIndicatorID)
        },
        editIndicatorPrivileges() {
            //TODO:
            console.log('clicked edit privileges');
        },
        setCustomDialogTitle(htmlContent) {
            this.dialogTitle = htmlContent;
        },
        //takes comp name as string, eg 'confirm-delete-dialog'
        //components must be registered to this app
        setFormDialogComponent(component) {
            this.dialogFormContent = component;
        },
        clearCustomDialog() {
            this.setCustomDialogTitle('');
            this.setFormDialogComponent('');
            this.dialogButtonText = {confirm: 'Save', cancel: 'Cancel'};
        },
        closeFormDialog() {
            this.showFormDialog = false;
            this.clearCustomDialog();
        },
        openConfirmDeleteFormDialog() {
            this.setCustomDialogTitle('<h2>Delete this form</h2>');
            this.setFormDialogComponent('confirm-delete-dialog');
            this.dialogButtonText = {confirm: 'Yes', cancel: 'No'};
            this.showFormDialog = true;
        },
        openStapleFormsDialog() {
            this.setCustomDialogTitle('<h2>Editing Stapled Forms</h2>');
            this.setFormDialogComponent('staple-form-dialog');
            this.dialogButtonText = {confirm: 'Add', cancel: 'Close'};
            this.showFormDialog = true;
        },
        openEditCollaboratorsDialog() {
            this.setCustomDialogTitle('<h2>Editing Collaborators</h2>');
            this.setFormDialogComponent('edit-collaborators-dialog');
            this.dialogButtonText = {confirm: 'Add', cancel: 'Close'};
            this.showFormDialog = true;
        },
        openIndicatorEditing(indicatorID) { //equal to curIndID when editing, a parIndID for add subquestion, and null for add section
            let title = ''
            if (indicatorID === null) { //not an existing indicator, nor a child of an existing indicator
                title = `<h2>Adding new question</h2>`;
            } else {
                title = this.currIndicatorID === parseInt(indicatorID) ? 
                `<h2>Editing indicator ${indicatorID}</h2>` : `<h2>Adding question to ${indicatorID}</h2>`;
            }
            this.setCustomDialogTitle(title);
            this.setFormDialogComponent('indicator-editing');
            this.showFormDialog = true;
        },
        openAdvancedOptionsDialog(indicatorID) {
            this.currIndicatorID = parseInt(indicatorID);
            this.getIndicatorByID(indicatorID).then(res => {
                this.ajaxIndicatorByID = res;
                this.setCustomDialogTitle(`<h2>Advanced Options for indicator ${indicatorID}</h2>`);
                this.setFormDialogComponent('advanced-options-dialog');
                this.showFormDialog = true;   
            }).catch(err => console.log('error getting indicator information', err));
        },
        openNewFormDialog() {
            const titleHTML = this.currCategoryID === null ? '<h2>New Form</h2>' : '<h2>New Internal Use Form</h2>';
            this.setCustomDialogTitle(titleHTML);
            this.setFormDialogComponent('new-form-dialog');
            this.showFormDialog = true; 
        },
        openImportFormDialog() {
            this.setCustomDialogTitle('<h2>Import Form</h2>');
            this.setFormDialogComponent('import-form-dialog');
            this.showFormDialog = true;  
        },
        openFormHistoryDialog() {
            this.setCustomDialogTitle(`<h2>Form History</h2>`);
            this.setFormDialogComponent('form-history-dialog');
            this.showFormDialog = true;
        },
        newQuestion(parentIndID) {
            this.currIndicatorID = null;
            this.newIndicatorParentID = parentIndID !== null ? parseInt(parentIndID) : null;
            this.isEditingModal = false;
            console.log('Adding new indicator.', 'currID should be null:', this.currIndicatorID, 
                'parentID (null for new sections):', this.newIndicatorParentID, 'FORM:', this.currCategoryID);
            this.openIndicatorEditing(parentIndID);
        },
        editQuestion(indicatorID, series) {
            this.currIndicatorID = parseInt(indicatorID);
            this.newIndicatorParentID = null;
            this.getIndicatorByID(indicatorID).then(res => {
                this.isEditingModal = true;
                this.ajaxIndicatorByID = res;
                this.openIndicatorEditing(indicatorID);
                console.log('app called editQuestion with:', indicatorID, series);
            }).catch(err => console.log('error getting indicator information', err));
        },
        checkSensitive(node, isSensitive = false) {
            if (isSensitive === false) {
                if (parseInt(node.is_sensitive) === 1) {
                    isSensitive = true;
                }
                if (isSensitive === false && node.child) {
                    for (let c in node.child) {
                        isSensitive = this.checkSensitive(node.child[c], isSensitive);
                        if (isSensitive === true) break;
                    }
                }
            }
            return isSensitive;
        },
        getIndicatorCountAndNodeSelection(node = {}, count = 0) {
            count++;
            if (node.indicatorID === this.selectedNodeIndicatorID) {
                this.selectedFormNode = node;
                console.log('found updated node from stored node ID', this.selectedNodeIndicatorID, this.selectedFormNode)
            }
            if (node.child) {
                for (let c in node.child) {
                    count = this.getIndicatorCountAndNodeSelection(node.child[c], count);
                }
            }
            return count;
        },
        showRestoreFields() {
            this.restoringFields = true;
        }
    }
}