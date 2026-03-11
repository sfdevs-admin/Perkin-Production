/*
// AWS v4 Signing
// Converted from the python example code
// See: http://docs.aws.amazon.com/general/latest/gr/sigv4_signing.html
*/

public class DynamoDBAPI {

    private static DynamoDBAPI instance = null;

    private DynamoDBAPI() {}

    public static DynamoDBAPI getInstance() {
        if (instance == null) {
            instance = new DynamoDBAPI();
        }
        return instance;
    }

    
    public Map<String, Object> getItem(String tableName, Map<String, Object> key){
        System.debug('test'+JSON.serialize(key));
        Map<String, Object> parameters = new Map<String, Object> {
            'TableName' => tableName,
            'Key' => key
        };
        String jsonString = DynamoDbClient.GetInstance().request('GetItem', parameters);
        System.debug('getItem data => ' + jsonString);
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        //if (!data.containsKey('Item')) return null;
        
        if (!key.containsKey('Item')) return null;
        //Map<String, Object> item = (Map<String, Object>) data.get('Item');
        Map<String, Object> item = data.containsKey('Item') ? (Map<String, Object>) data.get('Item')
            : new Map<String, Object>();
        
        Map<String, Object> output = new Map<String, Object>();
        for (String k : item.keySet()) {
            Map<String, Object> v = (Map<String, Object>) item.get(k);
            for (String t : v.keySet()) {output.put(k, v.get(t));break;
            }
        }
        return output;
    }
    

    public void putItem(String tableName, Map<String, Object> item){
        System.debug(JSON.serialize(item));
        Map<String, Object> parameters = new Map<String, Object> {
            'TableName' => tableName,
            'Item' => item
        }; 
        DynamoDbClient.GetInstance().request('PutItem', parameters);
    }

    public void deleteItem(String tableName, Map<String, Object> key) {
        Map<String, Object> parameters = new Map<String, Object> {  
            'TableName' => tableName,
            'Key' => key
        };
        DynamoDbClient.GetInstance().request('DeleteItem', parameters);
    }

}