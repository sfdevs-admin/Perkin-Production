public interface CustomDynamoDBAPI {
    Map<String, Object> getItem(String tableName, Map<String, Object> key);
    void putItem(String tableName, Map<String, Object> item);
    void deleteItem(String tableName, Map<String, Object> key);
}