import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';

final ethUtilsProviders = StateNotifierProvider<EthereumUtils, bool>((ref) {
  return EthereumUtils();
});

class EthereumUtils extends StateNotifier<bool> {
  EthereumUtils() : super(true) {
    initialSetup();
  }

  final String _rpcUrl = "http://192.168.1.109:7545";
  final String _wsUrl = "ws://192.168.1.109:7545/";
  final String _privateKey = "";

  Web3Client? _ethClient; //connects to the ethereum rpc via WebSocket
  bool isLoading = true; //checks the state of the contract

  String? _abi; //used to read the contract abi
  EthereumAddress? _contractAddress; //address of the deployed contract

  EthPrivateKey? _credentials; //credentials of the smart contract deployer

  DeployedContract? _contract; //where contract is declared, for Web3dart
  ContractFunction?
      _getEmployeeCount; // stores the name getter declared in the HelloWorld.sol
  ContractFunction?
      _writeName; // stores the setName function declared in the HelloWorld.sol

  ContractFunction? _getContractCount;
  ContractFunction? _getContract;
  ContractFunction? _getEmployeeLocationCount;
  ContractFunction? _getEmployeeLocation;
  ContractFunction? _sendEmployeeLocation;

  String? deployedName;

  initialSetup() async {
    print("#########STATE INIT###############");
    http.Client _httpClient = http.Client();
    _ethClient = Web3Client(_rpcUrl, _httpClient, socketConnector: () {
      return IOWebSocketChannel.connect(_wsUrl).cast<String>();
    });
    // _ethClient = Web3Client(
    //     "https://goerli.infura.io/v3/68d9e29cfc094544a8557d52482abcb1",
    //     _httpClient);

    await getAbi();
    await getCredentials();
    await getDeployedContract();
  }

  readPKey(String key) async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(key) != null
        ? json.decode(prefs.getString(key)!)
        : null;
  }

  Future<void> getAbi() async {
    print("#########GETTING ABI#########");
    //Reading the contract abi
    String abiStringFile =
        await rootBundle.loadString("assets/abis/Refund.json");
    var jsonAbi = jsonDecode(abiStringFile);
    _abi = jsonEncode(jsonAbi["abi"]);

    _contractAddress =
        EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);
    print(_contractAddress);
    print("#########GETTING ABI#########");
  }

  Future<void> getCredentials() async {
    String pk = "";
    var val = await readPKey("p_key");
    if (val != null) {
      print("KEY");
      print(val);
      _credentials = EthPrivateKey.fromHex(val);
    } else {
      // pk = "6c3e36c0fe9fdc3441297a92d0496c686d9d939e5395c525c672a3fe7dd457ea";
      // pk = "acecb1c36ac48a41ff31140ec9085e8244b10cae341ff06af1a147ec79d0924c";
      // pk = "0x806D6834F5991FC0bdE702d546702131690Aa1d2";
      // pk = "f56eac917c3752845ae1a98b0d4210a1e51fb43357318f790ad4649403f57c06";
      pk = "acecb1c36ac48a41ff31140ec9085e8244b10cae341ff06af1a147ec79d0924c";
      // pk = "4682ee6c3e6c82fc842d3d775c360fadf3b85fa3881c947eeea388579c276215";
      _credentials = EthPrivateKey.fromHex(pk);
    }
  }

  Future<void> getDeployedContract() async {
    // Telling Web3dart where our contract is declared.
    _contract = DeployedContract(
        ContractAbi.fromJson(_abi!, "RefundByLocation"), _contractAddress!);

    // Extracting the functions, declared in contract.
    _writeName = _contract!.function("employercount");
    _getEmployeeCount = _contract!.function("employercount");
    _getContractCount = _contract!.function("contract_info_count");
    _getContract = _contract!.function("contract_infos");
    _getEmployeeLocationCount =
        _contract!.function("employee_location_infos_count");
    _getEmployeeLocation = _contract!.function("employee_location_infos");
    _sendEmployeeLocation =
        _contract!.function("create_employee_location_info");

    // getValue();
    print("############GETTING CONTRACT###########");
    print(_contractAddress);
    print("############GETTING CONTRACT###########");
  }

  getEmployeeCount() async {
    isLoading = true;
    state = isLoading;
    var currentName = await _ethClient!
        .call(contract: _contract!, function: _getEmployeeCount!, params: []);
    print("##############################");
    print(currentName);
    print("##############################");
    isLoading = false;
    state = isLoading;
  }

  getContractCount() async {
    isLoading = true;
    state = isLoading;
    var contractCount = await _ethClient!
        .call(contract: _contract!, function: _getContractCount!, params: []);
    print("##############################");
    print(contractCount);
    print("##############################");
    isLoading = false;
    state = isLoading;
    return contractCount[0];
  }

  getEmployeeLocationCount() async {
    // isLoading = true;
    // state = isLoading;
    var locationCount = await _ethClient!.call(
        contract: _contract!, function: _getEmployeeLocationCount!, params: []);
    print("##############################");
    print(locationCount);
    print("##############################");
    isLoading = false;
    state = isLoading;
    return locationCount[0];
  }

  getEmployeeLocation(BigInt index) async {
    isLoading = true;
    state = isLoading;
    var employeeLocation = await _ethClient!.call(
        contract: _contract!, function: _getEmployeeLocation!, params: [index]);
    print("##############################");
    print(employeeLocation);
    print("##############################");
    isLoading = false;
    state = isLoading;
    return employeeLocation;
  }

  getContract(BigInt index) async {
    isLoading = true;
    state = isLoading;
    var fetchedContract = await _ethClient!
        .call(contract: _contract!, function: _getContract!, params: [index]);
    print("##############################");
    print(fetchedContract);
    print("##############################");
    isLoading = false;
    state = isLoading;
    return fetchedContract;
  }

  /**
   * uint contract_id, address _employee_address, 
            uint[2] memory _lat, uint[2] memory _lng,
            string memory _timestamp, bool _status, uint _distance
   */

  sendLocation(
      BigInt contract_id,
      BigInt latitude,
      BigInt latOffset,
      BigInt longitude,
      BigInt lngOffset,
      String empAddress,
      String timeStamp,
      bool status,
      BigInt distance) async {
    // Setting the name to nameToSet(name defined by user)
    isLoading = true;
    state = isLoading;
    // notifyListeners();
    await _ethClient!.sendTransaction(
        _credentials!,
        Transaction.callContract(
            contract: _contract!,
            function: _sendEmployeeLocation!,
            parameters: [
              contract_id,
              EthereumAddress.fromHex(empAddress),
              [latitude, latOffset],
              [longitude, lngOffset],
              timeStamp,
              status,
              distance
            ]));
    // getValue();
  }
}
