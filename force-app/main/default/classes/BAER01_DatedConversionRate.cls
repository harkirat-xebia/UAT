/**
 * @author Oussama LASFAR
 * @date 12/10/2018 (dd/mm/yyyy)
 * @description Batch to call the ECB and update currencies (DatedConversionRate object)
 */
global class BAER01_DatedConversionRate implements Schedulable, Database.AllowsCallouts {
  global void execute(SchedulableContext BC) {
    List<CurrencyType> currencyTypes = [SELECT id, IsoCode, isActive FROM CurrencyType WHERE isActive = TRUE];

    List<String> currencyTypeList = new List<String>();
    for (CurrencyType CT : currencyTypes) {
      currencyTypeList.add(CT.IsoCode);
    }
    if (!currencyTypeList.isEmpty()) {
      APER09_DatedConversionRate_Management.getDailyRates(currencyTypeList);
    }
  }
}