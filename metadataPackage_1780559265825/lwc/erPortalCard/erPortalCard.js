import { LightningElement, api } from 'lwc';

export default class ErPortalCard extends LightningElement {
  @api labels;
  @api isSelected;
  @api isMandatory;
  @api optionsList;
  @api isRadioBtn;
  @api isActivated;
  isChangingOption;

  get cardClass() {
    let cssClass = 'card-container ';
    cssClass += !this.isSelected && !this.isMandatory ? 'unselected' : 'selected';
    return cssClass;
  }

  get titleClass() {
    let cssClass = 'slds-hyphenate ';
    cssClass += this.isSelected ? 'selected-title' : 'unselected-title';
    return cssClass;
  }

  async connectedCallback() {
    if (this.isMandatory) this.isSelected = true;
    console.log('connectedCallback - labels = ' + JSON.stringify(this.labels));
  }

  handleClick(event) {
    if (!this.isMandatory && !this.isChangingOption && !this.isActivated) {
      this.isSelected = !this.isSelected;
      this.isChangingOption = false;
      console.log('handleClick - cardName: ' + this.labels.productCode);
      const clickEvent = new CustomEvent('click', {
        detail: { value: this.labels.productCode, isSelected: this.isSelected }
      });
      this.dispatchEvent(clickEvent);
      event.stopPropagation();
    } else {
      this.isChangingOption = false;
    }
  }

  handleOptionChange(event) {
    console.log('handleOptionChange - event.detail.value: ' + JSON.stringify(event.detail.value));
    console.log('handleOptionChange - event.detail.optionName: ' + JSON.stringify(event.detail.optionName));

    const changeEvent = new CustomEvent('change', {
      detail: { value: event.detail.value, optionName: event.detail.optionName }
    });
    this.dispatchEvent(changeEvent);
    console.log('handleOptionChange - changeEvent = ' + JSON.stringify(changeEvent));
    this.isChangingOption = true;
  }
}