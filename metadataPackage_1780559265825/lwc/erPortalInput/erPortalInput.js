import { LightningElement, api } from 'lwc';

export default class ErPortalInput extends LightningElement {
  @api inputLabel;
  @api propertyName;
  @api value;
  @api required = false;
  @api requiredConditional;
  @api disabled;
  @api hasError;
  @api errorMessage;
  @api autofocus;
  @api toolTipText;
  @api placeHolderText;
  @api maxLength;

  get hasTooltip() {
    return this.toolTipText;
  }

  async connectedCallback() {
    // console.log('--- ErPortalInput - connectedCallback. value= ' + this.value);
    if (this.value === undefined) this.value = ''; // To avoid field display "undefined"
  }

  get _value() {
    return this.value === undefined ? '' : this.value; // To avoid field display "undefined"
  }

  get hasInputLabel() {
    return this.inputLabel;
  }

  get inputCssClass() {
    let elemClass = 'slds-form-element';
    if (this.hasError) elemClass = elemClass + ' slds-has-error';

    return elemClass;
  }

  get inputCssClass2() {
    let elemClass = 'slds-input erportal-input';
    if (this.hasError) elemClass = elemClass + ' has-error';
    if (this.disabled) elemClass = elemClass + ' field__disabled';

    return elemClass;
  }

  handleChange(event) {
    const changeEvent = new CustomEvent('change', {
      detail: { field: this.propertyName, value: event.target.value }
    });
    this.dispatchEvent(changeEvent);
  }

  handleKeyup(event) {
    const changeEvent = new CustomEvent('keyup', {
      detail: { field: this.propertyName, value: event.target.value }
    });
    this.dispatchEvent(changeEvent);
  }
}