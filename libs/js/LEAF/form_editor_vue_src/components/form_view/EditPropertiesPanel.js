export default {
    data() {
        return {
            categoryName: this.currentCategorySelection?.categoryName || 'Untitled',
            categoryDescription: this.currentCategorySelection?.categoryDescription || '',
            workflowID: parseInt(this.currentCategorySelection?.workflowID) || 0,
            description: this.currentCategorySelection?.description || '',
            needToKnow: parseInt(this.currentCategorySelection?.needToKnow) || 0,
            sort: parseInt(this.currentCategorySelection?.sort) || 0,
            visible: parseInt(this.currentCategorySelection?.visible) || 0,
            type: this.currentCategorySelection?.type || '',
            formID: this.currSubformID || this.currCategoryID
        }
    },
    inject: [
        'APIroot',
        'CSRFToken',
        'currCategoryID',
        'currSubformID',
        'truncateText',
        'ajaxWorkflowRecords',
        'currentCategorySelection',
        'currentCategoryIsSensitive',
        'updateCategoriesProperty',
        'editPermissionsClicked',
        'closeFormDialog'
	],
    computed: {
        categoryDescriptionDisplay() {
            return XSSHelpers.stripAllTags(this.currentCategorySelection.categoryDescription);
        },
        workflow() {
            return parseInt(this.currentCategorySelection.workflowID) === 0 ?
            `<span style="color: red">No workflow. Users will not be able to select this form.</span>` :
            `${this.currentCategorySelection.description} (ID #${this.currentCategorySelection.workflowID})`;
        },
        isSubForm(){
            return this.currentCategorySelection.parentID !== '';
        },
        isNeedToKnow(){
            return parseInt(this.needToKnow) === 1;
        },
        changesPending() {
            const nameChanged = this.categoryName !== this.currentCategorySelection.categoryName;
            const descriptionChanged  = this.categoryDescription !== this.currentCategorySelection.categoryDescription;
            const workflowChanged  = this.workflowID !== parseInt(this.currentCategorySelection.workflowID);
            const needToKnowChanged = this.needToKnow !== parseInt(this.currentCategorySelection.needToKnow);
            const sortChanged = this.sort !== parseInt(this.currentCategorySelection.sort);
            const visibleChanged = this.visible !== parseInt(this.currentCategorySelection.visible);
            const typeChanged = this.type !== this.currentCategorySelection.type;
            const changes = [
                nameChanged, descriptionChanged, workflowChanged, needToKnowChanged, sortChanged, visibleChanged, typeChanged
            ];
            return changes.some(c => c === true);
        }
    },
    methods: {
        updateWorkflowDescription() {
            const currWorkflow = this.ajaxWorkflowRecords.find(rec => parseInt(rec.workflowID) === this.workflowID);
            this.description = currWorkflow?.description || '';
        },
        onSave(){
            let  editPropertyUpdates = [];
            const nameChanged = this.categoryName !== this.currentCategorySelection.categoryName;
            const descriptionChanged  = this.categoryDescription !== this.currentCategorySelection.categoryDescription;
            const workflowChanged  = this.workflowID !== parseInt(this.currentCategorySelection.workflowID);
            const needToKnowChanged = this.needToKnow !== parseInt(this.currentCategorySelection.needToKnow);
            const sortChanged = this.sort !== parseInt(this.currentCategorySelection.sort);
            const visibleChanged = this.visible !== parseInt(this.currentCategorySelection.visible);
            const typeChanged = this.type !== this.currentCategorySelection.type;

            if(nameChanged) {
                editPropertyUpdates.push(
                    $.ajax({
                        type: 'POST',
                        url: `${this.APIroot}formEditor/formName`,
                        data: {
                            name: this.categoryName,
                            categoryID: this.formID,
                            CSRFToken: this.CSRFToken
                        },
                        success: () => {  //NOTE:  except for WF, these give back an empty array
                            this.updateCategoriesProperty(this.formID, 'categoryName', this.categoryName);
                        },
                        error: err =>  console.log('name post err', err)
                    })
                );
            }
            if(descriptionChanged) {
                editPropertyUpdates.push(
                    $.ajax({
                        type: 'POST',
                        url: `${this.APIroot}formEditor/formDescription`,
                        data: {
                            description: this.categoryDescription,
                            categoryID: this.formID,
                            CSRFToken: this.CSRFToken
                        },
                        success: () => {
                            this.updateCategoriesProperty(this.formID, 'categoryDescription', this.categoryDescription);
                        },
                        error: err => console.log('form description post err', err)
                    })
                );
            }
            if(workflowChanged) {
                editPropertyUpdates.push(
                    $.ajax({
                        type: 'POST',
                        url: `${this.APIroot}formEditor/formWorkflow`,
                        data: {
                            workflowID: this.workflowID,
                            categoryID: this.formID,
                            CSRFToken: this.CSRFToken
                        },
                        success: (res) => {
                            if (res === false) { //1 on success
                                alert('The workflow could not be set because this form is stapled to another form');
                            } else {
                                this.updateCategoriesProperty(this.formID, 'workflowID', this.workflowID);
                                this.updateCategoriesProperty(this.formID, 'description', this.description);
                            }
                        },
                        error: err => console.log('workflow post err', err)
                    })
                );
            }
            if(needToKnowChanged){
                editPropertyUpdates.push(
                    $.ajax({
                        type: 'POST',
                        url: `${this.APIroot}formEditor/formNeedToKnow`,
                        data: {
                            needToKnow: this.needToKnow,
                            categoryID: this.formID,
                            CSRFToken: this.CSRFToken
                        },
                        success: () => {
                            this.updateCategoriesProperty(this.formID, 'needToKnow', this.needToKnow);
                        },
                        error: err => console.log('ntk post err', err)
                    })
                );
            }
            if(sortChanged){
                editPropertyUpdates.push(
                    $.ajax({
                        type: 'POST',
                        url: `${this.APIroot}formEditor/formSort`,
                        data: {
                            sort: this.sort,
                            categoryID: this.formID,
                            CSRFToken: this.CSRFToken
                        },
                        success: () => {
                            this.updateCategoriesProperty(this.formID, 'sort', this.sort);
                        },
                        error: err => console.log('sort post err', err)
                    })
                );
            }
            if(visibleChanged){
                editPropertyUpdates.push(
                    $.ajax({
                        type: 'POST',
                        url: `${this.APIroot}formEditor/formVisible`,
                        data: {
                            visible: this.visible,
                            categoryID: this.formID,
                            CSRFToken: this.CSRFToken
                        },
                        success: () => {
                            this.updateCategoriesProperty(this.formID, 'visible', this.visible);
                        },
                        error: err => console.log('visibility post err', err)
                    })
                );
            }
            if(typeChanged){
                editPropertyUpdates.push(
                    $.ajax({
                        type: 'POST',
                        url: `${this.APIroot}formEditor/formType`,
                        data: {
                            type: this.type,
                            categoryID: this.formID,
                            CSRFToken: this.CSRFToken
                        },
                        success: () => {
                            this.updateCategoriesProperty(this.formID, 'type', this.type);
                        },
                        error: err => console.log('type post err', err)
                    })
                );
            }
            Promise.all(editPropertyUpdates)
                .then(()=> {
                    console.log('promise all:', editPropertyUpdates);
                    this.closeFormDialog();
                });
        }
    },
    template: `<div id="edit-properties-panel">
    <div id="edit-properties-description">
        <div class="form-id">ID: {{currCategoryID}}
            <span v-if="currSubformID!==null">(subform {{currSubformID}})</span>
        </div>
        <label for="categoryName">Form name (up to 50 characters)</label>
        <input id="categoryName" type="text" maxlength="50" v-model="categoryName" />
        
        <label for="categoryDescription">Form description (up to 255 characters)</label>
        <textarea id="categoryDescription" maxlength="255" v-model="categoryDescription" rows="3"></textarea>
    </div>
    <div id="edit-properties-other-properties">
        <template v-if="!isSubForm">
            <div style="display:flex;">
                <button id="editFormPermissions" class="btn-general"
                    style="width: fit-content;"
                    @click="editPermissionsClicked">
                    Edit Collaborators
                </button>
                <div v-if="!changesPending" class="can_update" title="properties can be edited directly in the info panel">ℹ</div>
                <button v-else class="can_update" title="Apply form property updates" @click="onSave">Apply updates</button>
            </div>
            <div class="panel-properties">
                <template v-if="ajaxWorkflowRecords.length > 0">
                    <label for="workflowID">Workflow&nbsp;
                    <select id="workflowID" name="select-workflow" 
                        title="select workflow"
                        v-model.number="workflowID"
                        @change="updateWorkflowDescription">
                        <option value="0" :selected="workflowID===0">No Workflow</option>
                        <template v-for="r in ajaxWorkflowRecords" :key="r.workflowID">
                            <option v-if="parseInt(r.workflowID) > 0"
                                :value="r.workflowID"
                                :selected="workflowID===parseInt(r.workflowID)">
                                ID#{{r.workflowID}}: {{truncateText(r.description, 26)}}
                            </option>
                        </template>
                    </select></label>
                </template>
                <div v-else style="color: #d00; width: 100%;">A workflow must be set up first</div>

                <label for="availability">Availability
                    <span v-if="workflowID===0 && visible===1" title="this form will not be selectable without a workflow">⚠️</span>&nbsp;
                    <select id="availability" title="Select Availability" v-model.number="visible">
                        <option value="1" :selected="visible===1">Available</option>
                        <option value="0" :selected="visible===0">Hidden</option>
                    </select>
                </label>

                <label for="categorySort">Sort&nbsp;
                    <input id="categorySort" type="number" v-model.number="sort" style="width:60px;"/>
                </label>

                <label for="formType">Form Type&nbsp;
                <select id="formType" title="Change type of form" v-model="type" >
                    <option value="" :selected="type===''">Standard</option>
                    <option value="parallel_processing" :selected="type==='parallel_processing'">Parallel Processing</option>
                </select></label>

                <span v-if="currentCategoryIsSensitive" style="color: #d00;">Need to know is forced on because sensitive fields are present</span>
                <label v-else for="needToKnow"
                    title="When turned on, the people associated with the workflow are the only ones who have access to view the form. \nForced on if the form contains sensitive information.">Need to know&nbsp;
                <select id="needToKnow" v-model.number="needToKnow" :style="{color: isNeedToKnow ? '#d00' : 'black'}">
                    <option value="0" :selected="!isNeedToKnow">Off</option>
                    <option value="1" :selected="isNeedToKnow">On</option>
                </select></label>
            </div>

        </template>
        <div v-else style="margin-top: auto; padding-left: 0.75rem">This is an Internal Form</div>
    </div>

</div>`
}