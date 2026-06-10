import { LightningElement, api } from 'lwc';
import sendEnvelope from '@salesforce/apex/EmbeddedSigningController.sendEnvelope';
import getEmbeddedSigningUrl from '@salesforce/apex/EmbeddedSigningController.getEmbeddedSigningUrl';
import fetchSignedDocuments from '@salesforce/apex/EmbeddedSigningController.fetchSignedDocuments';

export default class EmbeddedSigningComponent extends LightningElement {

       template = '0916c5bf-6505-4ad0-b879-859535ef2c45';
       description = 'Embedded Signing';
       @api recordId;  
       globalEnvId; 
       handleClick() {
           sendEnvelope({template: this.template, description: this.description, recordId: this.recordId})
               .then((envelopeId) => {
                    
                   getEmbeddedSigningUrl({envId: envelopeId,url: window.location.href})
                   .then((signingUrl) => {
                        window.location.href = signingUrl;
                    })
                   console.log('eve id--->'+envelopeId);
                   this.globalEnvId = envelopeId;
                })
               .catch((error) => {
                   console.log('Error:');
                   console.log(error);
               });
       }

       handleFetchClick(){
            fetchSignedDocuments({envelopeIdStr: this.globalEnvId, recordId: this.recordId})
            .then(res=>{
                console.log('res',res);
            })
            .catch(error=>{
                console.log('error vin', error);
            })

       }

     

    
}