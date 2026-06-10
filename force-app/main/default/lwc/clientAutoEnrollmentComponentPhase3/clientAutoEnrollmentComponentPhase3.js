import { LightningElement, api, track, wire } from 'lwc';
import HEADER from '@salesforce/label/c.Phase3_Header';
import SUBHEADER from '@salesforce/label/c.Phase3_SubHeader';
import BENEF_SUB from '@salesforce/label/c.Beneficiary_sub_header';
import LAST_NAME from '@salesforce/label/c.Last_Name';
import LAST_NAME_PLACEHOLDER from '@salesforce/label/c.Last_Name_Placeholder';
import SHIPPING_STREET from '@salesforce/label/c.Shipping_Street';
import SHIPPING_POSTAL_CODE from '@salesforce/label/c.Shipping_Postal_Code';
import SHIPPING_COUNTRY from '@salesforce/label/c.Shipping_Country';
import SHIPPING_CITY from '@salesforce/label/c.Shipping_City';
import PHASE3_ADDRESS from '@salesforce/label/c.Phase3_Address';
import PHASE3_EMPLOYEES from '@salesforce/label/c.Phase3_Employees';
import PHASE3_BENEFLABL from '@salesforce/label/c.Phase3_BenefLabl';
import PHASE3_BENEF from '@salesforce/label/c.Phase3_Benef';
import FACE_VALUE_LABEL from '@salesforce/label/c.FaceValueLabel';
import YES_LABEL from '@salesforce/label/c.Yes';
import NO_LABEL from '@salesforce/label/c.No';
import SHIPPING_CITY_PLACEHOLDER from '@salesforce/label/c.Shipping_City_Placeholder';
import SHIPPING_CITY_PLACEHOLDER_LUX from '@salesforce/label/c.Shipping_City_Placeholder_Lux';
import SHIPPING_COUNTRY_PLACEHOLDER from '@salesforce/label/c.Shipping_Country_Placeholder';
import SHIPPING_COUNTRY_PLACEHOLDER_LUX from '@salesforce/label/c.Shipping_Country_Placeholder_Lux';
import SHIPPING_POSTAL_CODE_PLACEHOLDER from '@salesforce/label/c.Shipping_Postal_Code_Placeholder';
import SHIPPING_POSTAL_CODE_PLACEHOLDER_LUX from '@salesforce/label/c.Shipping_Postal_Code_Placeholder_Lux';
import SHIPPING_STREET_PLACEHOLDER from '@salesforce/label/c.Shipping_Street_Placeholder';
import SHIPPING_STREET_PLACEHOLDER_LUX from '@salesforce/label/c.Shipping_Street_Placeholder_Lux';
import BENEF_ERROR from '@salesforce/label/c.Benef_Greater_Than_Emp_Error';
import POSTAL_ERROR from '@salesforce/label/c.postalCodeError';
import getSettingsAttributes from '@salesforce/apex/clientAutoEnrollmentComponentController.getSettingsAttributes';
import getSMESizeLimit from '@salesforce/apex/clientAutoEnrollmentComponentController.getSMESizeLimit';

export default class ClientAutoEnrollmentComponentPhase3 extends LightningElement {

    //Primitive
    @api enterpriseNumber;
    @api noOfBeneficiaries;
    @api translatedProductName;
    @api faceValue = 0;
    @api noOfEmployees = 0;
    minFaceValue;
    maxFaceValue;
    @api shippingName;
    @api shippingStreet;
    @api shippingPostalCode;
    @api shippingCity;
    @api shippingCountry;
    @api maxBenefCount;
    @api productCode;
    smeSizeLimit;
    xxBeneficiaryCount;
    @api businessUnit;

    //Collection
    label = {
        header: HEADER,
        subHeader: SUBHEADER,
        beneficiarySubHeader: BENEF_SUB,
        shippingName: LAST_NAME,
        namePlaceholder: LAST_NAME_PLACEHOLDER,
        shippingStreet: SHIPPING_STREET,
        shippingPostalCode: SHIPPING_POSTAL_CODE,
        shippingCountry: SHIPPING_COUNTRY,
        shippingCity: SHIPPING_CITY,
        phase3Address: PHASE3_ADDRESS,
        phase3Employees: PHASE3_EMPLOYEES,
        phase3BenefLabl: PHASE3_BENEFLABL,
        phase3Benef: PHASE3_BENEF,
        faceValueLabel: FACE_VALUE_LABEL,
        yesLabel: YES_LABEL,
        noLabel: NO_LABEL,
        shippingCityPlaceholder: SHIPPING_CITY_PLACEHOLDER,
        shippingCountryPlaceholder: SHIPPING_COUNTRY_PLACEHOLDER,
        shippingPostalCodePlaceholder: SHIPPING_POSTAL_CODE_PLACEHOLDER,
        shippingStreetPlaceholder: SHIPPING_STREET_PLACEHOLDER,
        shippingCityPlaceholderLux: SHIPPING_CITY_PLACEHOLDER_LUX,
        shippingCountryPlaceholderLux: SHIPPING_COUNTRY_PLACEHOLDER_LUX,
        shippingPostalCodePlaceholderLux: SHIPPING_POSTAL_CODE_PLACEHOLDER_LUX,
        shippingStreetPlaceholderLux: SHIPPING_STREET_PLACEHOLDER_LUX,
        benefError: BENEF_ERROR,
        postalCodeError: POSTAL_ERROR
    };
    @api opportunityContactRolesMap;
    @api multiProductList;

    //Boolean
    isLoading = false;
    @api isEmployeeSameAsBenef;
    @api isBillingSameAsShipping;
    @api isWebOffer = false;

    @wire(getSettingsAttributes)
    wiredFaceValueSetting({ error, data }) {
        if (data) {
            console.log('data: ', data);
            const maxKey = `MaxFaceValue${this.productCode}`;
            const minKey = `MinFaceValue${this.productCode}`;
            console.log('maxKey: ', maxKey);
            console.log('minKey: ', minKey);

            this.maxFaceValue = Number(data[maxKey]);
            this.minFaceValue = Number(data[minKey]);
            this.faceValue = Number(this.maxFaceValue);
            console.log('this.maxFaceValue: ', this.maxFaceValue);
            console.log('this.minFaceValue: ', this.minFaceValue);
        } else if (error) {
            console.error('Error fetching custom metadata:', error);
        }
    }
    
    @wire(getSMESizeLimit)
    wiredSizeValue({ error, data }) {
        if (data) {
            this.smeSizeLimit = data;
        } else if (error) {
            console.error('Error fetching custom metadata:', error);
        }
    }

    get faceValuePlaceholder(){
        return this.businessUnit == 'BE' ? '8 €' : '15 €';
    } 
    get shippingStreetPlaceholder(){
        return this.businessUnit == 'BE' ? this.label.shippingStreetPlaceholder : this.label.shippingStreetPlaceholderLux;
    }
    get shippingCityPlaceholder(){
        return this.businessUnit == 'BE' ? this.label.shippingCityPlaceholder : this.label.shippingCityPlaceholderLux;
    }
    get shippingPostalCodePlaceholder(){
        return this.businessUnit == 'BE' ? this.label.shippingPostalCodePlaceholder : this.label.shippingPostalCodePlaceholderLux;
    }
    get shippingCountryPlaceholder(){
        return this.businessUnit == 'BE' ? this.label.shippingCountryPlaceholder : this.label.shippingCountryPlaceholderLux;
    }
    connectedCallback(){
        if(!this.isWebOffer){
            this.xxBeneficiaryCount = this.noOfBeneficiaries;
        }else{
            let max = 0;                         
            for (const item of this.multiProductList) {
                const n = item.nbOfBeneficiaries ?? 0; 
                if (n > max) max = n;
            }
            this.xxBeneficiaryCount = max;
            this.noOfBeneficiaries = max;
        }
    }

    handleInputChange(event) {
        const field = event.target.name;
        const value = event.detail?.value || event.target.value;
    
        if (event.target.type === 'checkbox' || event.target.type === 'toggle') {
            this[field] = event.target.checked;
            console.log(field, ' result: ', event.target.checked);
            
        }else{
            this[field] = value;
            console.log(field, ' result: ', value);
        }
    }

    increase(event) {
        const field = event.target.name;
        let max;
    
        if (field === 'faceValue') {
            max = this.maxFaceValue;
        } else if (field === 'noOfBeneficiaries') {
            max = this.smeSizeLimit;
        } else if (field === 'noOfEmployees') {
            max = this.maxBenefCount;
        } else {
            max = 9999;
        }
    
        if (this[field] < max) {
            let cleaned = this[field].toString().replace(/,/g, '');
            let numeric = parseFloat(cleaned);
            this[field] = numeric + 1;
        }
        console.log(field, ' result: ', this[field]);  
    }
    decrease(event) {
        const field = event.target.name;
        let min;
    
        if (field === 'faceValue') {
            min = this.minFaceValue;
        } else if (field === 'noOfBeneficiaries' || field === 'noOfEmployees') {
            min = 1;
        } else {
            min = 0; 
        }
    
        if (this[field] > min) {
            let cleaned = this[field].toString().replace(/,/g, '');
            let numeric = parseFloat(cleaned);
            this[field] = numeric - 1;
        }
        console.log(field, ' result: ', this[field]);  
    }

    @api
    getData() {
        return {
            faceValue: this.faceValue,
            noOfEmployees: this.noOfEmployees,
            noOfBeneficiaries: this.noOfBeneficiaries,

            shippingName: this.shippingName,
            shippingStreet: this.shippingStreet,
            shippingPostalCode: this.shippingPostalCode,
            shippingCity: this.shippingCity,

            shippingCountry: this.shippingCountry,
            isEmployeeSameAsBenef: this.isEmployeeSameAsBenef,
            isBillingSameAsShipping: this.isBillingSameAsShipping,
        };
    }
    @api
    validateFields() {
        let isValid = true;
        let employeeInput;
        const postalCodeRegex = /^\d+$/;
        const inputs = this.template.querySelectorAll('[data-form-element]');
        inputs.forEach(input => {
            if (typeof input.reportValidity === 'function' && typeof input.checkValidity === 'function') {
                if (!input.checkValidity()) {
                    input.reportValidity();
                    isValid = false;
                }
            }
            if (input.name === 'shippingPostalCode') {
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
            if(!this.isWebOffer){
                if (input.name === 'noOfBeneficiaries') {
                    employeeInput = input;
                    if (!this.isEmployeeSameAsBenef && this.noOfBeneficiaries > this.noOfEmployees) {
                        employeeInput.setCustomValidity(this.label.benefError);
                        employeeInput.reportValidity();
                        isValid = false;
                    }else {
                        if (employeeInput) {
                            employeeInput.setCustomValidity('');
                            employeeInput.reportValidity();
                        }
                    }
                    
                }
            }else{
                if (input.name === 'noOfEmployees') {
                    employeeInput = input;
                    if (!this.isEmployeeSameAsBenef && this.noOfBeneficiaries > this.noOfEmployees) {
                        employeeInput.setCustomValidity(this.label.benefError);
                        employeeInput.reportValidity();
                        isValid = false;
                    }else {
                        if (employeeInput) {
                            employeeInput.setCustomValidity('');
                            employeeInput.reportValidity();
                        }
                    }
                    
                }
            }
        }); 

        console.log('employeeInput: ', employeeInput);
        
        return isValid;
    }
}