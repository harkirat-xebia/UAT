import { LightningElement, api } from 'lwc';

export default class ErPortalCbx extends LightningElement {
  @api inputLabel;
  @api isChecked;
  @api disabled;
  @api propertyName;
  @api toolTipText;

  get hasTooltip() {
    return this.toolTipText;
  }

  handleChange(event) {
    console.log('handleChange CBX - event.target.checked = ' + event.target.checked);
    const changeEvent = new CustomEvent('change', {
      detail: event.target.checked
    });
    this.isChecked = event.target.checked;
    this.dispatchEvent(changeEvent);
  }
}