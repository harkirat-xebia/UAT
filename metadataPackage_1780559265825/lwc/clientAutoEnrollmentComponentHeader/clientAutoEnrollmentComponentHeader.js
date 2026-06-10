import { LightningElement, track, wire } from 'lwc';
import LOGO from '@salesforce/resourceUrl/EdenredLogo';
import { loadStyle } from 'lightning/platformResourceLoader';
import { CurrentPageReference } from 'lightning/navigation';
import ER_CUSTOM_CSS from '@salesforce/resourceUrl/EdenredCustomCSS'; 

export default class ClientAutoEnrollmentComponentHeader extends LightningElement {

    logoUrl = LOGO;
    
    @track selectedLanguage = 'en_US';
    language;
    productCode;

    @wire(CurrentPageReference)
        currentPageReference;

    get languageOptions() {
        const options = [
            { label: 'FR', value: 'fr_BE' },
            { label: 'NL', value: 'nl_BE' },
            { label: 'EN', value: 'en_US' }
        ];

        const restrictedProducts = ['TRL', 'CLU', 'TCL'];

        if (restrictedProducts.includes(this.productCode)) {
            return options.filter(opt => opt.value !== 'nl_BE');
        }

        return options;
    }


    handleLanguageChange(event) {
        const newLanguage = event.detail.value;
    
        const currentState = this.currentPageReference.state;
    
        const newState = {
            ...currentState,
            language: newLanguage
        };
    
        const newUrl = window.location.pathname + '?' + this.encodeStateToQueryString(newState);
    
        window.location.href = newUrl;
    }
    
    encodeStateToQueryString(state) {
        return Object.keys(state)
            .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(state[key])}`)
            .join('&');
    }

    connectedCallback() { 
        this.productCode = this.currentPageReference.state.product;     
        loadStyle(this, ER_CUSTOM_CSS)
            .then(() => {
                console.log('Custom CSS loaded successfully');
            })
            .catch(error => {
                console.error('Error loading custom CSS:', error);
            });
            
        console.log('params: ', this.currentPageReference.state); 
        this.language = this.currentPageReference.state.language;
        this.selectedLanguage = this.language;

    }
}