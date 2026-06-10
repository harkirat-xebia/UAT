import { LightningElement, api } from 'lwc';

export default class ErPortalPicklist extends LightningElement {
  @api inputLabel;
  @api propertyName;
  @api value;
  @api pkEntries = [];
  @api required;
  @api disabled;
  @api hasError;
  @api errorMessage;
  @api displayCurValue = false;
  @api toolTipText;
  @api placeHolderText;

  get hasTooltip() {
    return this.toolTipText;
  }

  async connectedCallback() {
    // In order to trigger picklist initialization (done in parent component) after rendering
    const loadedEvent = new CustomEvent('loaded', {
      detail: { field: this.propertyName, value: 0 }
    });
    this.dispatchEvent(loadedEvent);
  }

  @api
  get displayedValue() {
    console.log('>>> displayedValue -- this.value: ' + this.value + ' for ' + this.propertyName);
    console.log('>>> displayedValue -- pkEntries: ' + JSON.stringify(this.pkEntries));
    let result;
    if (this.pkEntries && this.pkEntries.length > 0) {
      let entry = this.pkEntries.filter((elem) => elem.key == this.value);
      console.log('>>> displayedValue -- result: ' + (entry.length > 0 ? entry[0].value : this.value));
      result = entry.length > 0 ? entry[0].value : this.value;
      // TODO find a better solution, in case of displaying translated value like "Other". dirty fix for dependant picklist
    }
    return result;
  }

  handleChange(event) {
    const changeEvent = new CustomEvent('change', {
      detail: {
        field: this.propertyName,
        value: event.target.value,
        picklist: true
      }
    });
    this.value = event.target.value;
    console.log('>>> handleChange -- value: ' + this.value);
    this.dispatchEvent(changeEvent);
  }

  handleClick(event) {
    this.displayCurValue = false;
  }

  get pickListCssClass() {
    let cssClass = 'slds-select erportal-picklist ';
    if (this.hasError) cssClass = cssClass + ' has-error';
    return cssClass;
  }
}