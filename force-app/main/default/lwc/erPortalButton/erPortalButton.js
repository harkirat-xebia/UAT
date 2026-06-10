import { api, LightningElement } from 'lwc';

export default class ErPortalButton extends LightningElement {
  @api label;
  @api size;
  @api large;
  @api width;
  @api disabled;
  @api alignment;
  @api color;
  @api responsive;
  @api responsiveLeft;

  get btnClass() {
    let btnClass = 'slds-button btn';

    switch (this.alignment) {
      case 'right':
        btnClass += ' slds-float_right';
        break;
      case 'center':
        btnClass += ' slds-align_absolute-center';
        break;
      case 'left':
        btnClass += ' slds-float_left';
        break;
    }

    if (this.size === 'small') btnClass += ' small';
    if (this.width === 'full-width') btnClass += ' full-width';
    if (this.color === 'red') btnClass += ' red';
    if (this.responsive) btnClass += ' ' + this.responsive;
    if (this.responsiveLeft) btnClass += ' left';

    return btnClass;
  }

  get isDisabled() {
    console.log('isDisabled() >> ' + this.disabled);
    console.log('isDisabled()2 >> ' + (this.disabled == true));
    return this.disabled == true;
  }
}