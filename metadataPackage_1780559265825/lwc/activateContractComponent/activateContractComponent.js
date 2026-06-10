import { LightningElement, api, track, wire} from 'lwc';
import activateContract from '@salesforce/apex/ActivateContractComponentController.activateContract';
import fetchContractDetails from '@salesforce/apex/ActivateContractComponentController.fetchContractDetails';
import fetchErrors from '@salesforce/apex/ActivateContractComponentController.fetchErrors';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class ActivateContractComponent extends LightningElement {
    @api recordId;
    @track contract = [];
    @track acc = {};
    @track errorList = [];
    @track errorMessage = '';
    @track syncAccountInfo = '';
    @track hasErrors = false;
    @track AccountCreatedInSysOp = false;
    @track ContractCreatedInSysOp = false;
    @track Spinner = false;
    contractId = '';
    accountId = '';
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            console.log('currentPageReference ', currentPageReference);
            //it gets executed before the connected callback and avilable to use
            this.recordId = currentPageReference.state.recordId;
        }
    }

    get accountName() {
        if(this.contract.length != 0){
            return this.contract[0].AccountName ? this.contract[0].AccountName : '';
        }
    }

    get contractNumber() {
        if(this.contract.length != 0){
            return this.contract[0].ContractNumber ? this.contract[0].ContractNumber : '';
        }
    }

    connectedCallback(){
        this.Spinner = true;
        this.fetchContractDetails();
    }
    fetchContractDetails() {
        console.log('this.recordId: ' , this.recordId);
        fetchContractDetails({ contractId: this.recordId })
            .then((result) => {
                console.log(result);
                this.contract = result;
                console.log(this.contract);
                this.contractId = this.contract[0].ContractId;
                this.accountId = this.contract[0].AccountId;
                this.fetchError();
            })
            .catch((error) => {
                console.error(error); // Log the error or handle it as needed
            });
    }

    fetchError(){
        fetchErrors({accountId: this.accountId, contractId: this.contractId})
            .then((result) => {
                this.Spinner = false;
                console.log(result);
                this.hasErrors = result.length != 0;
                this.errorList = result.flatMap(wrapper => wrapper.data);
                console.log('this.errorList: ', this.errorList);
                if(this.hasErrors){
                    this.errorMessage = result[0].count + ' error(s) to correct';
                }
            }).catch((error)=>{
                console.error(error);
            })
    }
    handleActivateContract(){
        this.Spinner = true;
        activateContract({contractId: this.contractId})
        .then((result)=>{
            console.log(result);
            if(result != null){
                this.Spinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Contract synced with NEMO successfully.',
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
                this.dispatchEvent(new CloseActionScreenEvent());
                /* updateContractStatus({contractId: this.contractId})
                .then((result)=>{
                    console.log('Success');
                    this.closeQuickAction();
                    
                }).catch((error)=>{
                    console.error(error);
                }) */
            }else{
                this.Spinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error Syncing Contract with NEMO. Try again later.',
                        variant: 'error',
                        mode: 'dismissable'
                    })
                );
                this.dispatchEvent(new CloseActionScreenEvent());
            }
        }).catch((error)=>{
            this.Spinner = false;
            console.error(error);
        })
    }
    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }


}