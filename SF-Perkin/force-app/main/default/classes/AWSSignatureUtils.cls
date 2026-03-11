public class AWSSignatureUtils {
    private AWSSignatureUtils() {}

    private static Blob sign(Blob key, String message) {
        return Crypto.generateMac('hmacSHA256', Blob.valueOf(message), key);
    }

    public static Blob getSignatureKey(String key, String datestamp, String region, String service) {
        Blob kDate = sign(Blob.valueOf('AWS4' + key), datestamp);
        Blob kRegion = sign(kDate, region);
        Blob kService = sign(kRegion, service);
        Blob kSigning = sign(kService, 'aws4_request');
        return kSigning;
    }
}