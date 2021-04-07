import 'package:ondemand_wrapper_gen/gen/account_inquiry.g.dart';
import 'package:ondemand_wrapper_gen/gen/base.g.dart';
import 'package:ondemand_wrapper_gen/gen/get_kitchens.g.dart' as _get_kitchens;
import 'package:ondemand_wrapper_gen/gen/login.g.dart' as _login;
import 'package:ondemand_wrapper_gen/gen/ondemand.g.dart';

Map<String, String> env = Platform.environment;

final UID = env['UID'];

Map<String, String> headers(String accessToken) => {
  'access-token': accessToken,
  'authorization': accessToken,
};

Future<void> main(List<String> args) async {
  var ondemand = OnDemand(siteNumber: '1312');
  var res = await ondemand.login(_login.Request());
  var accessToken = res.headers['access-token'];

  var siteRequest = await ondemand.getKitchens(_get_kitchens.Request(
      headers: headers(accessToken)));
  var firstKitchen = siteRequest.kitchens.first;
  var terminalId = firstKitchen.displayOptions.onDemandTerminalId;
  var contextId = firstKitchen.kitchenSettings.kitchenContextId;
  print('Using terminal: ${firstKitchen.name}');
  print('Context ID: $contextId');
  print('Terminal ID: $terminalId\n');

  await makeInquiry(ondemand, accessToken, contextId, terminalId);
}

Future<void> makeInquiry(OnDemand ondemand, String accessToken, String contextId, String terminalId) async {
  var inquiry =
      await ondemand.accountInquiry(Request(inquiries: [
    Inquiry(
      tenderId: TenderIds.DINING_DOLLARS,
      data: Data(
        tenantId: ondemand.siteNumber,
        contextId: contextId,
        tenderId: TenderIds.DINING_DOLLARS_DATA,
        atriumTerminal: AtriumTerminal(terminalId: terminalId),
        customer: Customer(
          customerType: 'campusid',
          id: UID,
        ),
      ),
    ),
  ], headers: headers(accessToken)));

  for (var inq in inquiry.inquiries) {
    print('Tender: ${TenderIds.TENDERS[inq.tenderId]}:');
    print('Remaining: ${inq.amount.remaining} ${inq.amount.currency}');

    print('\nIndividual accounts:');
    for (var account in inq.accounts) {
      print('${account.name}: ${account.balance} ${account.currency}');
    }
  }
}

class TenderIds {
  static const TIGER_BUCKS = '9';
  static const DINING_DOLLARS = '16';

  static const TIGER_BUCKS_DATA = '1';
  static const DINING_DOLLARS_DATA = '4';

  static const TENDERS = <String, String>{
    TIGER_BUCKS: 'Tiger Bucks',
    DINING_DOLLARS: 'Dining Dollars'
  };
}
