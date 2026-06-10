import { LightningElement, api } from 'lwc';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class ErChangeDataNotificationComponent extends LightningElement {
  @api recordId;
  @api channelName;

  subscription = {}; //subscription information

  // Initializes the component
  connectedCallback() {
    this.handleSubscribe();
    // Register error listener
    this.registerErrorListener();
  }

  // Handles subscribing
  handleSubscribe() {
    // Callback invoked whenever a new event message is received
    const messageCallback = (response) => {
      console.log('New message received: ', JSON.stringify(response));
      // Response contains the payload of the new message received
      this.handleNotification(response);
    };

    // Invoke subscribe method of empApi. Pass reference to messageCallback
    subscribe(this.channelName, -1, messageCallback).then((response) => {
      // Response contains the subscription information on subscribe call
      console.log('Subscription request sent to: ', JSON.stringify(response.channel));
      this.subscription = response;
      this.handleNotification(response);
    });
  }

  // Handles unsubscribing
  handleUnsubscribe() {
    // Invoke unsubscribe method of empApi
    unsubscribe(this.subscription, (response) => {
      console.log('unsubscribe() response: ', JSON.stringify(response));
      // Response is true for successful unsubscribe
    });
  }

  registerErrorListener() {
    // Invoke onError empApi method
    onError((error) => {
      console.log('Received error from server: ', JSON.stringify(error));
      // Error contains the server-side error
    });
  }

  //this method checks if current record got updated and shows message on UI
  handleNotification(response) {
    if (response.hasOwnProperty('data')) {
      let jsonObj = response.data;

      if (jsonObj.hasOwnProperty('payload')) {
        let payload = response.data.payload;
        let recordIds = payload.ChangeEventHeader.recordIds;

        //find the current recordId in the array and if found then display message
        const recId = recordIds.find((element) => element == this.recordId);
        if (recId != undefined) {
          eval("$A.get('e.force:refreshView').fire();");
        }
      }
    }
  }
}