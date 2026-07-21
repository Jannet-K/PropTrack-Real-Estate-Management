@isTest
private class LeaseAgreementControllerTest {
  private static Property__c createProperty() {
    Property__c property = new Property__c(
      Address__c = '123 Main St',
      City__c = 'Springfield',
      State__c = 'IL',
      Postal_Code__c = '62701',
      Country__c = 'USA',
      Type__c = 'Residential',
      Status__c = 'Available',
      Rent__c = 1500,
      Description__c = 'A cozy property'
    );
    insert property;
    return property;
  }

  private static Contact createTenant() {
    Contact tenant = new Contact(FirstName = 'Arjun', LastName = 'Kumar');
    insert tenant;
    return tenant;
  }

  @isTest
  static void testCreateLeaseInsertsRecordWithAllFields() {
    Property__c property = createProperty();
    Contact tenant = createTenant();

    Test.startTest();
    Id leaseId = LeaseAgreementController.createLease(
      tenant.Id,
      property.Id,
      'Standard 12 month lease',
      1500,
      Date.newInstance(2026, 1, 1),
      Date.newInstance(2026, 12, 31)
    );
    Test.stopTest();

    Lease_Agreement__c lease = [
      SELECT
        Id,
        Tenant_Contact__c,
        Property__c,
        Terms__c,
        Agreed_Monthly_Rent__c,
        Start_Date__c,
        End_Date__c
      FROM Lease_Agreement__c
      WHERE Id = :leaseId
    ];
    Assert.areEqual(tenant.Id, lease.Tenant_Contact__c, 'Tenant should be linked');
    Assert.areEqual(property.Id, lease.Property__c, 'Property should be linked');
    Assert.areEqual('Standard 12 month lease', lease.Terms__c, 'Terms should match');
    Assert.areEqual(1500, lease.Agreed_Monthly_Rent__c, 'Rent should match');
    Assert.areEqual(
      Date.newInstance(2026, 1, 1),
      lease.Start_Date__c,
      'Start date should match'
    );
    Assert.areEqual(
      Date.newInstance(2026, 12, 31),
      lease.End_Date__c,
      'End date should match'
    );
  }

  @isTest
  static void testCreateLeaseWithoutRequiredDateThrowsHandledException() {
    Property__c property = createProperty();
    Contact tenant = createTenant();

    Test.startTest();
    Boolean handledExceptionThrown = false;
    try {
      LeaseAgreementController.createLease(
        tenant.Id,
        property.Id,
        'Missing dates',
        1200,
        null,
        null
      );
    } catch (AuraHandledException ex) {
      handledExceptionThrown = true;
    }
    Test.stopTest();

    Assert.isTrue(
      handledExceptionThrown,
      'Missing required Start/End Date should surface as a handled exception'
    );
  }
}
