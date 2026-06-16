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
import RCS_REQUIRED_ERROR from '@salesforce/label/c.Rcs_Number_Required_Label';
import VAT_FORMAT_ERROR from '@salesforce/label/c.codeTVAInvalid';
import VAT_EXEMPT from '@salesforce/label/c.codeTVAShouldBeEmpty';
import VAT_REQUIRED from '@salesforce/label/c.codeTVARequired';
import { loadStyle } from 'lightning/platformResourceLoader';
import ER_CUSTOM_CSS from '@salesforce/resourceUrl/EdenredCustomCSS'; 
import POSTAL_ERROR from '@salesforce/label/c.postalCodeError';
import RCS_NUM from '@salesforce/label/c.RCS_Number';
import RCS_NUM_PLACEHOLDER from '@salesforce/label/c.RCS_Number_Placeholder';
import RCS_NUM_HELP from '@salesforce/label/c.RCS_Number_Helptext';
import RCS_NUM_LINK_LABEL from '@salesforce/label/c.RCS_Number_Link_Label';
import REGISTRATION_NUM from '@salesforce/label/c.Registration_Number';
import REGISTRATION_NUM_PLACEHOLDER from '@salesforce/label/c.Registration_Number_Placeholder';
import REGISTRATION_NUM_HELP from '@salesforce/label/c.Registration_Number_Helptext';
import hasActiveContract from '@salesforce/apex/clientAutoEnrollmentComponentController.hasActiveContract';

export default class ClientAutoEnrollmentComponentPhase2 extends LightningElement {


    //Primitive Variables
    @api enterpriseNumber;
    @api registrationNumber;
    @api businessName;
    @api commercialName;
    @api codeTVA;
    @api streetNumber;
    @api city;
    @api postalCode;
    @api pays;
    @api businessUnit;
    @api vatCheckbox;
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
        rcsRequiredError: RCS_REQUIRED_ERROR,
        enterpriseHelp: ENTERPRISE_HELP,
        enterpriseHelpLU: ENTERPRISE_HELP_LU,
        codeTVAInvalid: VAT_FORMAT_ERROR,
        codeTVAShouldBeEmpty: VAT_EXEMPT,
        codeTVARequired: VAT_REQUIRED,
        postalCodeError: POSTAL_ERROR,
        rcsError: RCS_ERROR,
        rcsNum: RCS_NUM,
        rcsNumPlaceholder: RCS_NUM_PLACEHOLDER,
        rcsHelp: RCS_NUM_HELP,
        rcsLinkLabel: RCS_NUM_LINK_LABEL,
        registrationNum: REGISTRATION_NUM,
        registrationNumPlaceholder: REGISTRATION_NUM_PLACEHOLDER,
        registrationHelp: REGISTRATION_NUM_HELP
    };
    

    lbrUrl = 'https://www.lbr.lu';

    //Boolean Variables
    @api hasEnterpriseNumber;
    @api isWebOffer = false;
    @api promoCode;
    @api productCode;
    @api noOfBeneficiaries;

    @api
    getData() {
        return {
          enterpriseNum: this.enterpriseNumber,
          registrationNumber: this.registrationNumber,
          businessName: this.businessName,
          commercialName: this.commercialName,
          codeTVA: this.codeTVA,
          streetNumber: this.streetNumber,
          city: this.city,
          postalCode: this.postalCode,
          pays: this.pays,
          vatCheckbox: this.vatCheckbox
        };
      }
      
    get isLU() {
        return this.businessUnit === 'LU';
    }

    get enterpriseNum() {
        return this.isLU ? this.label.rcsNum : this.label.enterpriseNum;
    }

    get enterpriseNumPlaceholder() {
        return this.isLU ? this.label.rcsNumPlaceholder : this.label.enterpriseNumPlaceholder;
    }

    get enterpriseHelp() {
        return this.isLU ? this.label.rcsHelp : this.label.enterpriseHelp;
    }

    get enterpriseFormatError() {
        return this.isLU ? this.label.rcsError : this.label.vatError;
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
        hasActiveContract({ enterpriseNumber: this.isLU ? this.registrationNumber : this.enterpriseNumber })
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
      const rcsRegex = /^(?=.*[A-Za-z])(?=.*[0-9])[A-Za-z0-9]{1,9}$/;
      const codeTVARegex = /^(BE[0-2]{1}\d{9}|LU\d{8})$/i;
      const postalCodeRegex = /^\d+$/;

      const inputs = this.template.querySelectorAll('[data-form-element]');
      inputs.forEach(input => {
        const name = input.name;
        var value = input.value;
        if(this.businessUnit == 'BE'){
          value = this.businessUnit + input.value;
        }
        const rawValue = input.value ? input.value.trim() : '';
        console.log('Value to Test: ', value);
        // Custom validation for VAT field
        if (name === 'enterpriseNumber' && !this.hasEnterpriseNumber) {
            if(!rawValue){
                input.setCustomValidity(this.isLU ? this.label.rcsRequiredError : this.label.enterpriseError);
                input.reportValidity();
                isValid = false;
            } else if (this.isLU && !rcsRegex.test(rawValue)) {
                input.setCustomValidity(this.enterpriseFormatError);
                input.reportValidity();
                isValid = false;
            } else if (!this.isLU && !vatRegex.test(value)) {
                input.setCustomValidity(this.enterpriseFormatError);
                input.reportValidity();
                isValid = false;
            } else {
                input.setCustomValidity('');
            }
        }
        if (name === 'registrationNumber' && !this.hasEnterpriseNumber && this.isLU) {
            if (!rawValue) {
                input.setCustomValidity(this.label.rcsRequiredError);
                input.reportValidity();
                isValid = false;
            } else {
                input.setCustomValidity('');
            }
        }
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