/*************************************************************************************
LWC Name:     erPortalUtils
Version:      1.0
Created Date: 22/02/2021
Purpose:      This lwc gathers common Edenred Portal functions.

Modification Log :
-----------------------------------------------------------------------------
* Developer     Date        Description
* ----------    ----------  -----------------------
* AAM           22/02/2021  Initial (Auto enrollment Project)
*************************************************************************************/

// display logs if debug mode activated
export function debugLog(debugMode, message) {
  if (debugMode) console.log(message);
}

// Check enterprise number with the modulo algorithm
export function isValidEnterpriseNb(enterpriseNb, country) {
  let result = false;
  console.log('>>> isValidEnterpriseNb -- enterpriseNb - country: ' + enterpriseNb + ' - ' + country);
  //TODO rework this part to be more generic (use pattern or list of patterns)
  switch (country) {
    case 'BE':
      // Test if BE format
      let beEnterpriseNb = enterpriseNb;
      let lastNumbers = beEnterpriseNb % 100;
      beEnterpriseNb = (beEnterpriseNb - lastNumbers) / 100;
      let reducedenterpriseNb = parseInt(beEnterpriseNb / 97) * 97;
      let rest = beEnterpriseNb - reducedenterpriseNb;
      result = 97 - rest == lastNumbers;
      console.log('>>> isValidEnterpriseNb -- result1: ' + result);
      break;
    case 'LU':
      let luEnterpriseNb = enterpriseNb;
      result = /^[a-zA-Z]{1}[0-9]*$/.test(luEnterpriseNb);
      console.log('>>> isValidEnterpriseNb -- result2: ' + result);
      break;
    case 'ES':
      result =
        /[0-9A-Z][0-9]{7}[0-9A-Z]/.test(enterpriseNb) ||
        /[XYZ]{7,8}[A-Z]/.test(enterpriseNb) ||
        /([a-z]|[A-Z]|[0-9])[0-9]{7}([a-z]|[A-Z]|[0-9])/.test(enterpriseNb);
      break;
    default:
      console.log('>>> isValidEnterpriseNb -- default: ' + result);
      result = true;
  }

  console.log('>>> isValidEnterpriseNb -- result end: ' + result);

  return result;
}

// Transform JSON object into array of objects key/value, which is the expected format
export function formatPicklist(pickListObject, initVal) {
  let pickListEntries = [];
  Object.entries(pickListObject).map(([valuePicklist, labelPicklist]) =>
    // pickListEntries.push({ key: valuePicklist, value: labelPicklist, selected: false, hidden: (valuePicklist) ? false : true})
    pickListEntries.push({
      key: valuePicklist,
      value: labelPicklist,
      selected: false,
      hidden: valuePicklist === ''
    })
  );
  if (initVal) pickListEntries = this.initPicklistValue(pickListEntries, initVal);
  return pickListEntries;
}

// reset picklist selected value, and set it to first value
export function resetPicklist(pickListArray) {
  console.log('>>> resetPicklist --- START -- nb pickListArray: ' + pickListArray.length);
  pickListArray.forEach((pkList) => {
    console.log('>>> resetPicklist --- pkList: ' + JSON.stringify(pkList));
    if (pkList.length > 0) {
      pkList.forEach((elem) => {
        console.log('>>> resetPicklist --- elem: ' + JSON.stringify(elem));
        elem.selected = false;
      });
      pkList[0].selected = true;
    }
  });
  console.log('>>> resetPicklist --- END -- ');
}

// reset picklist selected value, and set it to first value
export function initPicklistDisplay(pickListArray) {
  console.log('>>> initPicklistDisplay --- START -- nb pickListArray: ' + pickListArray.length);
  pickListArray.forEach((pkList) => (pkList.displayCurValue = true));
  console.log('>>> initPicklistDisplay --- END --');
}

// Initialize picklist with the right selected value
export function initPicklistValue(pickList, value) {
  pickList.forEach((elem, index) => {
    pickList[index].selected = elem.key === value;
  });
  console.log('>>> initPicklistValue -- pickList: ' + JSON.stringify(pickList));
  return pickList;
}

// Check if required fields are populated
export function checkRequiredFields(fieldList, errorMessage) {
  let noErrors = true;
  let isFocusSet = false;
  fieldList.forEach((field) => {
    field.hasError = !field.value && field.required;
    console.log('field.value: ' + field.inputLabel + ' = "' + field.value + '" --> field err  = ' + field.hasError);
    if (field.hasError) {
      field.errorMessage = errorMessage;
      noErrors = false;
      if (!isFocusSet) {
        field.scrollIntoView();
        isFocusSet = true;
      }
    }
  });
  return noErrors;
}

// Init fields with inputs previously done and set it to disable
export function initFields(fieldList, objectInfos, isDisabled, fieldMapping, otherObjectInfos) {
  fieldList.forEach((field) => {
    field.disabled = isDisabled;
    console.log('initFields --- field.propertyName: ' + field.propertyName);
    console.log('initFields --- fieldMapping: ' + JSON.stringify(fieldMapping));
    let propertyName = fieldMapping ? fieldMapping[field.propertyName] : field.propertyName;
    field.value = objectInfos[propertyName]; // init input field value

    if (otherObjectInfos) {
      otherObjectInfos[field.propertyName] = objectInfos[propertyName]; // init target property in objectInfos object (binding)
      console.log('initFields otherObjectInfos--- propertyName: ' + propertyName + ' value is ' + field.value);
    } else {
      objectInfos[field.propertyName] = objectInfos[propertyName]; // init target property in objectInfos object (binding)
      console.log('initFields objectInfos--- propertyName: ' + propertyName + ' value is ' + field.value);
    }
  });
  // field.value = objectInfos[field.propertyName.replace(fieldRename,"")]; });
  console.log('initFields ***END***');
}

// Erase field values and set enable it again
export function eraseFieldsAndEnable(fieldList) {
  fieldList.forEach((field) => {
    field.disabled = false;
    field.value = '';
  });
}

//TODO bulkify validation for many field
// Validate format with regex, return true if format is OK
// export function validateFormat(field, pattern, errorMessage) {
export function validateFormat(fieldValidationList) {
  let result = true;
  fieldValidationList.forEach((fieldValidation) => {
    console.log('validateFormat -- regex: ' + fieldValidation.regex);
    let isFocusSet = false;
    if (fieldValidation.field.value) {
      // check only if field is populated

      let regex = new RegExp(fieldValidation.regex);
      let resultField = regex.test(fieldValidation.field.value.trim());
      console.log('validateFormat -- result for: "' + fieldValidation.field.value + '" is ' + resultField);
      if (fieldValidation.field.hasError || !resultField) {
        result = false;
        fieldValidation.field.hasError = true;
        fieldValidation.field.errorMessage = fieldValidation.errMsg;
        console.log('validateFormat -- isFocusSet: ' + isFocusSet);
        if (!isFocusSet) {
          fieldValidation.field.scrollIntoView();
          console.log('validateFormat -- scroll done');
          isFocusSet = true;
        }
      } else {
        fieldValidation.field.errorMessage = '';
      }
    }
  });
  return result;
}

// Check if Terminal ID is correct
export function isValidTID(terminalInfos, solution, ece_providers_ko, ece_models_ko, providers_tids, models_tids) {
  const tid = terminalInfos.tid;
  const provider = terminalInfos.terminalProvider;
  const model = terminalInfos.terminalModel;

  console.log('>>> isValidTID -- Start');
  let result = { isValid: true, errorMsg: '' };
  const provider_model = provider + '_' + model;
  console.log('>>> isValidTID -- Start tid: ' + tid);

  if (tid.length < 9) {
    console.log('>>> isValidTID -- check ECE ');
    // For ECE, check if terminal compatible (test to be done after model selection too)
    if (ece_providers_ko.includes(provider) || ece_models_ko.includes(provider_model)) {
      result = { isValid: false, errorMsg: 'Not_compatible_ECE' };
    }

    console.log('>>> isValidTID -- check ECE result ' + result.isValid);
    console.log('>>> isValidTID -- providers_tids ' + JSON.stringify(providers_tids));
    console.log('>>> isValidTID -- models_tids ' + JSON.stringify(models_tids));
    // Check if first digits are OK according to provider and model
    if (result.isValid) {
      let provider_model = provider + '_' + model;
      if (!hasMatchingStart(tid, provider, providers_tids) || !hasMatchingStart(tid, provider_model, models_tids))
        result = { isValid: false, errorMsg: 'Wrong_TID' };
    }

    console.log('>>> isValidTID -- result2 ' + result.isValid);
  } else {
    console.log('>>> isValidTID -- tid.length too long: ' + tid.length);
    result = { isValid: false, errorMsg: 'Wrong_TID' };
  }
  console.log('>>> isValidTID -- result: ' + JSON.stringify(result));

  return result;
}

function hasMatchingStart(tid, terminalType, patterns) {
  console.log('>>> hasMatchingStart -- Start - tid: ' + tid);
  console.log('>>> hasMatchingStart -- terminalType: ' + terminalType);
  console.log('>>> hasMatchingStart -- patterns: ' + JSON.stringify(patterns));
  let hasMatchingStart = false;
  if (Object.keys(patterns).includes(terminalType)) {
    if (Array.isArray(patterns[terminalType])) {
      console.log('>>> hasMatchingStart -- patterns[terminalType]: ' + JSON.stringify(patterns[terminalType]));
      patterns[terminalType].forEach((firstDigits) => {
        if (!hasMatchingStart && tid.startsWith(firstDigits)) hasMatchingStart = true;
      });
    } else {
      console.log('>>> hasMatchingStart -- patterns[terminalType] 2: ' + JSON.stringify(patterns[terminalType]));
      if (tid.startsWith(patterns[terminalType])) hasMatchingStart = true;
    }
  } else {
    hasMatchingStart = true;
  }
  console.log('>>> hasMatchingStart -- end: ' + hasMatchingStart);
  return hasMatchingStart;
}

function dynamicTemplate(strTemplate, params) {
  console.log('>>> dynamicTemplate -- strTemplate: ' + strTemplate);
  console.log('>>> dynamicTemplate -- params: ' + params);
  return new Function(params, 'return `' + strTemplate + '`;');
}

export function buildTemplate(strTemplate, paramsValues) {
  console.log('>>> buildTemplate -- start ');
  let paramNames = strTemplate.match(/{[\w\d]+}/g).map(function (value) {
    return value.substring(1, value.length - 1);
  });
  console.log('>>> buildTemplate -- paramNames: ' + JSON.stringify(paramNames));
  let template = dynamicTemplate(strTemplate, paramNames);
  console.log('>>> buildTemplate -- result: ' + template(...paramsValues));
  return template(...paramsValues);
}