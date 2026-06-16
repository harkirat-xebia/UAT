import { LightningElement, api, track } from 'lwc';

export default class RichHelptext extends LightningElement {
    @api content = '';
    @api linkUrl = '';
    @api linkLabel = '';
    @track isOpen = false;
    _hideTimer = null;

    get hasLink() {
        return !!(this.linkUrl && this.linkLabel);
    }

    show() {
        if (this._hideTimer) {
            clearTimeout(this._hideTimer);
            this._hideTimer = null;
        }
        this.isOpen = true;
    }

    hide() {
        this._hideTimer = setTimeout(() => {
            this.isOpen = false;
        }, 200);
    }
}
