public with sharing class VoiceOutboundPhoneNumber {
    
    private static String DYNAMODB_TABLE = 'AWSSCV_OutboundPhoneNumber';  
    private static DynamoDBAPI API = DynamoDBAPI.getInstance();
    
    public static String getLogin() {
        String orgId = UserInfo.getOrganizationId();  
        String userId = UserInfo.getUserId();
        User u = [SELECT Alias FROM User WHERE Id =: userId];
        String login = u.Alias + '@' + userId.substring(0, 15) + '@' + orgId.substring(0, 15);
        return login;
    }
    
    @AuraEnabled
    public static Map<String, String> getPhoneOptions() { 
        String profileName = getUserProfile();
        Map<String, String> options = new Map<String, String>();
       
        List<VoiceOutboundPhoneNumbers__mdt> VOP= [Select id,Outbound_Number__c,Profile_Name__c,MasterLabel from VoiceOutboundPhoneNumbers__mdt];
             
        
        for (VoiceOutboundPhoneNumbers__mdt vopmeta : VOP) {
            
            System.debug('Number' + vopmeta.Outbound_Number__c);
            if (vopmeta.Profile_Name__c != null && vopmeta.Profile_Name__c.contains(profileName)) {
                options.put(vopmeta.Outbound_Number__c, vopmeta.MasterLabel);  
            }
        }
        return options;
        
    }
    
    
    private static String getUserProfile() {
        User currentUser = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        return currentUser.Profile.Name;
    }
    
    
    @AuraEnabled
    public static String getPhone() {
        String login = getLogin();
        Map<String, Object> record = getRecord(login);
        if (record != null) return (String) record.get('Phone');
        return '+18001234567';
    }
    
    @AuraEnabled
    public static Boolean updatePhone(String phone) {
        String login = getLogin();
        putRecord(login, phone);  
        return true; 
    }
    
    @AuraEnabled
    public static Boolean deletePhone() {
        String login = getLogin();
        deleteRecord(login);
        return true;
    }
    
    public static Map<String, Object> getRecord(String login) {
        Map<String, Object> data = new Map<String, Object> {
            'Login' => new Map<String, String> {
                'S' => login
                    }
        };
            Map<String, Object> item;
        if (!Test.isRunningTest()) item = API.getItem(DYNAMODB_TABLE, data);
        System.debug(item);
        return item;
    } 
    
    @future(callout=true)
    public static void putRecord(String login, String phone) { 
        Map<String, Object> data = new Map<String, Object> {
            'Login' => new Map<String, String> {
                'S' => login
                    },
                        'Phone' => new Map<String, String> {
                            'S' => phone
                                }
        };
            if (!Test.isRunningTest()) API.putItem(DYNAMODB_TABLE, data);
    }
    
    @future(callout=true)
    public static void deleteRecord(String login) {
        Map<String, Object> data = new Map<String, Object> {
            'Login' => new Map<String, String> {
                'S' => login
                    }
        };
            if (!Test.isRunningTest()) API.deleteItem(DYNAMODB_TABLE, data);
    }
    
}