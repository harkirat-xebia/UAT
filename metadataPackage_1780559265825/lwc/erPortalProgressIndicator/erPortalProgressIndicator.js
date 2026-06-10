import { LightningElement, api } from 'lwc';

export default class ErPortalProgressIndicator extends LightningElement {
  @api steps = [];
  @api currentStep;

  @api
  get step1() {
    this.setState();
    return this.steps[0];
  }

  @api
  get subsequentSteps() {
    0;
    return this.steps.slice(1);
  }

  setState() {
    let curStep = this.currentStep;
    let steps2 = [];
    this.steps.forEach(function (step) {
      let stepState = (step.nb === curStep) ? 'active' : 'inactive';
      steps2.push({ nb: step.nb, label: step.label, state: stepState });
    });
    this.steps = steps2;
  }
}