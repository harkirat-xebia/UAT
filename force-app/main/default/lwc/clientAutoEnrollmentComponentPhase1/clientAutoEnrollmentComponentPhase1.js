import { LightningElement, api, track, wire } from 'lwc';
import PHASE1_HEADER from '@salesforce/label/c.Phase1_Header';
import PHASE1_SUBHEADER from '@salesforce/label/c.Phase1_SubHeader';
import FIRST_NAME from '@salesforce/label/c.First_Name';
import FIRST_NAME_PLACEHOLDER from '@salesforce/label/c.First_Name_Placeholder';
import LAST_NAME from '@salesforce/label/c.Last_Name';
import LAST_NAME_PLACEHOLDER from '@salesforce/label/c.Last_Name_Placeholder';
import FUNCTION from '@salesforce/label/c.Function';
import SALUTATION from '@salesforce/label/c.Salutation';
import EMAIL from '@salesforce/label/c.Email';
import EMAIL_PLACEHOLDER from '@salesforce/label/c.Email_Placeholder';
import PHONE from '@salesforce/label/c.Phone';
import MOBILE_PLACEHOLDER from '@salesforce/label/c.Mobile_Phone_Placeholder';
import MOBILE_PHONE from '@salesforce/label/c.Mobile_Phone';
import PHONE_PLACEHOLDER from '@salesforce/label/c.Phone_Placeholder';
import LANGUAGE from '@salesforce/label/c.Language';
import OPTIN from '@salesforce/label/c.OPTIN_Checkbox';
import PHONEMOBERROR from '@salesforce/label/c.PhoneOrMobileError';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import JOB_TITLE_LABEL from '@salesforce/label/c.jobTitleLabel';
import DEPARTMENT_LABEL from '@salesforce/label/c.departmentLabel';
import SUB_DEPARTMENT_LABEL from '@salesforce/label/c.subDepartmentLabel';
import LEAD_OBJECT from '@salesforce/schema/Lead';
import LANGUAGE_FIELD from '@salesforce/schema/Lead.ER_Language__c';
import FUNCTION_FIELD from '@salesforce/schema/Lead.Business_Role__c'; 
import SALUTATION_FIELD from '@salesforce/schema/Lead.Salutation';
import DEPARTMENT_FIELD from '@salesforce/schema/Contact.ER_Department_Family__c';
import SUB_DEPARTMENT_FIELD from '@salesforce/schema/Contact.ER_SubDepartment_Family__c';
import { loadScript,loadStyle } from 'lightning/platformResourceLoader';
import ER_CUSTOM_CSS from '@salesforce/resourceUrl/EdenredCustomCSS'; 
import flagTelpicker from '@salesforce/resourceUrl/flagTelpicker';
import getPickListValues from '@salesforce/apex/clientAutoEnrollmentComponentController.getPickListValues';


export default class ClientAutoEnrollmentComponentPhase1 extends LightningElement {

    countryCodeOptions = [
        { label: '🇧🇪 Belgium', value: 'BE' },
        { label: '🇮🇳 India', value: 'IN' },
        { label: '🇫🇷 France', value: 'FR' }
    ];
    
    countryDialMap = {
        BE: '+32',
        IN: '+91',
        FR: '+33'
    };

    @api countryCode;
    @api dialCode;
    @api countryCodePhone;
    @api dialCodePhone;
    @api businessUnit;
    
    //imported variables
    @api noOfBeneficiaries;

    //Primitive
    @api salutation;
    @api firstName;
    @api lastName;
    @api language;
    @api role;
    @api email;
    @api phone;
    @api mobile;
    @api optin;
    @api selectedLanguage;
    @api jobTitle;
    @api department;
    @api subDepartment;

    //Collections
    label = {
        header: PHASE1_HEADER,
        subHeader: PHASE1_SUBHEADER,
        firstName: FIRST_NAME,
        lastName: LAST_NAME,
        firstNamePlaceholder: FIRST_NAME_PLACEHOLDER,
        lastNamePlaceholder: LAST_NAME_PLACEHOLDER,
        role: FUNCTION,
        salutation: SALUTATION,
        email: EMAIL,
        emailPlaceholder: EMAIL_PLACEHOLDER,
        phone: PHONE,
        mobile: MOBILE_PHONE,
        mobilePlaceholder: MOBILE_PLACEHOLDER,
        phonePlaceholder: PHONE_PLACEHOLDER,
        language: LANGUAGE,
        optin: OPTIN,
        phoneOrMobileError: PHONEMOBERROR,
        jobTitle: JOB_TITLE_LABEL,
        department: DEPARTMENT_LABEL,
        subDepartment: SUB_DEPARTMENT_LABEL
    };
    @track civilityOptions = [];
    @track languageOptions = [];
    @track functionOptions = [];
    @track departmentOptions = [];
    @track subDepartmentOptions = [];

    //Boolean Variables
    optin = false;
    flagInputInitialized  = false;
    showSubDepartment = false;
    @api isWebOffer = false;

    @api
    getData() {
        const phoneInput = this.template.querySelector('[data-id=phoneInput]');
        if (phoneInput && window.intlTelInputGlobals) {
            const itiPhone = window.intlTelInputGlobals.getInstance(phoneInput);
            if (itiPhone) {
                const fullPhone = itiPhone.getNumber();
                const countryDataPhone = itiPhone.getSelectedCountryData();
                this.dialCodePhone    = `+${countryDataPhone.dialCode}`;
                this.countryCodePhone = countryDataPhone.iso2.toUpperCase();
                this.phone            = fullPhone.replace(this.dialCodePhone, '').trim();
            }
        }

        const gsmInput = this.template.querySelector('[data-id=gsmInput]');
        if (gsmInput && window.intlTelInputGlobals) {
            const itiInstance = window.intlTelInputGlobals.getInstance(gsmInput);


            if (itiInstance) {
                const fullNumber = itiInstance.getNumber();
                const selectedCountryData = itiInstance.getSelectedCountryData();

                const dialCode = selectedCountryData.dialCode;
                const isoCode = selectedCountryData.iso2;

                this.dialCode = `+${dialCode}`;
                this.countryCode = isoCode.toUpperCase();
                this.mobile = fullNumber.replace(this.dialCode, '').trim();
            }
        }

        return {
            salutation: this.salutation,
            firstName: this.firstName,
            lastName:  this.lastName,
            language: this.language,
            role: this.role,
            email: this.email,
            phone: this.phone,
            countryCodePhone:this.countryCodePhone,
            dialCodePhone:   this.dialCodePhone,
            countryCode: this.countryCode,
            dialCode: this.dialCode,
            mobile:this.mobile,
            optin: this.optin,
            jobTitle: this.jobTitle,
            department: this.department,
            subDepartment: this.subDepartment
        };
    }

    connectedCallback(){
        this.fetchTranslatedPicklist(LANGUAGE_FIELD.fieldApiName, 'languageOptions', LEAD_OBJECT.objectApiName);
        this.fetchTranslatedPicklist(FUNCTION_FIELD.fieldApiName, 'functionOptions', LEAD_OBJECT.objectApiName);
        this.fetchTranslatedPicklist(SALUTATION_FIELD.fieldApiName, 'civilityOptions', LEAD_OBJECT.objectApiName);
        this.fetchTranslatedPicklist(DEPARTMENT_FIELD.fieldApiName, 'departmentOptions', CONTACT_OBJECT.objectApiName);
        this.fetchTranslatedPicklist(SUB_DEPARTMENT_FIELD.fieldApiName, 'subDepartmentOptions', CONTACT_OBJECT.objectApiName);

        loadStyle(this, ER_CUSTOM_CSS)
            .then(() => {
                console.log('Custom CSS loaded successfully');
            })
            .catch(error => {
                console.error('Error loading custom CSS:', error);
            });

        if (this.department === 'Executive Management') {
            this.showSubDepartment = true;
        }
    }
    async fetchTranslatedPicklist(fieldApiName, targetProperty, objectApiName, required = false) {
        this.isLoading = true;
        try {
            const data = await getPickListValues({
                objectApiName,
                fieldApiName,
                required,
                language: this.selectedLanguage,
                businessUnit: this.businessUnit
            });

            this[targetProperty] = Object.entries(data).map(([value, label]) => ({
                label: label,
                value: value
            }));
        } catch (error) {
            console.error(`Error fetching picklist for ${fieldApiName}:`, error);
        } finally{
            this.isLoading = false;
        }
    }
    renderedCallback() {
        if (this.flagInputInitialized) return;
        this.flagInputInitialized = true;
    
        Promise.all([
            loadStyle(this, flagTelpicker + '/css/intlTelInput.css'),
            loadScript(this, flagTelpicker + '/js/utils.js'),
            loadScript(this, flagTelpicker + '/js/intlTelInput.js')
        ])
        .then(() => {
            const input = this.template.querySelector('[data-id=gsmInput]');
            this.intlInput = window.intlTelInput(input, {
                initialCountry: this.countryCode?.toLowerCase() || 'be',
                separateDialCode: true,
                preferredCountries: ['lu', 'be', 'fr']
            });
    
            const countryData = this.intlInput.getSelectedCountryData();
            this.countryCode = countryData.iso2.toUpperCase();
            this.dialCode = `+${countryData.dialCode}`;
    
            input.addEventListener('countrychange', () => {
                const updated = this.intlInput.getSelectedCountryData();
                this.countryCode = updated.iso2.toUpperCase();
                this.dialCode = `+${updated.dialCode}`;
                console.log('Updated on country change:', this.countryCode, this.dialCode);
            });
    
            if (this.mobile) input.value = this.mobile;

            const phoneEl = this.template.querySelector('[data-id=phoneInput]');
            this.intlPhoneInput = window.intlTelInput(phoneEl, {
                initialCountry: this.countryCodePhone?.toLowerCase() || 'be',
                separateDialCode: true,
                preferredCountries: ['lu','be','fr']
            });
            let pData = this.intlPhoneInput.getSelectedCountryData();
            this.countryCodePhone = pData.iso2.toUpperCase();
            this.dialCodePhone    = `+${pData.dialCode}`;
            phoneEl.addEventListener('countrychange', () => {
                const pd = this.intlPhoneInput.getSelectedCountryData();
                this.countryCodePhone = pd.iso2.toUpperCase();
                this.dialCodePhone    = `+${pd.dialCode}`;
                console.log('Phone changed:', this.countryCodePhone, this.dialCodePhone);
            });
            if (this.phone) phoneEl.value = this.phone;

            if(this.isWebOffer){
                if (this.phone) {
                    phoneEl.value = this.phone;
                    this.intlPhoneInput.setNumber(this.phone);
                    const pData = this.intlPhoneInput.getSelectedCountryData();
                    this.countryCodePhone = pData.iso2.toUpperCase();
                    this.dialCodePhone = `+${pData.dialCode}`;
                }
                if (this.mobile) {
                    input.value = this.mobile;
                    this.intlInput.setNumber(this.mobile);
                    const mData = this.intlInput.getSelectedCountryData();
                    this.countryCode = mData.iso2.toUpperCase();
                    this.dialCode = `+${mData.dialCode}`;
                }
            }     
        })
        .catch(error => console.error('Flag picker load error:', error));
    }
    

    handleInputChange(event) {
        const field = event.target.name;
        if(field === 'optin'){
            this[field] = event.target.checked;
        }else if(field === 'department'){
            this[field] = event.target.value;
            if (this[field] === 'Executive Management') {
                this.showSubDepartment = true;
            }else{
                this.subDepartment = null;
                this.showSubDepartment = false;
            }
        }else{
            this[field] = event.target.value;
        }
        console.log(field, event.target.value);
        
    }
    handleMobileChange(event) {
        const inputValue = event.target.value;
        this.mobile = inputValue;
        console.log(`Mobile input: ${this.dialCode}${this.mobile}`);
    }
    handlePhoneChange(event) {
        const inputValue = event.target.value;
        this.phone = inputValue;
        console.log(`Phone input: ${this.dialCodePhone}${this.phone}`);
    }
    @api
    validateFields() {
        let isValid = true;
        const mobileRegex = /^[6-9]\d{9}$/;
        const phoneRegex = /^[0-9]{6,14}$/; 
        const inputs = this.template.querySelectorAll('[data-form-element]');
        inputs.forEach(input => {
            if (typeof input.reportValidity === 'function' && typeof input.checkValidity === 'function') {
                const name = input.name;
                if ((name === 'mobile' || name === 'phone') && !this.phone && !this.mobile) {
                    input.setCustomValidity(this.label.phoneOrMobileError);
                }/* else if (name === 'mobile' && this.mobile && !mobileRegex.test(this.mobile)) {
                    input.setCustomValidity('Enter a valid 10-digit mobile number.');
                }else if (name === 'phone' && this.phone && !phoneRegex.test(this.phone)) {
                    input.setCustomValidity('Enter a valid phone number (6–14 digits).');
                } */else {
                    input.setCustomValidity('');
                }

                if (!input.checkValidity()) {
                    input.reportValidity();
                    isValid = false;
                }
            }
        });
        return isValid;
    }


}