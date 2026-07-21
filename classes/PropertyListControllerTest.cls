@isTest
private class PropertyListControllerTest {
  @TestSetup
  static void setup() {
    List<Property__c> properties = new List<Property__c>();
    for (Integer i = 0; i < 30; i++) {
      properties.add(
        new Property__c(
          Address__c = 'Address ' + i,
          City__c = 'City',
          State__c = 'State',
          Postal_Code__c = '00000',
          Country__c = 'Country',
          Type__c = (Math.mod(i, 2) == 0) ? 'Residential' : 'Commercial',
          Status__c = (Math.mod(i, 2) == 0) ? 'Available' : 'Occupied',
          Furnishing_Status__c = (Math.mod(i, 3) == 0)
            ? 'Furnished'
            : 'Unfurnished',
          Rent__c = 1000 + (i * 100),
          Description__c = 'Description ' + i
        )
      );
    }
    insert properties;
  }

  @isTest
  static void testDefaultPaginationReturnsFirst25() {
    Test.startTest();
    PropertyListController.PagedResult result = PropertyListController.getProperties(
      null,
      null,
      null,
      null,
      null,
      null
    );
    Test.stopTest();

    Assert.areEqual(
      25,
      result.records.size(),
      'Default page size should be 25'
    );
    Assert.areEqual(
      30,
      result.totalRecords,
      'Total records should reflect all inserted properties'
    );
    Assert.areEqual(1, result.pageNumber, 'Default page number should be 1');
    Assert.areEqual(25, result.pageSize, 'Default page size should be 25');
  }

  @isTest
  static void testSecondPageReturnsRemainder() {
    Test.startTest();
    PropertyListController.PagedResult result = PropertyListController.getProperties(
      2,
      25,
      null,
      null,
      null,
      null
    );
    Test.stopTest();

    Assert.areEqual(
      5,
      result.records.size(),
      'Second page should contain the remaining 5 records'
    );
    Assert.areEqual(
      30,
      result.totalRecords,
      'Total record count should be unaffected by paging'
    );
  }

  @isTest
  static void testStatusFilterNarrowsResults() {
    Test.startTest();
    PropertyListController.PagedResult result = PropertyListController.getProperties(
      1,
      25,
      null,
      null,
      'Available',
      null
    );
    Test.stopTest();

    Assert.areEqual(
      15,
      result.totalRecords,
      'Half of the seeded properties are Available'
    );
    for (Property__c prop : result.records) {
      Assert.areEqual(
        'Available',
        prop.Status__c,
        'Only Available properties should be returned'
      );
    }
  }

  @isTest
  static void testFurnishingStatusFilterNarrowsResults() {
    Test.startTest();
    PropertyListController.PagedResult result = PropertyListController.getProperties(
      1,
      25,
      null,
      null,
      null,
      'Furnished'
    );
    Test.stopTest();

    Assert.areEqual(
      10,
      result.totalRecords,
      'A third of the seeded properties are Furnished'
    );
    for (Property__c prop : result.records) {
      Assert.areEqual(
        'Furnished',
        prop.Furnishing_Status__c,
        'Only Furnished properties should be returned'
      );
    }
  }

  @isTest
  static void testRentRangeFilterNarrowsResults() {
    Test.startTest();
    PropertyListController.PagedResult result = PropertyListController.getProperties(
      1,
      25,
      1000,
      1200,
      null,
      null
    );
    Test.stopTest();

    Assert.areEqual(
      3,
      result.totalRecords,
      'Only rents 1000, 1100 and 1200 fall in range'
    );
    for (Property__c prop : result.records) {
      Assert.isTrue(
        prop.Rent__c >= 1000 && prop.Rent__c <= 1200,
        'Every returned property should fall within the rent range'
      );
    }
  }

  @isTest
  static void testPageBeyondAvailableDataReturnsEmpty() {
    Test.startTest();
    PropertyListController.PagedResult result = PropertyListController.getProperties(
      5,
      25,
      null,
      null,
      null,
      null
    );
    Test.stopTest();

    Assert.areEqual(
      0,
      result.records.size(),
      'A page past the end of the data should return no records'
    );
    Assert.areEqual(
      30,
      result.totalRecords,
      'Total record count should still reflect all seeded properties'
    );
  }

  @isTest
  static void testSecurityEnforcedBlocksUserWithoutAccess() {
    Profile minimumAccessProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Minimum Access - Salesforce'
      LIMIT 1
    ];
    User restrictedUser = new User(
      FirstName = 'Restricted',
      LastName = 'Tester',
      Alias = 'rtest',
      Email = 'restricted.tester@proptrack.test.invalid',
      Username = 'restricted.tester@proptrack.test.invalid.' +
        DateTime.now().getTime(),
      TimeZoneSidKey = 'America/Los_Angeles',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      ProfileId = minimumAccessProfile.Id
    );
    insert restrictedUser;

    System.runAs(restrictedUser) {
      try {
        PropertyListController.getProperties(1, 25, null, null, null, null);
        Assert.fail(
          'Expected WITH SECURITY_ENFORCED to block a user without Property__c access'
        );
      } catch (System.QueryException qe) {
        Assert.isTrue(
          qe.getMessage().length() > 0,
          'A security exception should be thrown'
        );
      }
    }
  }
}
