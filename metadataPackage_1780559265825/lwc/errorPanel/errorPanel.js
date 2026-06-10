/**
 * Created by noorgoolamnabee on 21/12/2022.
 */

import { LightningElement, api } from 'lwc';
import { reduceErrors } from 'c/utils';
import noDataIllustration from './templates/noDataIllustration.html';
import inlineMessage from './templates/inlineMessage.html';
import LAB_SF_LWC_ERROR_PANEL from '@salesforce/label/c.LAB_SF_LWC_ERROR_PANEL';

export default class ErrorPanel extends LightningElement {
  /** Single or array of LDS errors */
  @api errors;
  /** Generic / user-friendly message */
  @api friendlyMessage = LAB_SF_LWC_ERROR_PANEL;
  /** Type of error message **/
  @api type;

  viewDetails = false;

  get errorMessages() {
    return reduceErrors(this.errors);
  }

  handleShowDetailsClick() {
    this.viewDetails = !this.viewDetails;
  }

  render() {
    if (this.type === 'inlineMessage') return inlineMessage;
    return noDataIllustration;
  }
}