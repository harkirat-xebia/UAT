import { LightningElement, api, track } from 'lwc';
import PHASE2_HEADER from '@salesforce/label/c.Phase2_Header';
import PHASE2_SUBHEADER from '@salesforce/label/c.Phase2_SubHeader';
import ENTERPRISE_NUM from '@salesforce/label/c.Enterprise_Number';
import ENTERPRISE_NUM_LU from '@salesforce/label/c.Enterprise_NumberLU';
import ENTERPRISE_PLACEHOLDER from '@salesforce/label/c.Enterprise_Number_Placeholder';
import ENTERPRISE_PLACEHOLDER_LU from '@salesforce/label/c.Enterprise_Number_PlaceholderLU';
import ENTERPRISE_HELP from '@salesforce/label/c.Enterprise_Number_Helptext';
import ENTERPRISE_HELP_LU from '@salesforce/label/c.Enterprise_Number_HelptextLU';
import COMPANY_NAME from '@salesforce/label/c.Company_Name';
import COMPANY_PLACEHOLDER from '@salesforce/label/c.Company_Name_Placeholder';
//New
import RCS_NUMBER from '@salesforce/label/c.RCS_Number';
import RCS_PLACEHOLDER from '@salesforce/label/c.RCS_Number_Placeholder';
import RCS_HELP from '@salesforce/label/c.RCS_Number_Helptext';
import COMMERCIAL_NAME from '@salesforce/label/c.Commercial_Name';
import COMMERCIAL_PLACEHOLDER from '@salesforce/label/c.Commercial_Name_Placeholder';
import SHIPPING_CITY from '@salesforce/label/c.Shipping_City';
import SHIPPING_CITY_PLACEHOLDER from '@salesforce/label/c.Shipping_City_Placeholder';
import SHIPPING_COUNTRY from '@salesforce/label/c.Shipping_Country';
import SHIPPING_COUNTRY_PLACEHOLDER from '@salesforce/label/c.Shipping_Country_Placeholder';
import VAT_NUMBER from '@salesforce/label/c.VAT_Number';
import SHIPPING_POSTAL_CODE from '@salesforce/label/c.Shipping_Postal_Code';
import SHIPPING_POSTAL_CODE_PLACEHOLDER from '@salesforce/label/c.Shipping_Postal_Code_Placeholder';
import SHIPPING_STREET from '@salesforce/label/c.Shipping_Street';
import SHIPPING_STREET_PLACEHOLDER from '@salesforce/label/c.Shipping_Street_Placeholder';
import VAT_ERROR from '@salesforce/label/c.Error_Message_Invalid_Enterprise_Number';
import RCS_ERROR from '@salesforce/label/c.Error_Message_Invalid_Enterprise_Number_LU';
import SUBJECT_TO_VAT from '@salesforce/label/c.Subject_to_VAT';
import ENTERPRISE_ERROR from '@salesforce/label/c.Enterprise_Required_Label';
import VAT_FORMAT_ERROR from '@salesforce/label/c.codeTVAInvalid';
import VAT_EXEMPT from '@salesforce/label/c.codeTVAShouldBeEmpty';
import VAT_REQUIRED from '@salesforce/label/c.codeTVARequired';
import { loadStyle } from 'lightning/platformResourceLoader';
import ER_CUSTOM_CSS from '@salesforce/resourceUrl/EdenredCustomCSS'; 
import POSTAL_ERROR from '@salesforce/label/c.postalCodeError';
import hasActiveContract from '@salesforce/apex/clientAutoEnrollmentComponentController.hasActiveContract';

export default class ClientAutoEnrollmentComponentPhase2 extends LightningElement {


    //Primitive Variables
    @api enterpriseNumber;
    @api businessName;
    @api commercialName;
    @api codeTVA;
    @api streetNumber;
    @api city;
    @api postalCode;
    @api pays;
    @api businessUnit;
    @api vatCheckbox;
    //New
    @api rcsNumber;
    @api registrationNumber;
    _hasCheckedActiveContract = false; // Added by harkirat
    isCompanyLocked = false;

    //Collections
    label = {
        header: PHASE2_HEADER,
        subHeader: PHASE2_SUBHEADER,
        enterpriseNum: ENTERPRISE_NUM,
        enterpriseNumPlaceholder: ENTERPRISE_PLACEHOLDER,
        enterpriseNumLU: ENTERPRISE_NUM_LU,
        enterpriseNumPlaceholderLU: ENTERPRISE_PLACEHOLDER_LU,
        companyName: COMPANY_NAME,
        companyNamePlaceholder: COMPANY_PLACEHOLDER,
        commercialName: COMMERCIAL_NAME,
        commercialNamePlaceholder: COMMERCIAL_PLACEHOLDER,
        codeTVA: VAT_NUMBER,
        shippingCity: SHIPPING_CITY,
        shippingCityPlaceholder: SHIPPING_CITY_PLACEHOLDER,
        shippingCountry: SHIPPING_COUNTRY,
        shippingCountryPlaceholder: SHIPPING_COUNTRY_PLACEHOLDER,
        shippingPostalCode: SHIPPING_POSTAL_CODE,
        shippingPostalCodePlaceholder: SHIPPING_POSTAL_CODE_PLACEHOLDER,
        shippingStreet: SHIPPING_STREET,
        shippingStreetPlaceholder: SHIPPING_STREET_PLACEHOLDER,
        vatError: VAT_ERROR,
        subjectToVat: SUBJECT_TO_VAT,
        enterpriseError: ENTERPRISE_ERROR,
        enterpriseHelp: ENTERPRISE_HELP,
        enterpriseHelpLU: ENTERPRISE_HELP_LU,
        codeTVAInvalid: VAT_FORMAT_ERROR,
        codeTVAShouldBeEmpty: VAT_EXEMPT,
        codeTVARequired: VAT_REQUIRED,
        postalCodeError: POSTAL_ERROR,
        rcsError: RCS_ERROR,
        // New RCS Labels
        rcsNumber: RCS_NUMBER,
        rcsPlaceholder: RCS_PLACEHOLDER,
        rcsHelp: RCS_HELP
        ,
        // Registration Number labels (fallback literals)
        registrationNumber: 'Registration Number',
        registrationPlaceholder: 'Registration Number',
        registrationHelp: 'Registration number'
    };
    

    //Boolean Variables
    @api hasEnterpriseNumber;
    @api isWebOffer = false;
    @api promoCode;
    @api productCode;
    @api noOfBeneficiaries;

    @api
    getData() {
        const data = {
          enterpriseNum: this.enterpriseNumber,
          businessName: this.businessName,
          commercialName: this.commercialName,
          codeTVA: this.codeTVA,
          streetNumber: this.streetNumber,
          city: this.city,
          postalCode: this.postalCode,
          pays: this.pays,
          vatCheckbox: this.vatCheckbox
        };
        
        // Add LU specific field
        if (this.businessUnit === 'LU') {
            data.rcsNumber = this.rcsNumber;
            data.registrationNumber = this.registrationNumber;
        }
        
        return data;
    }
      
    get enterpriseNum() {
        return this.businessUnit === 'LU' ? this.label.enterpriseNumLU : this.label.enterpriseNum;
    }
    
    get enterpriseNumPlaceholder() {
        return this.businessUnit === 'LU' ? this.label.enterpriseNumPlaceholderLU : this.label.enterpriseNumPlaceholder;
    }

    get enterpriseHelp() {
      return this.businessUnit === 'LU' ? this.label.enterpriseHelpLU : this.label.enterpriseHelp;
    }
    get enterpriseFormatError() {
      return this.businessUnit === 'LU' ? this.label.rcsError : this.label.vatError;
    }

        // Show LU specific fields in template
        get isLuxembourg() {
            return this.businessUnit === 'LU';
        }

    connectedCallback(){
      console.log('Phase2 connectedCallback, hasEnterpriseNumber =', this.hasEnterpriseNumber, 'enterpriseNumber =', this.enterpriseNumber);//Remove this later
        window.dataLayer = window.dataLayer || [];
        window.dataLayer.push({
            event: 'funnel',
            funnel_step: 'Step2enterprisebeforecompanynumber',
            promoCode: this.promoCode || '',
            light_offer: this.isWebOffer,
            funnel_product: this.productCode,
            numberofBeneficiaries: this.noOfBeneficiaries,
            error_status: []
        });
        console.log('Check: ', this.label.enterpriseHelp)
        loadStyle(this, ER_CUSTOM_CSS)
            .then(() => {
                console.log('Custom CSS loaded successfully');
            })
            .catch(error => {
                console.error('Error loading custom CSS:', error);
            });
        //     if (this.hasEnterpriseNumber && this.enterpriseNumber) {
        //     console.log('connectedCallback calling checkActiveContract');
        //     this.checkActiveContract();
        // }
    }

    //Added by harkirat
    renderedCallback() {
    console.log('Phase2 renderedCallback: hasEnterpriseNumber =', this.hasEnterpriseNumber,
                '| enterpriseNumber =', this.enterpriseNumber,
                '| hasChecked =', this._hasCheckedActiveContract);

    // Only run when:
    // 1) enterpriseNumber is present
    // 2) hasEnterpriseNumber is true
    // 3) we haven't already checked
    if (this.hasEnterpriseNumber && this.enterpriseNumber && !this._hasCheckedActiveContract) {
        this._hasCheckedActiveContract = true;
        this.checkActiveContract();
    }
}
    
    
    checkActiveContract() {
        console.log('checkActiveContract called with enterpriseNumber =', this.enterpriseNumber);
        hasActiveContract({ enterpriseNumber: this.enterpriseNumber })
            .then(result => {
                console.log('hasActiveContract result =', result);
                this.isCompanyLocked = result;   // true => lock fields
            })
            .catch(error => {
                console.error('Error in hasActiveContract:', error);
                this.isCompanyLocked = false;
            });
    }
    
    handleInputChange(event) {
        const field = event.target.name;
        if(field == 'vatCheckbox'){
            this[field] = event.target.checked;
            if(this[field] == true){
                this.codeTVA = '';
            }
            console.log(field, this[field]);
        }else{
            this[field] = event.target.value;
            console.log(field, event.target.value);
        }
        
        
    }

    //Added by harkirat
    get lockCompanyFields() {
        return this.isCompanyLocked;
    }
    

    @api
    validateFields() {
      let isValid = true;
      const vatRegex = /^([A-Z][0-9]{1,6}|BE[0-9]{10})$/;
      const codeTVARegex = /^(BE[0-2]{1}\d{9}|LU\d{8})$/i;
      const postalCodeRegex = /^\d+$/;
      //NEw
      const rcsRegex = /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{1,9}$/;
    const registrationRegex = rcsRegex;

      const inputs = this.template.querySelectorAll('[data-form-element]');
      inputs.forEach(input => {
        const name = input.name;  
        var value = input.value;
        if(this.businessUnit == 'BE'){
          value = this.businessUnit + input.value;
        }
        const rawValue = input.value ? input.value.trim() : '';
        console.log('Value to Test: ', value);
        //New 

        // For Luxembourg, validate RCS
        if (this.businessUnit === 'LU' && !this.hasEnterpriseNumber) {
            // Validate RCS
            if (name === 'rcsNumber') {
                if (!rawValue) {
                    input.setCustomValidity('RCS Number is required');
                    input.reportValidity();
                    isValid = false;
                } else if (!rcsRegex.test(rawValue)) {
                    input.setCustomValidity('Invalid RCS format. Must be 1-9 alphanumeric characters (both letters and digits required)');
                    input.reportValidity();
                    isValid = false;
                } else {
                    input.setCustomValidity('');
                }
            }
            // Validate Registration Number
            if (name === 'registrationNumber') {
                if (!rawValue) {
                    input.setCustomValidity(this.label.registrationHelp || 'Registration number is required');
                    input.reportValidity();
                    isValid = false;
                } else if (!registrationRegex.test(rawValue)) {
                    input.setCustomValidity(this.label.rcsError || 'Invalid registration number format');
                    input.reportValidity();
                    isValid = false;
                } else {
                    input.setCustomValidity('');
                }
            }
            
            // Validate Enterprise Number for LU (acts as NIF)
            if (name === 'enterpriseNumber') {
                if (!rawValue) {
                    input.setCustomValidity(this.label.enterpriseError);
                    input.reportValidity();
                    isValid = false;
                } else {
                    input.setCustomValidity('');
                }
            }
        } else if (name === 'enterpriseNumber' && !this.hasEnterpriseNumber && this.businessUnit !== 'LU') {
            // Original validation for non-LU business units
            if(!rawValue){
                input.setCustomValidity(this.label.enterpriseError);
                input.reportValidity();
                isValid = false;
            } else if (!vatRegex.test(value)) {
                input.setCustomValidity(this.enterpriseFormatError);
                input.reportValidity();
                isValid = false;
            } else {
                input.setCustomValidity('');
            }
        } 
        //Vat Validation
        if (name === 'codeTVA') {
            if (this.vatCheckbox && rawValue) {
              input.setCustomValidity(this.label.codeTVAShouldBeEmpty);
              input.reportValidity();
              isValid = false;
            } else if (!this.vatCheckbox) {
              if (!rawValue) {
                input.setCustomValidity(this.label.codeTVARequired);
                input.reportValidity();
                isValid = false;
              } else if (!codeTVARegex.test(rawValue)) {
                input.setCustomValidity(this.label.codeTVAInvalid);
                input.reportValidity();
                isValid = false;
              } else {
                input.setCustomValidity('');
              }
            } else {
              input.setCustomValidity('');
            }
        }
        if (input.name === 'postalCode') {
          const postalCodeValue = input.value ? input.value.trim() : '';
          if (postalCodeValue && !postalCodeRegex.test(postalCodeValue)) {
              input.setCustomValidity(this.label.postalCodeError);
              input.reportValidity();
              isValid = false;
          } else {
              input.setCustomValidity('');
              input.reportValidity();
          }
      }

        if (typeof input.reportValidity === 'function' && typeof input.checkValidity === 'function') {
            if (!input.checkValidity()) {
                  input.reportValidity();
                  isValid = false;
            }
          }
      });
      return isValid;
    }

}