import "dart:io";

import "package:google_oauth2_client/google_oauth2_console.dart";
import "package:google_datastore_v1beta2_api/datastore_v1beta2_api_client.dart"
    as client;
import "package:google_datastore_v1beta2_api/datastore_v1beta2_api_console.dart"
    as console;

void main(List<String> args) {
  Map<String, String> envVars = Platform.environment;
  String projectId = envVars['CLOUD_PROJECT_ID'] == null ?
      args[0] : envVars['CLOUD_PROJECT_ID'];
  String projectNumber = envVars['CLOUD_PROJECT_NUMBER'] == null ?
      args[1] : envVars['CLOUD_PROJECT_NUMBER'];
  String pemFilename = envVars['DATASTORE_PRIVATE_KEY_FILE'] == null ?
      args[2] : envVars['DATASTORE_PRIVATE_KEY_FILE'];
  String serviceAccountEmail = envVars['DATASTORE_SERVICE_ACCOUNT'] == null ?
      args[3] : envVars['DATASTORE_SERVICE_ACCOUNT'];

  print(projectId);
  print(projectNumber);
  print(pemFilename);
  print(serviceAccountEmail);

  String iss = serviceAccountEmail;
  String scopes = 'https://www.googleapis.com/auth/userinfo.email '
      'https://www.googleapis.com/auth/datastore';
  String rsa_private_key_file = new File(pemFilename).readAsStringSync();

  ComputeOAuth2Console computeEngineClient = new ComputeOAuth2Console(
      projectNumber, privateKey: rsa_private_key_file, iss: iss, scopes: scopes);

  console.Datastore datastore = new console.Datastore(computeEngineClient)
  ..makeAuthRequests = true;

  // Create a RPC request to begin a new transaction
  var beginTransactionRequest = new client.BeginTransactionRequest.fromJson({});
  String transaction;
  client.Key key;
  client.Entity entity;

  // Execute the RPC asynchronously
  datastore.datasets.beginTransaction(beginTransactionRequest, projectId).then(
      (client.BeginTransactionResponse beginTransactionResponse) {
    // Get the transaction handle from the response.
    transaction = beginTransactionResponse.transaction;

    // Create a RPC request to get entities by key.
    var lookupRequest = new client.LookupRequest.fromJson({});

    // Create a new entities by key
    key = new client.Key.fromJson({});

    // Set the entity key with only one `path_element`: no parent.
    var path = new client.KeyPathElement.fromJson({
      'kind': 'Trivia',
      'name': 'hgtg'
    });
    key.path = new List<client.KeyPathElement>();
    key.path.add(path);
    lookupRequest.keys = new List<client.Key>();

    // Add one key to the lookup request.
    lookupRequest.keys.add(key);

    // Set the transaction, so we get a consistent snapshot of the
    // entity at the time the transaction started.
    lookupRequest.readOptions = new client.ReadOptions.fromJson({
      'transaction': transaction
    });

    // Execute the RPC and get the response.
    return datastore.datasets.lookup(lookupRequest, projectId);
  }).then((client.LookupResponse lookupResponse) {
    // Create a RPC request to commit the transaction.
    var req = new client.CommitRequest.fromJson({});

    // Set the transaction to commit.
    req.transaction = transaction;

    if (lookupResponse.found.isNotEmpty) {
      // Get the entity from the response if found
      entity = lookupResponse.found.first.entity;
      print("found entity = ${entity.toString()}");
    } else {
      print("did not found entity");
      // If no entity was found, insert a new one in the commit request mutation.
      entity = new client.Entity.fromJson({});
      req.mutation = new client.Mutation.fromJson({});
      req.mutation.insert = new List<client.Entity>();
      req.mutation.insert.add(entity);

      // Copy the entity key.
      entity.key = new client.Key.fromJson(key.toJson());

      // Add two entity properties:

      // - a utf-8 string: `question`
      client.Property property = new client.Property.fromJson({});
      property.stringValue = "Meaning of life?";
      entity.properties = new Map<String, client.Property>();
      entity.properties['question'] = property;

      // - a 64bit integer: `answer`
      property = new client.Property.fromJson({});
      property.integerValue = 42;
      entity.properties['answer'] = property;

      // Execute the Commit RPC synchronously and ignore the response:
      // Apply the insert mutation if the entity was not found and close
      // the transaction.
      return datastore.datasets.commit(req, projectId);
    }
  }).then((client.CommitResponse commitResponse) =>
      print("> entity = ${entity.properties}"));
}
