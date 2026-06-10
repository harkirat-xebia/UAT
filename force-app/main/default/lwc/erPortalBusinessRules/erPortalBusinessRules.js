/*************************************************************************************
LWC Name:     ErPortalBusinessRules
Version:      1.0
Created Date: 21/07/2023
Purpose:      This lwc gathers specific business rules functions.

Modification Log :
-----------------------------------------------------------------------------
* Developer     Date        Description
* ----------    ----------  -----------------------
* AAM           21/07/2023  Initial
*************************************************************************************/

// returns collection of products to be displayed in online acquisition and cross selling
export function setProductListNew(
  companyInfos,
  allLabels,
  scope,
  solution,
  cs,
  cardType,
  benefits,
  additionalProducts,
  selectedProduct
) {
  console.log('setProductListNew - Start');
  let productList = [];
  let activeProds = [];
  let availableProds = [];

  // Set main product
  let mainProduct = this.setProduct(solution, additionalProducts);
  Object.assign(mainProduct, { optionsList: [{ optionText: companyInfos.serviceName }], isMandatory: true });

  let otherProds = [];
  let cardOptionList = [
    {
      optionName: 'CardType',
      optionText: allLabels.lb_opt_card_type_question,
      choice1: allLabels.lb_virtual_card,
      choice2: allLabels.lb_physical_card,
      value: allLabels.lb_virtual_card
    },
    { optionText: allLabels.lb_opt_lunch_virike }
  ];
  let virtualCardOption = [{ optionText: allLabels.lb_virtual_card }];
  let btnLabels = {
    add: allLabels.lb_add,
    select: allLabels.lb_select,
    selected: allLabels.lb_selected,
    active: allLabels.lb_active
  };

  let dentalProd = this.setProduct('ERFI_C_DENT_EUR', additionalProducts, btnLabels);
  let massageProd = this.setProduct('ERFI_C_MASS_EUR', additionalProducts, btnLabels);
  let cardProd = this.setProduct('ERFI_C_TD_DUALW_EUR', additionalProducts, btnLabels);
  let transportProd = this.setProduct('ERFI_C_TTR_EUR', additionalProducts, btnLabels);
  let lounariVoucherProd = this.setProduct('ERFI_C_VOU_LUNCH', additionalProducts, btnLabels);
  let virikeVoucherProd = this.setProduct('ERFI_C_VOU_REC', additionalProducts, btnLabels);

  if (!cs || scope == 'C') {
    let curProducts = [];
    switch (solution) {
      case 'ERFI_C_TD_DUALW_EUR':
        let cardTypeOption = {
          optionName: 'CardType',
          optionText: allLabels.lb_opt_card_type_question,
          choice1: allLabels.lb_virtual_card,
          choice2: allLabels.lb_physical_card,
          value: cardType
        };
        let benefitsOption = {
          optionName: 'Benefits',
          optionText: allLabels.lb_opt_benefits_question,
          choice1: allLabels.lb_opt_lunch_virike,
          choice2: allLabels.lb_opt_lunch,
          value: benefits
        };
        mainProduct.optionsList.push(cardTypeOption);
        let showTransportMassageDentalProdsCs = false;

        if (cs) {
          // Check contracts for Edenred Card in cross selling
          companyInfos.contractsJSON.forEach((contract) => {
            if (contract.Type != 'Client' || contract.Pricebook != 'ERFI_C_EMP') showTransportMassageDentalProdsCs = true;
          });
          //Case no contracts, then show massage, transport and denatl products
          if(companyInfos.contractsJSON.length == 0) showTransportMassageDentalProdsCs = true; 
        }

        console.log('setProductListNew - showTransportMassageDentalProdsCs ' + showTransportMassageDentalProdsCs);
        if (showTransportMassageDentalProdsCs || !cs) {
          // Show benefits choice in Edenred Card product
          if (
            cardType == allLabels.lb_physical_card ||
            cs ||
            (cardType != allLabels.lb_physical_card &&
              Number(companyInfos.numberEmployees) >= Number(allLabels.default_erfi_td_nb_emp_min))
          ) {
            benefits == allLabels.lb_opt_lunch_virike;
            mainProduct.optionsList.push({ optionText: allLabels.lb_opt_lunch_virike });
          } else {
            mainProduct.optionsList.push(benefitsOption);
          }

          let prodCodeList;
          if (Number(companyInfos.numberEmployees) < Number(allLabels.default_erfi_td_nb_emp_min)) {
            if (cardType == allLabels.lb_virtual_card) {
              prodCodeList =
                benefits == allLabels.lb_opt_lunch_virike
                  ? allLabels.default_erfi_td_prod_list1_csv
                  : allLabels.default_erfi_td_prod_list2_csv;
            } else {
              prodCodeList = allLabels.default_erfi_td_prod_list1_csv;
            }
          } else {
            prodCodeList = allLabels.default_erfi_td_prod_list1_csv;
          }

          prodCodeList.split(',').forEach((prodCode) => {
            let prod = this.setProduct(prodCode, additionalProducts, btnLabels);
            prod.optionsList = [{ optionText: allLabels.lb_virtual_card }];
            curProducts.push(prod);
          });
        } else {
          mainProduct.optionsList = [{ optionText: allLabels.lb_virtual_card }, { optionText: allLabels.lb_opt_lunch }];
          curProducts.push(virikeVoucherProd);
        }

        break;

      case 'ERFI_C_VOU_LUNCH':
        virikeVoucherProd.isMandatory = true;
        curProducts.push(virikeVoucherProd);
        break;

      case 'ERFI_C_VOU_REC':
        lounariVoucherProd.isMandatory = true;
        curProducts.push(lounariVoucherProd);

        if (Number(companyInfos.numberEmployees) < Number(allLabels.default_erfi_td_nb_emp_min)) {
          cardProd.optionsList = [{ optionText: allLabels.lb_virtual_card }, { optionText: allLabels.lb_opt_lunch }];
          curProducts.push(cardProd);
        }
        break;

      case 'ERFI_C_TTR_EUR':
        cardProd.optionsList = cardOptionList;
        massageProd.optionsList = virtualCardOption;
        dentalProd.optionsList = virtualCardOption;
        curProducts.push(cardProd, massageProd, dentalProd);
        break;

      case 'ERFI_C_MASS_EUR':
        cardProd.optionsList = cardOptionList;
        transportProd.optionsList = virtualCardOption;
        dentalProd.optionsList = virtualCardOption;
        curProducts.push(cardProd, transportProd, dentalProd);
        break;

      case 'ERFI_C_DENT_EUR':
        cardProd.optionsList = cardOptionList;
        transportProd.optionsList = virtualCardOption;
        massageProd.optionsList = virtualCardOption;
        curProducts.push(cardProd, transportProd, massageProd);
        break;
    }
    // otherProds.push(...curProducts);
    console.log('setProductListNew - companyInfos.activeProductsCsv: ' + companyInfos.activeProductsCsv);

    curProducts.forEach((prod) => {
      console.log('setProductListNew - prod.labels.productCode: ' + prod.labels.productCode);
      console.log(
        'setProductListNew - test result: ' + companyInfos.activeProductsCsv.includes(prod.labels.productCode)
      );

      if (companyInfos.activeProductsCsv.includes(prod.labels.productCode)) {
        prod.isActivated = true;
        activeProds.push(prod);
      } else availableProds.push(prod);
    });

    console.log('setProductListNew - cross selling activeProds: ' + JSON.stringify(activeProds));
    console.log('setProductListNew - cross selling availableProds: ' + JSON.stringify(availableProds));

    if (cs && ['ERFI_C_TTR_EUR', 'ERFI_C_MASS_EUR', 'ERFI_C_DENT_EUR'].includes(solution))
      mainProduct.optionsList = virtualCardOption;
  } else {
    console.log('setProductListNew - cross selling');

    if (scope == 'M') {
      console.log('setProductListNew - cross selling Merchant');
      Object.keys(additionalProducts).forEach((prodCode) => {
        if (prodCode.startsWith('ERFI_M')) {
          let prod = this.setProduct(prodCode, additionalProducts, btnLabels);

          prod.isRadioBtn = true;
          prod.isSelected = selectedProduct == prodCode;

          if (companyInfos.activeProductsCsv) {
            prod.isActivated = companyInfos.activeProductsCsv.includes(prodCode);
          }
          if (prod.isActivated) activeProds.push(prod);
          else {
            if (!companyInfos.ongoingOppProductsCsv) availableProds.push(prod);
            else if (!companyInfos.ongoingOppProductsCsv.includes(prodCode)) availableProds.push(prod);
          }
        }
      });
    }
  }

  if (!cs) otherProds.push(...activeProds, ...availableProds);
  else otherProds.push(...availableProds, ...activeProds);
  console.log('setProductListNew - cross selling otherProds: ' + JSON.stringify(otherProds));

  if (!cs || scope == 'C') productList.push(mainProduct);
  productList.push(...otherProds);
  console.log('setProductListNew - productList end: ' + JSON.stringify(productList));

  return productList;
}

export function setProduct(prodCode, additionalProducts, otherLabels) {
  return { labels: { cardName: additionalProducts[prodCode], productCode: prodCode, ...otherLabels } };
}