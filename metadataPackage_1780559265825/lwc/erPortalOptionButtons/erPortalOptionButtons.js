import { LightningElement, api } from 'lwc';

const defaultBtnClass1 = 'slds-button btn choice1';
const defaultBtnClass2 = 'slds-button btn choice2';
const defaultLabelClass = "option-text";

export default class ErPortalOptionButtons extends LightningElement {
  // @api questionLabel = "How do you want to use the benefits?";
  // @api toolTipText;
  // @api choice1Label = "Virtual Card";
  // @api choice2Label = "Physical Card";
  @api optionName;
  @api optionText;
  @api toolTipText;
  @api choice1Label;
  @api choice2Label;
  @api value;

  btnClassChoice1 = defaultBtnClass1 + ' selected';
  btnClassChoice2 = defaultBtnClass2 + ' unselected';

  get hasTooltip() {
    return this.toolTipText;
  }

  get showOptions() {
    return this.choice1Label && this.choice2Label;
  }

  get labelClass(){
    let lbClass = defaultLabelClass;
    if (!this.choice1Label && !this.choice2Label) lbClass += " option-text-selected";
    return lbClass;
  }

  async connectedCallback() {
    if (this.value == this.choice1Label){

      this.btnClassChoice1 = defaultBtnClass1 + ' selected';
      this.btnClassChoice2 = defaultBtnClass2 + ' unselected';
    } else {
      this.btnClassChoice1 = defaultBtnClass1 + ' unselected';
      this.btnClassChoice2 = defaultBtnClass2 + ' selected';
    }
  }

  handleClick(event) {
    console.log('handleClick - event.target.id = ' + event.target.id);
    console.log('handleClick - event.target.value = ' + event.target.value);
    if (event.target.value == 'true') {
      this.btnClassChoice1 = defaultBtnClass1 + ' selected';
      this.btnClassChoice2 = defaultBtnClass2 + ' unselected';
      this.value = this.choice1Label;
    } else {
      this.btnClassChoice1 = defaultBtnClass1 + ' unselected';
      this.btnClassChoice2 = defaultBtnClass2 + ' selected';
      this.value = this.choice2Label;
    }
    const changeEvent = new CustomEvent('change', { detail: { value: this.value, optionName: this.optionName } });
    this.dispatchEvent(changeEvent);
    console.log('handleClick - changeEvent = ' + JSON.stringify(changeEvent));
  }
}