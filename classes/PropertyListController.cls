public with sharing class PropertyListController {
  private static final String BASE_FIELDS =
    'Id, Name, Property_Name__c, Address__c, City__c, State__c, Postal_Code__c, ' +
    'Country__c, Type__c, Furnishing_Status__c, Status__c, Rent__c';

  public class PagedResult {
    @AuraEnabled
    public List<Property__c> records;
    @AuraEnabled
    public Integer totalRecords;
    @AuraEnabled
    public Integer pageNumber;
    @AuraEnabled
    public Integer pageSize;
  }

  @AuraEnabled(cacheable=true)
  public static PagedResult getProperties(
    Integer pageNumber,
    Integer pageSize,
    Decimal minRent,
    Decimal maxRent,
    String status,
    String furnishingStatus
  ) {
    Integer safePageNumber = (pageNumber == null ||
      pageNumber < 1)
      ? 1
      : pageNumber;
    Integer safePageSize = (pageSize == null || pageSize < 1) ? 25 : pageSize;
    Integer offsetValue = (safePageNumber - 1) * safePageSize;

    List<String> conditions = new List<String>();
    Map<String, Object> bindMap = new Map<String, Object>();

    if (minRent != null) {
      conditions.add('Rent__c >= :minRent');
      bindMap.put('minRent', minRent);
    }
    if (maxRent != null) {
      conditions.add('Rent__c <= :maxRent');
      bindMap.put('maxRent', maxRent);
    }
    if (String.isNotBlank(status)) {
      conditions.add('Status__c = :status');
      bindMap.put('status', status);
    }
    if (String.isNotBlank(furnishingStatus)) {
      conditions.add('Furnishing_Status__c = :furnishingStatus');
      bindMap.put('furnishingStatus', furnishingStatus);
    }

    String whereClause = conditions.isEmpty()
      ? ''
      : ' WHERE ' + String.join(conditions, ' AND ');

    bindMap.put('safePageSize', safePageSize);
    bindMap.put('offsetValue', offsetValue);

    String recordsQuery =
      'SELECT ' +
      BASE_FIELDS +
      ' FROM Property__c' +
      whereClause +
      ' ORDER BY CreatedDate DESC LIMIT :safePageSize OFFSET :offsetValue';
    String countQuery = 'SELECT COUNT() FROM Property__c' + whereClause;

    List<Property__c> pageOfRecords = Database.queryWithBinds(
      recordsQuery,
      bindMap,
      AccessLevel.USER_MODE
    );
    Integer totalCount = Database.countQueryWithBinds(
      countQuery,
      bindMap,
      AccessLevel.USER_MODE
    );

    PagedResult result = new PagedResult();
    result.records = pageOfRecords;
    result.totalRecords = totalCount;
    result.pageNumber = safePageNumber;
    result.pageSize = safePageSize;
    return result;
  }
}
