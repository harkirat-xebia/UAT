/**
 * @author: ALK
 * @date: 02/05/2023
 * @desc: lcerConfirmationDialog
 */

import { LightningElement, api } from 'lwc';

export default class LcerConfirmationDialog extends LightningElement {
  @api visible; //used to hide/show dialog
  @api title; //modal title
  @api message; //modal message
  @api confirmLabel; //confirm button label
  @api cancelLabel; //cancel button label

  handleCancel(event) {
    this.dispatchEvent(new CustomEvent('clickconfirmmodal', { detail: 'cancel' }));
  }

  handleConfirmation(event) {
    this.dispatchEvent(new CustomEvent('clickconfirmmodal', { detail: 'confirm' }));
  }
}