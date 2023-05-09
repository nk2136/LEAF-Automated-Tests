import CustomMenuItem from "./CustomMenuItem";

export default {
    name: 'custom-home-menu',
    components: {
        CustomMenuItem
    },
    inject: [
        'isPostingUpdate',
        'publishedStatus',
        'isEditingMode',
        'menuItemList',
        'allBuiltinsPresent',
        'addStarterButtons',
        'editMenuItemList',
        'postMenuItemList',
        'setMenuItem',
        'postEnableTemplate'
    ],
    methods: {
        onDragStart(event = {}) {
            if(!this.isPostingUpdate && event?.dataTransfer) {
                event.dataTransfer.dropEffect = 'move';
                event.dataTransfer.effectAllowed = 'move';
                event.dataTransfer.setData('text/plain', event.target.id);
            }
        },
        onDrop(event = {}) {
            if(!this.isPostingUpdate && event?.dataTransfer && event.dataTransfer.effectAllowed === 'move') {
                const dataID = event.dataTransfer.getData('text');
                const elUl = event.currentTarget;

                const listItems = Array.from(document.querySelectorAll('#menu_designer li'));
                const elLiToMove = document.getElementById(dataID);
                const elOtherLi = listItems.filter(item => item.id !== dataID);

                const closest = elOtherLi.find(item => event.clientY <= item.offsetTop + item.offsetHeight / 2);

                elUl.insertBefore(elLiToMove,closest);
                this.editMenuItemList();
                this.postMenuItemList();
            }
        }
    },
    template: `<div>
        <p v-show="isEditingMode">Drag-Drop cards to change their order.  Use the card menu to edit text and other values.</p>
        <ul v-if="menuItemList.length > 0" id="menu_designer" :class="{editMode: isEditingMode}"
            data-effect-allowed="move"
            @drop.stop="onDrop"
            @dragover.prevent>
            <li v-for="m in menuItemList" :key="m.id" :id="m.id" :class="{editMode: isEditingMode}"
                :aria-label="+m.enabled === 1 ? 'This card is enabled' : 'This card is not enabled'"
                :draggable="isEditingMode ? true : false"
                @dragstart.stop="onDragStart">
                <custom-menu-item :menuItem="m"></custom-menu-item>
                <div v-show="isEditingMode" class="edit_card">
                    <button type="button" @click="setMenuItem(m)" title="edit this card" class="edit_menu_card btn-general">
                        <span role="img" aria="">☰</span>
                    </button>
                    <div class="notify_disabled">{{+m.enabled === 1 ? 'enabled' : 'hidden'}}</div>
                </div>
            </li>
        </ul>
        <div v-show="isEditingMode" style="display:flex; flex-direction: column;">
            <div style="display:flex; gap: 1rem;">
                <button type="button" class="btn-general" @click="setMenuItem(null)">Create New Menu Item</button>
                <button v-if="!allBuiltinsPresent" type="button" class="btn-general" @click="addStarterButtons()">Add Starter Buttons</button>
            </div>
            <h3 style="margin: 0.5rem 0;">Homepage Menu is {{ publishedStatus.homepage === true ? '' : 'not'}} enabled</h3>
            <button type="button" class="btn-confirm" @click="postEnableTemplate('homepage')"
                style="width: 150px;" :disabled="isPostingUpdate">
                {{ publishedStatus.homepage === true ? 'Click to disable' : 'Click to enable'}}
            </button>
        </div>
    </div>`
}