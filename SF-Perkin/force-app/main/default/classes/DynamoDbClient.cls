public with sharing class DynamoDbClient {

    private static DynamoDbClient client = null;

    private String service = 'dynamodb';
    private String content_type = 'application/x-amz-json-1.0';
    private String method = 'POST';

    private String access_key;
    private String secret_key;
    private String region;
    private String host;
    private String endpoint; 

    private DynamoDbClient() { }

    public static DynamoDbClient GetInstance() {
        if (client == null) {
            AWS_Connection__mdt Connection = [SELECT Access_Key__c, Secret_Key__c, Region__c FROM AWS_Connection__mdt WHERE Default__c = true][0];
            client = new DynamoDbClient();
            client.access_key = Connection.Access_key__c;
            client.secret_key = Connection.Secret_key__c;
            client.region = Connection.Region__c; 
            client.host = client.service + '.' + client.region + '.amazonaws.com';
            client.endpoint = 'https://'+ client.host + '/';
        }
        System.debug('Dynamo Db Get INstancle client ' + client);
        return client; 
    }

    public String request(String target, Object parameters) {
        System.debug(endpoint);
        String amz_target = 'DynamoDB_20120810.' + target;
        String payload = JSON.serialize(parameters);

        System.debug(payload);

        if (access_key == null) throw new IllegalArgumentException('Access key not found');
        if (secret_key == null) throw new IllegalArgumentException('Secret key not found');
        
        // Create a date for headers and the credential string
        Datetime t = Datetime.now();
        String amz_date = t.formatGmt('yyyyMMdd\'T\'HHmmss\'Z\'');
        String datestamp = t.formatGmt('yyyyMMdd'); // date w/o time, used in credential scope

        System.debug(amz_date);
                
        // ************* TASK 1: CREATE A CANONICAL REQUEST *************
        // http://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
        
        // Step 1 is to define the verb (GET, POST, etc.)--already done.
        
        // Step 2: Create canonical URI--the part of the URI from domain to query 
        // string (use '/' if no path)
        String canonical_uri = '/';
        
        // Step 3: Create the canonical query string. In this example,
        // request parameters are in the query string. Query string values must
        // be URL-encoded (space=%20). The parameters must be sorted by name.
        // For this example, the query string is pre-formatted in the request_parameters variable.
        String canonical_querystring = '';
        
        // Step 4: Create the canonical headers and signed headers. Header names
        // must be trimmed and lowercase, and sorted in code point order from
        // low to high. Note that there is a trailing \n.
        String canonical_headers = 'content-type:' + content_type + '\n' + 'host:' + host + '\n' + 'x-amz-date:' + amz_date + '\n' + 'x-amz-target:' + amz_target + '\n';
        
        System.debug(canonical_headers);

        // Step 5: Create the list of signed headers. This lists the headers
        // in the canonical_headers list, delimited with ";" and in alpha order.
        // Note: The request can include any headers; canonical_headers and
        // signed_headers lists those that you want to be included in the 
        // hash of the request. "Host" and "x-amz-date" are always required.
        String signed_headers = 'content-type;host;x-amz-date;x-amz-target';
        
        // Step 6: Create payload hash. In this example, the payload (body of
        // the request) contains the request parameters.
        String payload_hash = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(payload))); // hashlib.sha256(request_parameters.encode('utf-8')).hexdigest();

        System.debug(payload_hash);
        
        // Step 7: Combine elements to create canonical request
        String canonical_request = method + '\n' + canonical_uri + '\n' + canonical_querystring + '\n' + canonical_headers + '\n' + signed_headers + '\n' + payload_hash;

        System.debug(canonical_request);
        
        // ************* TASK 2: CREATE THE STRING TO SIGN*************
        // Match the algorithm to the hashing algorithm you use, either SHA-1 or
        // SHA-256 (recommended)
        String algorithm = 'AWS4-HMAC-SHA256';
        String credential_scope = datestamp + '/' + region + '/' + service + '/' + 'aws4_request';
        // python: string_to_sign = algorithm + '\n' +  amz_date + '\n' +  credential_scope + '\n' +  hashlib.sha256(canonical_request.encode('utf-8')).hexdigest()
        String request_hash = EncodingUtil.convertToHex((Crypto.generateDigest('SHA-256', Blob.valueOf(canonical_request))));
        String string_to_sign = algorithm + '\n' +  amz_date + '\n' +  credential_scope + '\n' +  request_hash;
        
        System.debug(string_to_sign);

        // ************* TASK 3: CALCULATE THE SIGNATURE *************
        // Create the signing key using the function defined above.
        System.debug('secret_key:' + secret_key + ' datestamp:' + datestamp + ' region:' + region + ' service:' + service);

        Blob signing_key = AWSSignatureUtils.getSignatureKey(secret_key, datestamp, region, service);
        
        // Sign the string_to_sign using the signing_key
        // python: signature = hmac.new(signing_key, (string_to_sign).encode('utf-8'), hashlib.sha256).hexdigest()
        String signature = EncodingUtil.convertToHex(Crypto.generateMac('hmacSHA256', Blob.valueOf(string_to_sign), signing_key));
        
        System.debug(signature);

        // ************* TASK 4: ADD SIGNING INFORMATION TO THE REQUEST *************
        // The signing information can be either in a query string value or in 
        // a header named Authorization. This code shows how to use a header.
        // Create authorization header and add to request headers
        String authorization_header = algorithm + ' ' + 'Credential=' + access_key + '/' + credential_scope + ', ' +  'SignedHeaders=' + signed_headers + ', ' + 'Signature=' + signature;

        System.debug(authorization_header);
        
        // The request can include any headers, but MUST include "host", "x-amz-date", 
        // and (for this scenario) "Authorization". "host" and "x-amz-date" must
        // be included in the canonical_headers and signed_headers, as noted
        // earlier. Order here is not significant.
        // Python note: The 'host' header is added automatically by the Python 'requests' library.
        Map<String, String> headers = new Map<String, String>();
        headers.put('Host', host);
        headers.put('Content-Type', content_type);
        headers.put('Authorization', authorization_header);
        headers.put('X-Amz-Date', amz_date);
        headers.put('X-Amz-Target', amz_target);

        String response = this.post(endpoint, headers, payload);
		System.debug('Data/response in request method ' + response);
        System.debug('Payload in request method ' + payload);
        //Object results = (Object) JSON.deserializeUntyped(response.getBody());

        return response;

    }

    private String post(String uri, Map<String, String> headers, String data) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(uri);
        request.setMethod('POST');
        for (String key : headers.keySet()) request.setHeader(key, headers.get(key));
        request.setBody(data);
        System.debug('Data in post method ' + data);
        if (Test.isRunningTest()) {
            return data;
        }
        HttpResponse response = http.send(request);
        System.debug(response);
        System.debug(response.getBody());
        if (response.getStatusCode() == 200) return response.getBody();
        return null;
    }
    
}