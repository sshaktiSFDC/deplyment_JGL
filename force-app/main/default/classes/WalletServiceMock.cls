/**
* @name         : WalletServiceMock
* @description  : Mock service for Wallet Service
* <Date>        <Modified By>     	<Brief Description of Change>
* 2024-04-19    Siddharth Singh     Created
*/
@isTest
public class WalletServiceMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"success": true}');
        return res;
    }
}