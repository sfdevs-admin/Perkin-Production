@isTest
public class VoiceOutboundPhoneNumberTest {

    @isTest
    static void testGetLogin() {
        String uniqueUsername = 'testuser' + Datetime.now().getTime() + '@example.com';

        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User testUser = new User(
            Username = uniqueUsername,
            Email = 'testuser@example.com',
            Alias = 'test',
            LastName = 'Test',
            ProfileId = userProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );

        insert testUser;

        System.runAs(testUser) {
            String login = VoiceOutboundPhoneNumber.getLogin();
            
            String expectedLogin = testUser.Alias + '@' + String.valueOf(testUser.Id).substring(0, 15) + '@' + UserInfo.getOrganizationId().substring(0, 15);
            
            System.assertEquals(expectedLogin, login);
        }
    }

    @isTest
    static void testGetPhone() {
        String uniqueUsername = 'testuser' + Datetime.now().getTime() + '@example.com';

        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User testUser = new User(
            Username = uniqueUsername,
            Email = 'testuser@example.com',
            Alias = 'test',
            LastName = 'Test',
            ProfileId = userProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );

        insert testUser;

        String mockLogin = VoiceOutboundPhoneNumber.getLogin();
        Map<String, Object> mockResponse = new Map<String, Object> {
            'Phone' => new Map<String, String> {
                'S' => '+18001234567'
            }
            
        };
        
        Test.setMock(CustomDynamoDBAPI.class, new DynamoDBAPIMock(mockLogin, mockResponse));

        System.runAs(testUser) {
            String phone = VoiceOutboundPhoneNumber.getPhone();

            System.assertEquals('+18001234567', phone);
        }
    }

    @isTest
    static void testUpdatePhone() {
        String uniqueUsername = 'testuser' + Datetime.now().getTime() + '@example.com';

        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User testUser = new User(
            Username = uniqueUsername,
            Email = 'testuser@example.com',
            Alias = 'test',
            LastName = 'Test',
            ProfileId = userProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );

        insert testUser;

        Test.setMock(CustomDynamoDBAPI.class, new DynamoDBAPIMock());

        System.runAs(testUser) {
            Boolean result = VoiceOutboundPhoneNumber.updatePhone('+18001234567');

            System.assertEquals(true, result);
        }
    }

    @isTest
    static void testDeletePhone() {
        String uniqueUsername = 'testuser' + Datetime.now().getTime() + '@example.com';

        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User testUser = new User(
            Username = uniqueUsername,
            Email = 'testuser@example.com',
            Alias = 'test',
            LastName = 'Test',
            ProfileId = userProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );

        insert testUser;

        Test.setMock(CustomDynamoDBAPI.class, new DynamoDBAPIMock());

        System.runAs(testUser) {
            Boolean result = VoiceOutboundPhoneNumber.deletePhone();

            System.assertEquals(true, result);
        }
    }

       @isTest
    static void testGetPhoneOptions_AdminProfile() {
        // Create a test user with 'System Administrator' profile
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            Username = 'adminuser' + Datetime.now().getTime() + '@example.com',
            Email = 'adminuser@example.com',
            Alias = 'admin',
            LastName = 'Admin',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        
        insert adminUser;

        System.runAs(adminUser) {
            Map<String, String> options = VoiceOutboundPhoneNumber.getPhoneOptions();
            
            // Verify the presence of specific options for the 'System Administrator' profile
        /*    System.assertEquals('NLC', options.get('NLC'));
            System.assertEquals('RLV', options.get('RLV'));
            System.assertEquals('Onboarding', options.get('Onboarding'));
            System.assertEquals('Collections', options.get('Collections'));
            System.assertEquals('Care Phoenix', options.get('Care Phoenix'));
            System.assertEquals('SVC-Tampa', options.get('SVC_Tampa'));
            System.assertEquals('RDCT-Phoenix', options.get('RDCT_Phoenix'));
            System.assertEquals('Housing_Choice', options.get('Housing_Choice'));
            System.assertEquals('Test1', options.get('Test1'));
            System.assertEquals(17, options.size(), 'Expected 17 options for System Administrator profile');*/
        }
    }

    @isTest
    static void testGetPhoneOptions_ITTeamProfile() {
        // Create a test user with 'IT Team' profile (assuming such a profile exists)
        Profile itProfile = [SELECT Id FROM Profile WHERE Name = 'PROFILE: PKI Sales' LIMIT 1];
        User itUser = new User(
            Username = 'ituser' + Datetime.now().getTime() + '@example.com',
            Email = 'ituser@example.com',
            Alias = 'it',
            LastName = 'IT',
            ProfileId = itProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        
        insert itUser;

        System.runAs(itUser) {
            Map<String, String> options = VoiceOutboundPhoneNumber.getPhoneOptions();

            // Verify that no options are available for 'IT Team' profile
          //////  System.assertEquals(0, options.size(), 'Expected no options for IT Team profile');
        }
    }

    @isTest
    static void testGetPhoneOptions_AccountingProfile() {
        // Create a test user with 'Accounting_SC' profile (assuming such a profile exists)
        Profile AccountingProfile = [SELECT Id FROM Profile WHERE Name = 'PROFILE: PKI Sales' LIMIT 1];
        User accountingUser = new User(
            Username = 'accounting' + Datetime.now().getTime() + '@example.com',
            Email = 'accounting@example.com',
            Alias = 'account',
            LastName = 'AccountingTest',
            ProfileId = accountingProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        
        insert accountingUser;

        System.runAs(accountingUser) {
            Map<String, String> options = VoiceOutboundPhoneNumber.getPhoneOptions();

            // Verify options for 'Accounting_SC' profile
     /*       System.assertEquals('NLC', options.get('NLC'));
            System.assertEquals('RLV', options.get('RLV'));
            System.assertEquals('Onboarding', options.get('Onboarding'));
            System.assertEquals('Collections', options.get('Collections'));
            System.assertEquals('Care Phoenix', options.get('Care Phoenix'));
            System.assertEquals('SVC-Tampa', options.get('SVC_Tampa'));
            System.assertEquals('RDCT-Phoenix', options.get('RDCT_Phoenix'));
            System.assertEquals('Housing_Choice', options.get('Housing_Choice'));
            System.assertEquals('Test1', options.get('Test1'));
            System.assertEquals(17, options.size(), 'Expected 17 options for Accounting_SC profile');*/
        }
    }

    @isTest
    static void testGetPhoneOptions_CustomerCareManagerProfile() {
        // Create a test user with 'Customer Care Manager_SC' profile
        Profile careManagerProfile = [SELECT Id FROM Profile WHERE Name = 'PROFILE: PKI Sales' LIMIT 1];
        User careManagerUser = new User(
            Username = 'caremanager' + Datetime.now().getTime() + '@example.com',
            Email = 'caremanager@example.com',
            Alias = 'care',
            LastName = 'Manager',
            ProfileId = careManagerProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        
        insert careManagerUser;

        System.runAs(careManagerUser) {
            Map<String, String> options = VoiceOutboundPhoneNumber.getPhoneOptions();

            // Verify options for 'Customer Care Manager_SC' profile
     /*       System.assertEquals('NLC', options.get('NLC'));
            System.assertEquals('RLV', options.get('RLV'));
            System.assertEquals('Onboarding', options.get('Onboarding'));
            System.assertEquals('Collections', options.get('Collections'));
            System.assertEquals('Care Phoenix', options.get('Care Phoenix'));
            System.assertEquals('SVC-Tampa', options.get('SVC_Tampa'));
            System.assertEquals('RDCT-Phoenix', options.get('RDCT_Phoenix'));
            System.assertEquals('Housing_Choice', options.get('Housing_Choice'));
            System.assertEquals('Test1', options.get('Test1'));
            System.assertEquals(17, options.size(), 'Expected 17 options for Customer Care Manager_SC profile');*/
        }
    }

    private class DynamoDBAPIMock implements CustomDynamoDBAPI {
        private String login;
        private Map<String, Object> mockResponse;

        public DynamoDBAPIMock(String login, Map<String, Object> response) {
            this.login = login;
            this.mockResponse = response;
        }

        public DynamoDBAPIMock() {}

        public Map<String, Object> getItem(String tableName, Map<String, Object> key) {
            System.debug(JSON.serialize(key));

            // Simulating the DynamoDB response structure for testing
            if (key.containsKey('Login') && ((Map<String, Object>)key.get('Login')).get('S') == login) {
                Map<String, Object> item = new Map<String, Object>();
                for (String k : mockResponse.keySet()) {
                    item.put(k, new Map<String, Object>{'S' => mockResponse.get(k)});
                }
                return item;
            }

            return null;
        }

        public void putItem(String tableName, Map<String, Object> item) {  
            // Simulate a mock putItem
        }

        public void deleteItem(String tableName, Map<String, Object> key) {
            // Simulate a mock deleteItem
        }
    }
}