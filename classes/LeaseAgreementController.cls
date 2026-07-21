public with sharing class LeaseAgreementController {
  @AuraEnabled
  public static Id createLease(
    Id tenantContactId,
    Id propertyId,
    String terms,
    Decimal agreedMonthlyRent,
    Date startDate,
    Date endDate
  ) {
    Lease_Agreement__c lease = new Lease_Agreement__c(
      Tenant_Contact__c = tenantContactId,
      Property__c = propertyId,
      Terms__c = terms,
      Agreed_Monthly_Rent__c = agreedMonthlyRent,
      Start_Date__c = startDate,
      End_Date__c = endDate
    );

    try {
      Database.insert(lease, AccessLevel.USER_MODE);
    } catch (DmlException ex) {
      throw new AuraHandledException(ex.getDmlMessage(0));
    }

    return lease.Id;
  }
}
