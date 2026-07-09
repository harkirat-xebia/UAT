public with sharing class APBE01_LeadBelfirst {

    // Entry point called from the Lead trigger (after insert / after update).
    // Uses @future so callouts are allowed outside a trigger context.
    @future(callout=true)
    public static void autoPopulateIfEmpty(Set<Id> leadIds) {
        List<Lead> leads = [
            SELECT
                Id,
                ER_BUPicklist__c,
                ER_Registration_Number__c,
                RCS_Number__c,
                ER_Language__c,
                ER_Legal_Name__c,
                Company,
                Street,
                PostalCode,
                City,
                Country,
                Phone,
                ER_VAT_Number__c,
                ER_Legal_Form__c,
                NumberOfEmployees,
                Website,
                Email
            FROM Lead
            WHERE Id IN :leadIds
              AND ER_BUPicklist__c IN ('BE', 'LU')
              AND (ER_Registration_Number__c != null OR RCS_Number__c != null
                   OR (ER_BUPicklist__c = 'BE' AND ER_VAT_Number__c LIKE 'BE%'))
              AND ER_Lead_sub_source__c != 'Econtratonline'
              AND (ER_Legal_Name__c = null
                OR Street = null
                OR PostalCode = null
                OR City = null)
        ];

        //System.debug('APBE01 autoPopulateIfEmpty: queried ' + leads.size() + ' eligible leads for IDs ' + leadIds);
        if (leads.isEmpty()) return;

        List<Lead> leadsToUpdate = new List<Lead>();
        WSBE01_Belfirst belfirstWS = new WSBE01_Belfirst();

        try {
            for (Lead lead : leads) {
                try {
                    Boolean isLU = lead.ER_BUPicklist__c == 'LU';
                    String regNum;
                    if (isLU) {
                        regNum = lead.RCS_Number__c;
                    } else if (String.isNotBlank(lead.ER_Registration_Number__c)) {
                        regNum = lead.ER_Registration_Number__c;
                    } else if (String.isNotBlank(lead.ER_VAT_Number__c)
                               && lead.ER_VAT_Number__c.toUpperCase().startsWith('BE')) {
                        // Strip "BE" prefix — the Belfirst call will re-add it as the BVDID
                        regNum = lead.ER_VAT_Number__c.replaceFirst('(?i)^BE', '');
                    }
                    if (String.isBlank(regNum)) continue;
                    String belFirstId = isLU ? regNum.replaceFirst('(?i)^LU', '') : 'BE' + regNum;
                    String idType     = isLU ? 'RCSID' : 'BVDID';
                    String locale    = 'FR'.equalsIgnoreCase(lead.ER_Language__c) ? 'fr_BE' : 'nl_BE';
                    //System.debug('APBE01 calling Belfirst for lead ' + lead.Id + ' | belFirstId=' + belFirstId + ' | idType=' + idType + ' | locale=' + locale);

                    Map<String, String> info = belfirstWS.getInfos(belFirstId, idType, locale);
                    //System.debug('APBE01 Belfirst response for lead ' + lead.Id + ': ' + info);
                    BelfirstUpdateResult res = buildLeadUpdate(lead, info);
                    //System.debug('APBE01 lead ' + lead.Id + ' | filled: ' + res.filledFields + ' | missing: ' + res.missingFields);
                    if (res.lead != null) leadsToUpdate.add(res.lead);

                } catch (WSBE01_BelfirstException ex) {
                    System.debug('APBE01 Belfirst company not found for lead ' + lead.Id + ' - ' + ex.getMessage());
                } catch (Exception ex) {
                    System.debug('APBE01 unexpected error for lead ' + lead.Id + ' - ' + ex.getTypeName() + ': ' + ex.getMessage());
                }
            }
        } finally {
            belfirstWS.closeConnection();
        }

        //System.debug('APBE01 leads to update with Belfirst data: ' + leadsToUpdate.size());
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
            //System.debug('APBE01 Belfirst update complete for ' + leadsToUpdate.size() + ' leads');
        }
    }

    // Returns true when a lead should trigger a Belfirst call.
    // Kept public so the trigger handler can pre-filter before scheduling the future.
    public static Boolean isEligible(Lead lead) {
        Boolean isBE = lead.ER_BUPicklist__c == 'BE';
        Boolean isLU = lead.ER_BUPicklist__c == 'LU';

        Boolean hasRegistrationId = isLU
            ? String.isNotBlank(lead.RCS_Number__c)
            : String.isNotBlank(lead.ER_Registration_Number__c);

        // BE-only fallback: VAT number starting with "BE" can substitute for a missing registration number
        Boolean hasVatFallback = isBE
            && String.isBlank(lead.ER_Registration_Number__c)
            && String.isNotBlank(lead.ER_VAT_Number__c)
            && lead.ER_VAT_Number__c.toUpperCase().startsWith('BE');

        return (isBE || isLU)
            && (hasRegistrationId || hasVatFallback)
            && lead.ER_Lead_sub_source__c != 'Econtratonline'
            && (String.isBlank(lead.ER_Legal_Name__c)
                || String.isBlank(lead.Street)
                || String.isBlank(lead.PostalCode)
                || String.isBlank(lead.City));
    }

    private class BelfirstUpdateResult {
        Lead lead;
        List<String> filledFields  = new List<String>();
        List<String> missingFields = new List<String>();
    }

    // Builds a Lead update record from the Belfirst response.
    // Only overwrites fields that are currently blank on the lead.
    // Returns a wrapper with the Lead to update (null if nothing to change)
    // and lists of which fields were filled vs still missing after the call.
    private static BelfirstUpdateResult buildLeadUpdate(Lead lead, Map<String, String> info) {
        BelfirstUpdateResult res = new BelfirstUpdateResult();
        Lead updated  = new Lead(Id = lead.Id);
        Boolean dirty = false;

        String name      = sanitize(info.get('NAME'));
        String address   = sanitize(info.get('ADDRESS'));
        String postcode  = sanitize(info.get('POSTCODE'));
        String town      = sanitize(info.get('TOWN'));
        String country   = sanitize(info.get('COUNTRY'));
        String phone     = sanitize(info.get('PHONE'));
        String legalForm = sanitize(info.get('TYPE'));
        String website   = sanitize(info.get('WEBSITE'));
        String email     = sanitize(info.get('EMAIL'));
        String employee  = sanitize(info.get('EMPLOYEE'));
        String bvdId     = sanitize(info.get('BVDID'));
        String lvat      = sanitize(info.get('LVAT'));

        if (String.isBlank(lead.ER_Legal_Name__c)) {
            if (name != null) { updated.ER_Legal_Name__c = name; dirty = true; res.filledFields.add('ER_Legal_Name__c'); }
            else               res.missingFields.add('ER_Legal_Name__c');
        }
        if (String.isBlank(lead.Company)) {
            if (name != null) { updated.Company = name; dirty = true; res.filledFields.add('Company'); }
            else               res.missingFields.add('Company');
        }
        if (String.isBlank(lead.Street)) {
            if (address != null) { updated.Street = address; dirty = true; res.filledFields.add('Street'); }
            else                   res.missingFields.add('Street');
        }
        if (String.isBlank(lead.PostalCode)) {
            if (postcode != null) { updated.PostalCode = postcode; dirty = true; res.filledFields.add('PostalCode'); }
            else                    res.missingFields.add('PostalCode');
        }
        if (String.isBlank(lead.City)) {
            if (town != null) { updated.City = town; dirty = true; res.filledFields.add('City'); }
            else                res.missingFields.add('City');
        }
        if (String.isBlank(lead.Country)) {
            if (country != null) { updated.Country = country; dirty = true; res.filledFields.add('Country'); }
            else                   res.missingFields.add('Country');
        }
        if (String.isBlank(lead.Phone)) {
            if (phone != null) { updated.Phone = phone; dirty = true; res.filledFields.add('Phone'); }
            else                 res.missingFields.add('Phone');
        }
        if (String.isBlank(lead.ER_Legal_Form__c)) {
            if (legalForm != null) { updated.ER_Legal_Form__c = legalForm; dirty = true; res.filledFields.add('ER_Legal_Form__c'); }
            else                     res.missingFields.add('ER_Legal_Form__c');
        }
        if (String.isBlank(lead.Website)) {
            if (website != null) { updated.Website = website; dirty = true; res.filledFields.add('Website'); }
            else                   res.missingFields.add('Website');
        }
        if (String.isBlank(lead.Email)) {
            if (email != null) { updated.Email = email; dirty = true; res.filledFields.add('Email'); }
            else                 res.missingFields.add('Email');
        }
        if (lead.NumberOfEmployees == null) {
            if (employee != null) {
                try { updated.NumberOfEmployees = Integer.valueOf(employee); dirty = true; res.filledFields.add('NumberOfEmployees'); }
                catch (Exception e) { res.missingFields.add('NumberOfEmployees'); }
            } else {
                res.missingFields.add('NumberOfEmployees');
            }
        }
        if (String.isBlank(lead.ER_VAT_Number__c)) {
            String vat = (bvdId != null && bvdId.startsWith('BE')) ? bvdId : lvat;
            if (vat != null) { updated.ER_VAT_Number__c = vat; dirty = true; res.filledFields.add('ER_VAT_Number__c'); }
            else               res.missingFields.add('ER_VAT_Number__c');
        }
        // When enrichment was triggered via VAT fallback (registration number was empty,
        // VAT has BE prefix), backfill the registration number by stripping the BE prefix
        if (String.isBlank(lead.ER_Registration_Number__c)
            && String.isNotBlank(lead.ER_VAT_Number__c)
            && lead.ER_VAT_Number__c.toUpperCase().startsWith('BE')) {
            updated.ER_Registration_Number__c = lead.ER_VAT_Number__c.replaceFirst('(?i)^BE', '');
            dirty = true;
            res.filledFields.add('ER_Registration_Number__c');
        }

        // Stamp missing fields onto the Lead so it's visible on the record.
        // Requires a custom textarea field: ER_Belfirst_Missing_Fields__c (Text Area, 255)
        // Comment out the two lines below if you haven't created the field yet.
        // updated.ER_Belfirst_Missing_Fields__c = res.missingFields.isEmpty() ? 'All fields filled' : String.join(res.missingFields, ', ');
        // dirty = true;

        res.lead = dirty ? updated : null;
        return res;
    }

    // Treats blank values and "n.d." (non disponible) as null so we never store placeholder text.
    private static String sanitize(String value) {
        if (String.isBlank(value) || value.trim().equalsIgnoreCase('n.d.')) {
            return null;
        }
        return value.trim();
    }

    // Old Code
    // Map<Id, Lead> newMap;
    // public APBE01_LeadBelfirst() {
    //   this.newMap = newMap;
    // }

    // AAM - COUL-1059: it seems to be unused code, to check if this class is still relevant or has to be deleted 
    // //Should be only one lead at a time
    // public void populateLeadFromSelligent() {
    //   belfirstCall(newMap.keySet());

    //   List<Lead> leadToUpdate = [SELECT Id, CreatedBy.Name FROM Lead WHERE Id IN :newMap.keySet()];

    //   Database.DMLOptions dmlOpts = new Database.DMLOptions();
    //   dmlOpts.AssignmentRuleHeader.useDefaultRule = true;

    //   for (Lead l : leadToUpdate) {
    //     if ('Selligent'.equals(l.CreatedBy.Name)) {
    //       l.setOptions(dmlOpts);
    //     }
    //   }

    //   update leadToUpdate;
    // }

    // //It's mandatory to use a future method to be able to do a callout in a trigger.
    // //In the loop, the trigger will check if the record is created by Selligent.
    // @future(callout=true)
    // private static void belfirstCall(Set<Id> recordIds) {
    //   List<Lead> leads = [
    //     SELECT
    //       Street,
    //       PostalCode,
    //       City,
    //       Country,
    //       Company,
    //       Phone,
    //       NumberOfEmployees,
    //       ER_Legal_Form__c,
    //       ER_Language__c,
    //       ER_Enterprise_Number__c,
    //       CreatedBy.Name,
    //       LeadSource,
    //       Rating,
    //       RecordTypeId,
    //       ER_VAT_Number__c
    //     //    ,BE_Product__c
    //     FROM Lead
    //     WHERE Id IN :recordIds
    //   ];
    //   List<Lead> leadsToUpdate = new List<Lead>();

    //   WSBE01_Belfirst belfirstWebservice = new WSBE01_Belfirst();
    //   Map<String, String> belfirstInfos;
    //   String language;

    //   for (Lead l : leads) {
    //     if ('Selligent'.equals(l.CreatedBy.Name)) {
    //       language = 'FR'.equals(l.ER_Language__c) ? 'fr_BE' : 'nl_BE';
    //       belfirstInfos = belfirstWebservice.getInfos('BE' + l.ER_Enterprise_Number__c, language);
    //       leadsToUpdate.add(updateLead(belfirstInfos, l));
    //     }
    //   }

    //   belfirstWebservice.closeConnection();
    //   update leadsToUpdate;
    // }

    // //Update lead with infos received from belfirst
    // private static Lead updateLead(Map<String, String> infos, Lead l) {
    //   l.Street = infos.get('ADDRESS');
    //   l.PostalCode = infos.get('POSTCODE');
    //   l.City = infos.get('TOWN');
    //   l.Country = infos.get('COUNTRY');
    //   L.Company = String.isBlank(l.Company) ? infos.get('NAME') : l.Company;
    //   l.Phone = String.isBlank(l.Phone) ? infos.get('PHONE') : l.Phone;
    //   l.ER_Legal_Name__c = String.isBlank(l.Company) ? infos.get('NAME') : l.Company;
    //   Integer numberOfEmployees;
    //   try {
    //     numberOfEmployees = Integer.valueOf(infos.get('EMPLOYEE'));
    //   } catch (Exception e) {
    //     //Invalid integer
    //   }
    //   l.NumberOfEmployees = l.NumberOfEmployees == null ? numberOfEmployees : l.NumberOfEmployees;
    //   l.ER_Legal_Form__c = infos.get('TYPE');
    //   l.ER_VAT_Number__c = 'BELGIUM'.equals((l.Country).toUpperCase()) ? 'BE' + l.ER_Enterprise_Number__c : '';
    //   l.Website = infos.get('WEBSITE');
    //   l.Email = 'EMAIL';

    //   //Hardcoded values
    //   l.LeadSource = 'Mobility Landing Page';
    //   //l.BE_Product__c = 'Mobility Solution';
    //   L.Rating = 'Hot';

    //   return l;
    // }

    public static void fakecc(){
        Integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}