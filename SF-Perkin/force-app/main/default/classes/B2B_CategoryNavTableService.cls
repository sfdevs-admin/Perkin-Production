// test class- B2B_CategoryNavTableControllerTest
public without sharing class B2B_CategoryNavTableService {
    private static String firstCategoryLabel = 'Kits & Bundles';
    private static String lastCategoryLabel = 'Other Parts';
    public B2B_CategoryNavTableService() {

    }

    public static Map<String,Object> fetchChildCategories(Map<String,Object> mapParams){
        Boolean isSuccess = false;
        String message = '';
        System.debug('fetchChildCategories mapParams-- '+JSON.serialize(mapParams));
        if( mapParams.containsKey('categoryId') ){
            String categoryId = (String)mapParams.get('categoryId');
            if( String.isNotBlank( categoryId ) ){
                List<B2B_Commerce_Category__c> childCategoryList = new List<B2B_Commerce_Category__c>();
                if ( Schema.sObjectType.B2B_Commerce_Category__c.isAccessible() ) {
                    childCategoryList = [SELECT Id, Name, Active__c, Label__c, Parent_Category__c, Child_Category__c, Technology_Type__c 
                                         FROM B2B_Commerce_Category__c 
                                         WHERE Parent_Category__c = :categoryId AND Active__c = true 
                                         
                                        ORDER BY Technology_Type__c,Label__c];
                } else {
                    message = 'Insufficient permissions to access B2B_Commerce_Category__c object';
                }
                if( ! childCategoryList.isEmpty() ){
                    Map<String,List<Object>> childCategoryMap = new Map<String,List<Object>>();
                    for( B2B_Commerce_Category__c childCategory : childCategoryList ){
                        List<Object> categoryList = !childCategoryMap.containsKey( childCategory.Technology_Type__c ) ?
                            new List<Object>() :
                        childCategoryMap.get(childCategory.Technology_Type__c);
                       
                         
                        if(childCategory.Label__c == firstCategoryLabel){
                            categoryList.add(0,childCategory);
                        }else if(childCategory.Label__c == lastCategoryLabel){
                            categoryList.add(1,childCategory);
                        }else{
                            categoryList.add(childCategory);
                        }
                        childCategoryMap.put(childCategory.Technology_Type__c ,categoryList );
                        
                    }
                    List<CategoryWrapper> categoryWrapperList = new List<CategoryWrapper>();
                    for( String technologyType : childCategoryMap.keySet() ){
                        CategoryWrapper wrap = new CategoryWrapper();
                        wrap.technologyType = technologyType;
                        List<Object> categoryList = childCategoryMap.get(technologyType);
                        if(!categoryList.isEmpty()){
                            if(categoryList.size() > 2 && 
                               ((B2B_Commerce_Category__c)categoryList[1]).Label__c == lastCategoryLabel){
                                categoryList.add(categoryList[1]);
                                categoryList.remove(1);
                            }
                        }
                        wrap.childCategoryList = categoryList;
                        categoryWrapperList.add(wrap);
                    }
                    mapParams.put('childCategoryMap', childCategoryMap);
                    mapParams.put('categoryWrapperList', categoryWrapperList);
                    isSuccess = true;
                }
                else{
                    message = 'No child categories found';
                }
            }
            else{
                message = 'Category Id is missing';
            }
        }
         else{
            message = 'Category Id is missing';
        }
        mapParams.put('isSuccess', isSuccess);
        mapParams.put('message', message);
        return mapParams;
    }

    public class CategoryWrapper {
        @AuraEnabled
        public String technologyType;
        @AuraEnabled
        public List<Object> childCategoryList;
    }
}