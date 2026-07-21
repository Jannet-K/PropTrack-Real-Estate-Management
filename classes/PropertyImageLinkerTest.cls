@isTest
private class PropertyImageLinkerTest {
  @isTest
  static void testLinkImagesLinksMultipleDocumentsToRecord() {
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

    ContentVersion versionOne = new ContentVersion(
      Title = 'Image One',
      PathOnClient = 'ImageOne.jpg',
      VersionData = Blob.valueOf('Image One Body')
    );
    ContentVersion versionTwo = new ContentVersion(
      Title = 'Image Two',
      PathOnClient = 'ImageTwo.jpg',
      VersionData = Blob.valueOf('Image Two Body')
    );
    insert new List<ContentVersion>{ versionOne, versionTwo };

    Set<Id> versionIds = new Set<Id>{ versionOne.Id, versionTwo.Id };
    List<ContentVersion> insertedVersions = [
      SELECT Id, ContentDocumentId
      FROM ContentVersion
      WHERE Id IN :versionIds
    ];
    List<String> contentDocumentIds = new List<String>();
    for (ContentVersion cv : insertedVersions) {
      contentDocumentIds.add(cv.ContentDocumentId);
    }

    PropertyImageLinker.LinkRequest request = new PropertyImageLinker.LinkRequest();
    request.recordId = property.Id;
    request.contentDocumentIds = contentDocumentIds;

    Test.startTest();
    PropertyImageLinker.linkImages(
      new List<PropertyImageLinker.LinkRequest>{ request }
    );
    Test.stopTest();

    List<ContentDocumentLink> links = [
      SELECT Id, ContentDocumentId, LinkedEntityId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :property.Id
    ];
    Assert.areEqual(
      2,
      links.size(),
      'Both uploaded documents should be linked to the property'
    );
  }

  @isTest
  static void testLinkImagesSkipsBlankOrMissingInput() {
    Property__c property = new Property__c(
      Address__c = '456 Oak St',
      City__c = 'Metropolis',
      State__c = 'NY',
      Postal_Code__c = '10001',
      Country__c = 'USA',
      Type__c = 'Commercial',
      Status__c = 'Occupied',
      Rent__c = 2000,
      Description__c = 'Another property'
    );
    insert property;

    PropertyImageLinker.LinkRequest blankRequest = new PropertyImageLinker.LinkRequest();
    blankRequest.recordId = null;
    blankRequest.contentDocumentIds = null;

    Test.startTest();
    PropertyImageLinker.linkImages(
      new List<PropertyImageLinker.LinkRequest>{ blankRequest }
    );
    Test.stopTest();

    List<ContentDocumentLink> links = [
      SELECT Id
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :property.Id
    ];
    Assert.areEqual(
      0,
      links.size(),
      'No links should be created for blank input'
    );
  }
}
