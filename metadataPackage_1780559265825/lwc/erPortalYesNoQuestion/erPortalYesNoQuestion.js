import { api, LightningElement } from 'lwc';
export default class ErPortalYesNoQuestion extends LightningElement {
  @api questionLabel;
  @api toolTipText;
  @api yesLabel;
  @api noLabel;
  @api value;
  @api isDisabled;

  btnClassYes = 'slds-button btn unselected';
  btnClassNo = 'slds-button btn unselected';

  get hasTooltip() {
    return this.toolTipText;
  }

  async connectedCallback() {
    if (this.value) {
      this.btnClassYes = 'slds-button btn selected';
      this.btnClassNo = 'slds-button btn unselected';
    } else {
      this.btnClassYes = 'slds-button btn unselected';
      this.btnClassNo = 'slds-button btn selected';
    }
  }

  handleClick(event) {
    console.log('handleClick - event.target.value = ' + event.target.value);
    if (event.target.value == 'true') {
      this.btnClassYes = 'slds-button btn selected';
      this.btnClassNo = 'slds-button btn unselected';
      this.value = true;
    } else {
      this.btnClassYes = 'slds-button btn unselected';
      this.btnClassNo = 'slds-button btn selected';
      this.value = false;
    }
    const changeEvent = new CustomEvent('change', {
      detail: event.target.value
    });
    this.dispatchEvent(changeEvent);
    console.log('handleClick - changeEvent = ' + JSON.stringify(changeEvent));
  }
}