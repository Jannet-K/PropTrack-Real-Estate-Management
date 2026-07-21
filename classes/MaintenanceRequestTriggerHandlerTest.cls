@isTest
private class MaintenanceRequestTriggerHandlerTest {
  private static final Id VENDOR_RECORD_TYPE_ID = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
    .get('Vendor')
    .getRecordTypeId();

  private static Contact createVendor(String name) {
    Contact vendor = new Contact(
      RecordTypeId = VENDOR_RECORD_TYPE_ID,
      FirstName = name,
      LastName = 'Vendor',
      Phone = '+1 5550001234',
      Email = name.deleteWhitespace() + '@example.com'
    );
    insert vendor;
    return vendor;
  }

  @isTest
  static void testAssignsToVendorWithLeastActiveWorkload() {
    Contact busyVendor = createVendor('Busy');
    Contact mediumVendor = createVendor('Medium');
    Contact freeVendor = createVendor('Free');

    insert new List<Maintenance_Request__c>{
      new Maintenance_Request__c(
        Vendor_Contact__c = busyVendor.Id,
        Status__c = 'Open'
      ),
      new Maintenance_Request__c(
        Vendor_Contact__c = busyVendor.Id,
        Status__c = 'In Progress'
      ),
      new Maintenance_Request__c(
        Vendor_Contact__c = mediumVendor.Id,
        Status__c = 'Open'
      ),
      new Maintenance_Request__c(
        Vendor_Contact__c = freeVendor.Id,
        Status__c = 'Completed'
      )
    };

    Test.startTest();
    Maintenance_Request__c newRequest = new Maintenance_Request__c(
      Description__c = 'Leaking faucet'
    );
    insert newRequest;
    Test.stopTest();

    Maintenance_Request__c inserted = [
      SELECT Vendor_Contact__c
      FROM Maintenance_Request__c
      WHERE Id = :newRequest.Id
    ];
    Assert.areEqual(
      freeVendor.Id,
      inserted.Vendor_Contact__c,
      'Request should be assigned to the vendor with zero active (Open/In Progress) requests, ' +
      'since the free vendor\'s Completed request should not count toward workload'
    );
  }

  @isTest
  static void testExplicitVendorAssignmentIsNotOverridden() {
    Contact chosenVendor = createVendor('Chosen');
    createVendor('Other');

    Test.startTest();
    Maintenance_Request__c request = new Maintenance_Request__c(
      Vendor_Contact__c = chosenVendor.Id,
      Description__c = 'Broken window'
    );
    insert request;
    Test.stopTest();

    Maintenance_Request__c inserted = [
      SELECT Vendor_Contact__c
      FROM Maintenance_Request__c
      WHERE Id = :request.Id
    ];
    Assert.areEqual(
      chosenVendor.Id,
      inserted.Vendor_Contact__c,
      'An explicitly chosen vendor should not be overridden by auto-assignment'
    );
  }

  @isTest
  static void testBulkInsertDistributesAcrossVendors() {
    Contact vendorOne = createVendor('One');
    Contact vendorTwo = createVendor('Two');

    List<Maintenance_Request__c> newRequests = new List<Maintenance_Request__c>{
      new Maintenance_Request__c(Description__c = 'Request 1'),
      new Maintenance_Request__c(Description__c = 'Request 2')
    };

    Test.startTest();
    insert newRequests;
    Test.stopTest();

    Set<Id> vendorIdsUsed = new Set<Id>();
    for (Maintenance_Request__c request : [
      SELECT Vendor_Contact__c
      FROM Maintenance_Request__c
      WHERE Id IN :newRequests
    ]) {
      vendorIdsUsed.add(request.Vendor_Contact__c);
    }
    Assert.areEqual(
      2,
      vendorIdsUsed.size(),
      'Two blank-vendor requests inserted together should be spread across both vendors, ' +
      'not both piled onto the same one'
    );
  }

  @isTest
  static void testNoVendorsLeavesVendorFieldBlank() {
    Test.startTest();
    Maintenance_Request__c request = new Maintenance_Request__c(
      Description__c = 'No vendors exist yet'
    );
    insert request;
    Test.stopTest();

    Maintenance_Request__c inserted = [
      SELECT Vendor_Contact__c
      FROM Maintenance_Request__c
      WHERE Id = :request.Id
    ];
    Assert.isNull(
      inserted.Vendor_Contact__c,
      'With no vendors in the org, the request should be left unassigned rather than erroring'
    );
  }
}
