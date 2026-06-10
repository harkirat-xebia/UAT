// Refreshed and complete JS with full contact role support, logging, and label handling

import { LightningElement, api, track, wire } from 'lwc';
import fetchContactFromAccount from '@salesforce/apex/clientAutoEnrollmentComponentController.fetchContactFromAccount';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import LANGUAGE_FIELD from '@salesforce/schema/Contact.ER_Language__c';
import FUNCTION_FIELD from '@salesforce/schema/Contact.Business_Role__c';
import SALUTATION_FIELD from '@salesforce/schema/Contact.Salutation';
import { loadScript,loadStyle } from 'lightning/platformResourceLoader';
import ER_CUSTOM_CSS from '@salesforce/resourceUrl/EdenredCustomCSS';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import SOCIAL_SECRETARY from '@salesforce/schema/Account.BE_Social_Secretary_Name__c';

// Label imports
import PHONEMOBERROR from '@salesforce/label/c.PhoneOrMobileError';
import SUBHEADER from '@salesforce/label/c.PhaseContact_SubHeader';
import HEADER from '@salesforce/label/c.PhaseContact_Header';
import OPERATIONAL_CONTACT from '@salesforce/label/c.Operational_Role_Delivery_Contact';
import OPERATIONAL_CONTACT_DESCRIPTION from '@salesforce/label/c.Operational_Role_Delivery_Contact_Description';
import OPERATIONAL_INVOICING_CONTACT from '@salesforce/label/c.Operational_Role_Invoicing_Contact';
import OPERATIONAL_INVOICING_CONTACT_DESCRIPTION from '@salesforce/label/c.Operational_Role_Invoicing_Contact_Description';
import OPERATIONAL_MAIN_CONTACT from '@salesforce/label/c.Operational_Role_Main_Contact';
import OPERATIONAL_MAIN_CONTACT_DESCRIPTION from '@salesforce/label/c.Operational_Role_Main_Contact_Description';
import OPERATIONAL_ORDER_CONTACT from '@salesforce/label/c.Operational_Role_Order_Contact';
import OPERATIONAL_ORDER_CONTACT_DESCRIPTION from '@salesforce/label/c.Operational_Role_Order_Contact_Description';
import SELECT_LABEL from '@salesforce/label/c.SelectContactLabel';
import ADD_LABEL from '@salesforce/label/c.AddContactLabel';
import ADD_LABEL_BUTTON from '@salesforce/label/c.addContactButton';
import ADD_LABEL_SUB from '@salesforce/label/c.AddContactModal_SubHeader';
import EXISTING_CONTACT from '@salesforce/label/c.ExistingContactLabel';
import CREATE_CONTACT from '@salesforce/label/c.CreateNewContact';
import CREATE_CONTACT_SUB from '@salesforce/label/c.CreateNewContactSubHeader';
import SAVE_LABEL from '@salesforce/label/c.LABS_SF_Opp_Price_Save';
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
import PHONE_PLACEHOLDER from '@salesforce/label/c.Phone_Placeholder';
import LANGUAGE from '@salesforce/label/c.Language';
import DELETE_CONTACT_HEADER from '@salesforce/label/c.DeleteContactHeader';
import DELETE_CONTACT_SUBHEADER from '@salesforce/label/c.DeleteContactSubHeader';
import DELETE_WARNING from '@salesforce/label/c.DeleteWarning';
import DELETE_BUTTON_LABEL from '@salesforce/label/c.DeleteButtonLabel';
import SECRETARY_LABEL from '@salesforce/label/c.Social_Secretary_Name';
import SECRETARY_CHOICE_LABEL from '@salesforce/label/c.Social_Secretary_is_in_charge_of_orders';
import YES_LABEL from '@salesforce/label/c.Yes';
import NO_LABEL from '@salesforce/label/c.No';
import flagTelpicker from '@salesforce/resourceUrl/flagTelpicker';
import MODIFY_CONTACT_SUB from '@salesforce/label/c.ModifyContactSubHeader';
import MODIFY_CONTACT from '@salesforce/label/c.ModifyContactLabel';
import CONTACT_EMPTY_ERROR from '@salesforce/label/c.contactEmptyError';
import getPickListValues from '@salesforce/apex/clientAutoEnrollmentComponentController.getPickListValues';
import DEPARTMENT_FIELD from '@salesforce/schema/Contact.ER_Department_Family__c';
import SUB_DEPARTMENT_FIELD from '@salesforce/schema/Contact.ER_SubDepartment_Family__c';
import JOB_TITLE_LABEL from '@salesforce/label/c.jobTitleLabel';
import DEPARTMENT_LABEL from '@salesforce/label/c.departmentLabel';
import SUB_DEPARTMENT_LABEL from '@salesforce/label/c.subDepartmentLabel';

export default class ClientAutoEnrollmentComponentPhaseContact extends LightningElement {
    @api enterpriseNumber;
    @api opportunityId;
    @api primaryContactId;
    @api billingContactId;
    @api orderContactId;
    @api deliveryContactId;

    @track modalTitle = '';
    @track selectedContactId = '';
    @api mapOfContacts = {};
    @track contactOptions = [];

    @track civilityOptions = [];
    @track languageOptions = [];
    @track functionOptions = [];
    @track socialSecretaryOptions = [];

    primaryContactDisplayName = '';
    billingContactDisplayName = '';
    orderContactDisplayName = '';
    deliveryContactDisplayName = '';

    @api selectedLanguage;

    @api salutationContact;
    @api firstNameContact;
    @api lastNameContact;
    @api languageContact;
    @api roleContact;
    @api emailContact;
    @api phoneContact;
    @api mobileContact;
    @api countryCodeContact;
    @api dialCodeContact;
    @api countryCodeContactPhone;
    @api dialCodeContactPhone;
    @api socialSecretary;
    @api jobTitle;
    @api department;
    @api subDepartment;

    @api promoCode;
    @api productCode;
    @api noOfBeneficiaries;

    contactCounter = 1;
    @track isDeleteConfirmationModalOpen = false;
    @track contactToDelete = null;
    @track contactToDeleteName = '';

    isLoading = false;
    @track isModalOpen = false;
    showAddContactSection = false;
    isEditing = false;
    flagInputInitialized  = false;
    @api isSocialSecretaryHandlingOrders = false;
    @api isWebOffer = false;
    showSecretaryToggle = true;
    @api businessUnit;
    showSubDepartment = false;

    @track departmentOptions = [];
    @track subDepartmentOptions = [];


    label = {
        header: HEADER,
        subHeader: SUBHEADER,
        delivery_contact: OPERATIONAL_CONTACT,
        delivery_contact_description: OPERATIONAL_CONTACT_DESCRIPTION,
        invoicing_contact: OPERATIONAL_INVOICING_CONTACT,
        invoicing_contact_description: OPERATIONAL_INVOICING_CONTACT_DESCRIPTION,
        main_contact: OPERATIONAL_MAIN_CONTACT,
        main_contact_description: OPERATIONAL_MAIN_CONTACT_DESCRIPTION,
        order_contact: OPERATIONAL_ORDER_CONTACT,
        order_contact_description: OPERATIONAL_ORDER_CONTACT_DESCRIPTION,
        selectLabel: SELECT_LABEL,
        addContact: ADD_LABEL,
        modalSubHeader: ADD_LABEL_SUB,
        existingContact: EXISTING_CONTACT,
        createContact: CREATE_CONTACT,
        saveLabel: SAVE_LABEL,
        firstName: FIRST_NAME,
        lastName: LAST_NAME,
        firstNamePlaceholder: FIRST_NAME_PLACEHOLDER,
        lastNamePlaceholder: LAST_NAME_PLACEHOLDER,
        role: FUNCTION,
        salutation: SALUTATION,
        email: EMAIL,
        emailPlaceholder: EMAIL_PLACEHOLDER,
        phone: PHONE,
        mobilePlaceholder: MOBILE_PLACEHOLDER,
        phonePlaceholder: PHONE_PLACEHOLDER,
        language: LANGUAGE,
        deleteContactHeader: DELETE_CONTACT_HEADER,
        deleteContactSubHeader: DELETE_CONTACT_SUBHEADER,
        deleteWarning: DELETE_WARNING,
        deleteButtonLabel: DELETE_BUTTON_LABEL,
        secretaryLabel: SECRETARY_LABEL,
        secretaryChoice: SECRETARY_CHOICE_LABEL,
        yesLabel: YES_LABEL,
        noLabel: NO_LABEL,
        addContactButton: ADD_LABEL_BUTTON,
        createNewContactSubHeader: CREATE_CONTACT_SUB,
        modifyContactLabel: MODIFY_CONTACT,
        modifyContactSubHeader: MODIFY_CONTACT_SUB,
        contactEmptyError: CONTACT_EMPTY_ERROR,
        phoneOrMobileError: PHONEMOBERROR,
        jobTitle: JOB_TITLE_LABEL,
        department: DEPARTMENT_LABEL,
        subDepartment: SUB_DEPARTMENT_LABEL
    };

    @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT }) contactMetadata;

    get isBUBelgium(){
        return this.businessUnit == 'BE';
    }
    connectedCallback() {

        this.fetchTranslatedPicklist(LANGUAGE_FIELD.fieldApiName, 'languageOptions', CONTACT_OBJECT.objectApiName);
        this.fetchTranslatedPicklist(FUNCTION_FIELD.fieldApiName, 'functionOptions', CONTACT_OBJECT.objectApiName);
        this.fetchTranslatedPicklist(SALUTATION_FIELD.fieldApiName, 'civilityOptions', CONTACT_OBJECT.objectApiName);
        this.fetchTranslatedPicklist(SOCIAL_SECRETARY.fieldApiName, 'socialSecretaryOptions', ACCOUNT_OBJECT.objectApiName);
        this.fetchTranslatedPicklist(DEPARTMENT_FIELD.fieldApiName, 'departmentOptions', CONTACT_OBJECT.objectApiName);
        this.fetchTranslatedPicklist(SUB_DEPARTMENT_FIELD.fieldApiName, 'subDepartmentOptions', CONTACT_OBJECT.objectApiName);

        this.socialSecretary = 'No Secretary Social';
        if(this.socialSecretary == 'No Secretary Social'){
            this.showSecretaryToggle = false;
        }else{
            this.showSecretaryToggle = true;
        }

        loadStyle(this, ER_CUSTOM_CSS).then(() => console.log('Custom CSS loaded'));
        if (this.mapOfContacts && Object.keys(this.mapOfContacts).length > 0) {
            console.log('Using passed mapOfContacts from parent.');
            this.setContactOptions();
            this.setDisplayNames();
            this.initializeContactCounter();
        } else {
            console.log('Fetching contacts from server because mapOfContacts is empty.');
            this.fetchContacts();
        }
    }

    async fetchTranslatedPicklist(fieldApiName, targetProperty, objectApiName, required = false) {
        this.isLoading = true;
        try {
            const data = await getPickListValues({
                objectApiName,
                fieldApiName,
                required,
                language: this.selectedLanguage
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
    initializeContactCounter() {
        const tempKeys = Object.keys(this.mapOfContacts).filter(key => key.startsWith('contact'));
        if (tempKeys.length > 0) {
            const numbers = tempKeys.map(k => parseInt(k.replace('contact', ''))).filter(n => !isNaN(n));
            if (numbers.length > 0) {
                this.contactCounter = Math.max(...numbers) + 1;
                console.log('Initialized contactCounter to:', this.contactCounter);
            }
        }
    }
    
    renderedCallback() {
        if (this.flagInputInitialized) {
            return;
        }
        this.flagInputInitialized = true;
    
        Promise.all([
            loadStyle(this, flagTelpicker + '/css/intlTelInput.css'),
            loadScript(this, flagTelpicker + '/js/utils.js'),
            loadScript(this, flagTelpicker + '/js/intlTelInput.js')
        ])
        .then(() => {
            console.log('FlagTelPicker resources loaded successfully');
            this.initializeFlagPicker();
            this.initializeFlagPickerPhone();
        })
        .catch(error => {
            console.error('Error loading FlagTelPicker resources:', error);
        });
    }
    getInitialCountry() {
        if (!this.businessUnit) return 'be';

        const bu = this.businessUnit.toUpperCase();
        return bu === 'LU' ? 'lu' : 'be';
    }
    initializeFlagPicker(callback) {
        const input = this.template.querySelector('[data-id=gsmInput]');
        if (!input || !window.intlTelInput) return;
    
        this.intlInput = window.intlTelInput(input, {
            initialCountry: (this.countryCodeContact 
                    ? this.countryCodeContact.toLowerCase() 
                    : this.getInitialCountry()),
            separateDialCode: true,
            preferredCountries: ['lu', 'be', 'fr']
        });
    
        const countryData = this.intlInput.getSelectedCountryData();
        this.countryCodeContact = countryData.iso2.toUpperCase();
        this.dialCodeContact = `+${countryData.dialCode}`;
    
        input.addEventListener('countrychange', () => {
            const updated = this.intlInput.getSelectedCountryData();
            this.countryCodeContact = updated.iso2.toUpperCase();
            this.dialCodeContact = `+${updated.dialCode}`;
            console.log('Updated on country change:', this.countryCodeContact, this.dialCodeContact);
        });
    
        if (typeof callback === 'function') {
            callback();
        }
    }
    initializeFlagPickerPhone(callback) {
        const phone = this.template.querySelector('[data-id=phoneInput]');
        if (!phone || !window.intlTelInput) return;
    
        this.intlPhone = window.intlTelInput(phone, {
            initialCountry: (this.countryCodeContact 
                    ? this.countryCodeContact.toLowerCase() 
                    : this.getInitialCountry()),
            separateDialCode: true,
            preferredCountries: ['lu','be','fr']
        });
    
        let pd = this.intlPhone.getSelectedCountryData();
        this.countryCodeContactPhone = pd.iso2.toUpperCase();
        this.dialCodeContactPhone    = `+${pd.dialCode}`;
    
        phone.addEventListener('countrychange', () => {
            let upd = this.intlPhone.getSelectedCountryData();
            this.countryCodeContactPhone = upd.iso2.toUpperCase();
            this.dialCodeContactPhone    = `+${upd.dialCode}`;
        });
    
        if (typeof callback === 'function') callback();
    }
    
    get getModalHeader() {
        if (this.showAddContactSection && this.isEditing) {
            return this.label.modifyContactLabel;
        } else if (this.showAddContactSection) {
            return this.label.createContact;
        } else {
            return this.label.addContact;
        }
    }
    
    get getModalSubHeader() {
        if (this.showAddContactSection && this.isEditing) {
            return this.label.modifyContactSubHeader;
        } else if (this.showAddContactSection) {
            return this.label.createNewContactSubHeader;
        } else {
            return this.label.modalSubHeader;
        }
    }
    

    fetchContacts() {
        this.isLoading = true;
        fetchContactFromAccount({ enterPriseNumber: this.enterpriseNumber, opportunityId: this.opportunityId, primaryContactId: this.primaryContactId })
            .then(result => {
                this.mapOfContacts = result;
                console.log(JSON.stringify(result));
                this.setContactOptions();
                this.setDisplayNames();
            })
            .catch(error => console.error(error))
            .finally(() => this.isLoading = false);
    }

    setContactOptions() {
        this.contactOptions = Object.values(this.mapOfContacts).map(contact => ({
            label: `${contact.Salutation || ''} ${contact.FirstName || ''} ${contact.LastName || ''}`.trim(),
            value: contact.Id
        }));
        console.log('Contact options:', JSON.stringify(this.contactOptions));
    }

    getContactKeyFromId(contactId) {
        return Object.keys(this.mapOfContacts).find(key => this.mapOfContacts[key].Id === contactId);
    }

    getContactDisplayName(contactId) {
        const contact = Object.values(this.mapOfContacts).find(c => c.Id === contactId);
        return contact ? `${contact.Salutation || ''} ${contact.FirstName || ''} ${contact.LastName || ''}`.trim() : this.label.selectLabel;
    }

    setDisplayNames() {
        this.primaryContactDisplayName = this.getContactDisplayName(this.primaryContactId);
        this.billingContactDisplayName = this.getContactDisplayName(this.billingContactId);
        this.orderContactDisplayName = this.getContactDisplayName(this.orderContactId);
        this.deliveryContactDisplayName = this.getContactDisplayName(this.deliveryContactId);
    }

    resetForm() {
        this.salutationContact = '';
        this.firstNameContact = '';
        this.lastNameContact = '';
        this.languageContact = '';
        this.roleContact = '';
        this.emailContact = '';
        this.phoneContact = '';
        this.mobileContact = '';
        this.countryCodeContact = '';
        this.dialCodeContact = '';
        this.jobTitle = '';
        this.department = '';
        this.subDepartment = '';
        this.isEditing = false;
        this.showAddContactSection = false;
    }

    handleMainContactClick() {
        this.modalTitle = this.label.main_contact;
        this.selectedContactId = this.primaryContactId;
        this.showAddContactSection = false;
        this.isModalOpen = true;
        setTimeout(() => this.initializeFlagPicker(), 0);
        setTimeout(() => this.initializeFlagPickerPhone(), 0);
    }

    handleBillingContactClick() {
        this.modalTitle = this.label.invoicing_contact;
        this.selectedContactId = this.billingContactId;
        this.showAddContactSection = false;
        this.isModalOpen = true;
        setTimeout(() => this.initializeFlagPicker(), 0);
        setTimeout(() => this.initializeFlagPickerPhone(), 0);
    }

    handleOrderContactClick() {
        this.modalTitle = this.label.order_contact;
        this.selectedContactId = this.orderContactId;
        this.showAddContactSection = false;
        this.isModalOpen = true;
        setTimeout(() => this.initializeFlagPicker(), 0);
        setTimeout(() => this.initializeFlagPickerPhone(), 0);
    }

    handleDeliveryContactClick() {
        this.modalTitle = this.label.delivery_contact;
        this.selectedContactId = this.deliveryContactId;
        this.showAddContactSection = false;
        this.isModalOpen = true;
        setTimeout(() => this.initializeFlagPicker(), 0);
        setTimeout(() => this.initializeFlagPickerPhone(), 0);
    }

    handleContactSelection(event) {
        this.selectedContactId = event.detail.value;
        console.log('Contact selected from dropdown:', this.selectedContactId);
        this.saveContactSelection();
    }

    saveContactSelection() {
        switch (this.modalTitle) {
            case this.label.main_contact: this.primaryContactId = this.selectedContactId; break;
            case this.label.invoicing_contact: this.billingContactId = this.selectedContactId; break;
            case this.label.order_contact: this.orderContactId = this.selectedContactId; break;
            case this.label.delivery_contact: this.deliveryContactId = this.selectedContactId; break;
        }
        console.log('Updated role contact IDs:', JSON.stringify({
            primary: this.primaryContactId,
            billing: this.billingContactId,
            order: this.orderContactId,
            delivery: this.deliveryContactId
        }));
        console.log('Contact MAP:', JSON.stringify(this.mapOfContacts));
        this.setDisplayNames();
        window.dataLayer = window.dataLayer || [];
        window.dataLayer.push({
            event: 'funnel',
            funnel_step: 'Step2contactselection',
            promoCode: this.promoCode || '',
            light_offer: this.isWebOffer,
            funnel_product: this.productCode,
            numberofBeneficiaries: this.noOfBeneficiaries,
            error_status: []
        });
    }

    addNewContact() {
        this.resetForm();
        this.isEditing = false;
        this.showAddContactSection = true;
        this.isModalOpen = true;
        setTimeout(() => this.initializeFlagPicker(), 0);
        setTimeout(() => this.initializeFlagPickerPhone(), 0);
        window.dataLayer = window.dataLayer || [];
        window.dataLayer.push({
            event: 'funnel',
            funnel_step: 'Step2contactcreate',
            promoCode: this.promoCode || '',
            light_offer: this.isWebOffer,
            funnel_product: this.productCode,
            numberofBeneficiaries: this.noOfBeneficiaries,
            error_status: []
        });
    }

    handleEdit(event) {
        const contactId = event.currentTarget.dataset.id;
        const contactKey = this.getContactKeyFromId(contactId);
        const contact = this.mapOfContacts[contactKey];
        if (!contact) return;

        this.selectedContactId = contactId;

        this.salutationContact = contact.Salutation;
        this.firstNameContact = contact.FirstName;
        this.lastNameContact = contact.LastName;
        this.languageContact = contact.ER_Language__c;
        this.roleContact = contact.Business_Role__c;
        this.emailContact = contact.Email;
        this.phoneContact = contact.Phone;
        this.jobTitle = contact.Title;
        this.department = contact.ER_Department_Family__c;
        this.subDepartment = contact.ER_SubDepartment_Family__c;

        if (this.department === 'Executive Management') {
            this.showSubDepartment = true;
        }

        const fullNumber = contact.MobilePhone;

        this.isEditing = true;
        this.showAddContactSection = true;
        setTimeout(() => {
            this.initializeFlagPicker(() => {
                const gsmInput = this.template.querySelector('[data-id=gsmInput]');
                if (gsmInput && window.intlTelInputGlobals) {
                    const iti = window.intlTelInputGlobals.getInstance(gsmInput);
                    if (iti && fullNumber) {
                        iti.setNumber(fullNumber);
    
                        const selectedCountryData = iti.getSelectedCountryData();
                        this.countryCodeContact = selectedCountryData.iso2.toUpperCase();
                        this.dialCodeContact = `+${selectedCountryData.dialCode}`;
                        this.mobileContact = fullNumber.replace(this.dialCodeContact, '').trim();
    
                        console.log('Edit Mode — Reconstructed from intl-tel-input:', {
                            fullNumber,
                            country: this.countryCodeContact,
                            dial: this.dialCodeContact,
                            mobile: this.mobileContact
                        });
                    }
                }
            });
            this.initializeFlagPickerPhone(() => {
                const phoneInput = this.template.querySelector('[data-id=phoneInput]');
                const itiPhone = window.intlTelInputGlobals.getInstance(phoneInput);
                if (itiPhone && this.phoneContact) {
                    itiPhone.setNumber(this.phoneContact);
                    const selP = itiPhone.getSelectedCountryData();
                    this.countryCodeContactPhone = selP.iso2.toUpperCase();
                    this.dialCodeContactPhone = `+${selP.dialCode}`;
                    this.phoneContact = this.phoneContact.replace(this.dialCodeContactPhone, '').trim();
                }
            });
        }, 0);
        window.dataLayer = window.dataLayer || [];
        window.dataLayer.push({
            event: 'funnel',
            funnel_step: 'Step2contactmodify',
            promoCode: this.promoCode || '',
            light_offer: this.isWebOffer,
            funnel_product: this.productCode,
            numberofBeneficiaries: this.noOfBeneficiaries,
            error_status: []
        });
    }
    
    get contactList() {
        const seenIds = new Set();
        return Object.values(this.mapOfContacts)
            .filter(contact => {
                if (contact?.Id && !seenIds.has(contact.Id)) {
                    seenIds.add(contact.Id);
                    return true;
                }
                return false;
            })
            .map(contact => ({
                ...contact,
                label: `${contact.Salutation || ''} ${contact.FirstName || ''} ${contact.LastName || ''}`.trim()
            }));
    }
    
    handleSelect(event) {
        const selectedId = event.currentTarget.dataset.id;
        this.selectedContactId = selectedId;
    
        // Assign to appropriate role based on modalTitle
        switch (this.modalTitle) {
            case this.label.main_contact:
                this.primaryContactId = selectedId;
                break;
            case this.label.invoicing_contact:
                this.billingContactId = selectedId;
                break;
            case this.label.order_contact:
                this.orderContactId = selectedId;
                break;
            case this.label.delivery_contact:
                this.deliveryContactId = selectedId;
                break;
        }
    
        console.log('Selected Contact ID set for role:', {
            role: this.modalTitle,
            contactId: selectedId
        });
    
        this.setDisplayNames();
        this.closeModal();
    }    

    createOrEditContact() {
        if (!this.validateModalFieldsOnly()) {
            console.log('Modal validation failed — cannot save contact');
            return;
        }
        const isEdit = this.isEditing && this.selectedContactId;
        const contactKey = isEdit ? this.getContactKeyFromId(this.selectedContactId) : `contact${this.contactCounter++}`;
        const contactId = isEdit ? this.selectedContactId : contactKey;

        const phoneEl = this.template.querySelector('[data-id=phoneInput]');
        if (phoneEl && window.intlTelInputGlobals) {
            phoneEl.blur();
            const itiPhone = window.intlTelInputGlobals.getInstance(phoneEl);
            if (itiPhone) {
                const fullPhone = itiPhone.getNumber();
                const sel = itiPhone.getSelectedCountryData();
                this.dialCodeContactPhone    = `+${sel.dialCode}`;
                this.countryCodeContactPhone = sel.iso2.toUpperCase();
                this.phoneContact = fullPhone.replace(this.dialCodeContactPhone, '').trim();
            }
        }

        const gsmInput = this.template.querySelector('[data-id=gsmInput]');
        if (gsmInput && window.intlTelInputGlobals) {
            gsmInput.blur();
            const itiInstance = window.intlTelInputGlobals.getInstance(gsmInput);
            if (itiInstance) {
                const fullNumber = itiInstance.getNumber();
                console.log('fullNumber: ', fullNumber);
                const selectedCountryData = itiInstance.getSelectedCountryData();

                this.dialCodeContact = `+${selectedCountryData.dialCode}`;
                this.countryCodeContact = selectedCountryData.iso2.toUpperCase();
                this.mobileContact = fullNumber.replace(this.dialCodeContact, '').trim();

                console.log('Extracted in createOrEditContact:', {
                    fullNumber,
                    dialCode: this.dialCodeContact,
                    mobile: this.mobileContact,
                    countryCode: this.countryCodeContact
                });
            }
        }


        const contactData = {
            Id: contactId,
            Salutation: this.salutationContact,
            FirstName: this.firstNameContact,
            LastName: this.lastNameContact,
            ER_Language__c: this.languageContact,
            Business_Role__c: this.roleContact,
            Email: this.emailContact,
            Phone: this.dialCodeContactPhone + this.phoneContact,
            MobilePhone: this.dialCodeContact + this.mobileContact,
            title: this.jobTitle,
            ER_Department_Family__c: this.department,
            ER_SubDepartment_Family__c: this.subDepartment
        };

        this.mapOfContacts = {
            ...this.mapOfContacts,
            [contactKey]: contactData
        };

        this.selectedContactId = contactId;

        console.log('Contact created/edited:\n', JSON.stringify(contactData));
        console.log('Updated mapOfContacts:\n', JSON.stringify(this.mapOfContacts));
        console.log('Updated contactOptions:\n', JSON.stringify(this.contactOptions));

        this.saveContactSelection();
        this.setDisplayNames();
        this.resetForm();
        this.closeModal();
    }
    handleInputChange(event) {
        const field = event.target.name;
        const value = event.detail?.value || event.target.value;
        
        if (event.target.type === 'checkbox' || event.target.type === 'toggle') {
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
            if(field == 'socialSecretary' && value == 'No Secretary Social'){
                this.showSecretaryToggle = false;
            }else{
                this.showSecretaryToggle = true;
            }
            this[field] = value;
        }
    }
    handleMobileChange(event) {
        const inputValue = event.target.value;
        this.mobileContact = inputValue;
        console.log(`Mobile input: ${this.dialCodeContact}${this.mobileContact}`);
    }
    handlePhoneChange(event) {
        const inputValue = event.target.value;
        this.phoneContact = inputValue;
        console.log(`Mobile input: ${this.dialCodeContactPhone}${this.phoneContact}`);
    }
    
    handleDelete(event) {
        const contactId = event.currentTarget.dataset.id;
        const contactKey = this.getContactKeyFromId(contactId);
        const contact = this.mapOfContacts[contactKey];
        if (contact) {
            this.contactToDelete = contactKey;
            this.contactToDeleteName = `${contact.FirstName || ''} ${contact.LastName || ''}`.trim();
            this.isDeleteConfirmationModalOpen = true;
            this.isModalOpen = false;
        }
    }

    confirmDelete() {
        if (this.contactToDelete) {
            const deletedContact = this.mapOfContacts[this.contactToDelete];
            const deletedContactId = deletedContact?.Id;
            this.mapOfContacts = { ...this.mapOfContacts };

            if (deletedContactId) {
                const updatedMap = { ...this.mapOfContacts };
    
                for (const [key, value] of Object.entries(updatedMap)) {
                    if (value?.Id === deletedContactId) {
                        delete updatedMap[key];
                    }
                }
    
                this.mapOfContacts = updatedMap;
    
                // Clear selected roles if any match the deleted Id
                if (this.primaryContactId === deletedContactId) this.primaryContactId = null;
                if (this.billingContactId === deletedContactId) this.billingContactId = null;
                if (this.orderContactId === deletedContactId) this.orderContactId = null;
                if (this.deliveryContactId === deletedContactId) this.deliveryContactId = null;
    
                console.log('Deleted Contact ID:', deletedContactId);
            }
        }
    
        this.isDeleteConfirmationModalOpen = false;
        this.isModalOpen = true;
        this.contactToDelete = null;
        this.contactToDeleteName = '';
        this.setDisplayNames();
        window.dataLayer = window.dataLayer || [];
        window.dataLayer.push({
            event: 'funnel',
            funnel_step: 'Step2contactdelete',
            promoCode: this.promoCode || '',
            light_offer: this.isWebOffer,
            funnel_product: this.productCode,
            numberofBeneficiaries: this.noOfBeneficiaries,
            error_status: []
        });
    }
    
    cancelDelete() {
        this.isDeleteConfirmationModalOpen = false;
        this.isModalOpen = true;
        this.contactToDelete = null;
        this.contactToDeleteName = '';
    }

    closeModal() {
        this.isModalOpen = false;
        console.log('Modal closed. Contact IDs:', {
            primary: this.primaryContactId,
            billing: this.billingContactId,
            order: this.orderContactId,
            delivery: this.deliveryContactId
        });
    }

    @api
    validateFields() {
        let isValid = true;

        const displayInputs = this.template.querySelectorAll('[data-form-element]');
        displayInputs.forEach(input => {
            const name = input.name;
            const value = input.value;
            const isTopLevelField = ['mainContact', 'billingContact', 'orderContact', 'deliveryContact', 'socialSecretary'].includes(name);

            if (isTopLevelField) {
                const isInvalid = !value || value === this.label.selectLabel;
                if (isInvalid) {
                    const msg = this.label.contactEmptyError.replace('{0}', name.replace('Contact', ' Contact'));
                    input.setCustomValidity(msg);
                    isValid = false;
                } else {
                    input.setCustomValidity('');
                }
                input.reportValidity();
            }
        });

        console.log('Validation result:', isValid);
        return isValid;
    }
    validateModalFieldsOnly() {
        let isValid = true;
        
        const phone = this.template.querySelector('[data-id="phoneInput"]');
        const mobile = this.template.querySelector('[data-id="gsmInput"]');

        const phoneVal = phone?.value?.trim() || '';
        const mobileVal = mobile?.value?.trim() || '';

        if (!phoneVal && !mobileVal) {
            phone.setCustomValidity(this.label.phoneOrMobileError);
            mobile.setCustomValidity(this.label.phoneOrMobileError);
            phone.reportValidity();
            mobile.reportValidity();
            isValid = false;
        } else {
            phone.setCustomValidity("");
            mobile.setCustomValidity("");
            phone.reportValidity();
            mobile.reportValidity();
        }
        const modalInputs = this.template.querySelectorAll('[data-form-element]');
        modalInputs.forEach(input => {
            const fieldName = input.name;
            if (!['mainContact', 'billingContact', 'orderContact', 'deliveryContact', 'socialSecretary'].includes(fieldName)) {
                if (typeof input.checkValidity === 'function' && typeof input.reportValidity === 'function') {
                    if (!input.checkValidity()) {
                        input.reportValidity();
                        isValid = false;
                    }
                }
            }
        });
    
        console.log('Modal validation result:', isValid);
        return isValid;
    }
    
    @api
    getData() {
        return {
            selectedSocialSecretary: this.socialSecretary,
            isSocialSecretaryHandlingOrders: this.isSocialSecretaryHandlingOrders,

            primaryContactId: this.primaryContactId,
            billingContactId: this.billingContactId,
            orderContactId: this.orderContactId,
            deliveryContactId: this.deliveryContactId,

            mapOfContacts: this.mapOfContacts
        };
    }
}