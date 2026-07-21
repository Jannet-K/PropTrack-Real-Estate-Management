public with sharing class PropertyImageLinker {
  public class LinkRequest {
    @InvocableVariable(required=true)
    public Id recordId;

    @InvocableVariable(required=true)
    public List<String> contentDocumentIds;
  }

  @InvocableMethod(
    label='Link Property Images'
    description='Links previously uploaded Content Documents to the given record.'
  )
  public static void linkImages(List<LinkRequest> requests) {
    List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();

    for (LinkRequest request : requests) {
      if (request.recordId == null || request.contentDocumentIds == null) {
        continue;
      }
      for (String docId : request.contentDocumentIds) {
        if (String.isBlank(docId)) {
          continue;
        }
        linksToInsert.add(
          new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId = request.recordId,
            ShareType = 'V',
            Visibility = 'AllUsers'
          )
        );
      }
    }

    if (!linksToInsert.isEmpty()) {
      insert linksToInsert;
    }
  }
}
