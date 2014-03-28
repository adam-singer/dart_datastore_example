Getting started with Google Cloud Datastore and Dart
====================================================

Before running through the steps below, make sure that:

* You have [enabled](https://developers.google.com/datastore/docs/activate) Google Cloud Datastore API.
* You have your `<dataset-id>` (same identifier as your Google Cloud [Project ID](https://developers.google.com/datastore/docs/activate#project_id)).
* You are [connected](https://developers.google.com/compute/docs/instances#sshing) to a Compute Engine instance with both the `datastore` and
`userinfo.email` [scopes](https://developers.google.com/compute/docs/authentication#using) or have a [<service-account>](https://developers.google.com/datastore/docs/activate#service_account) and the [<path-to-private-key-file>](https://developers.google.com/datastore/docs/activate#private_key).
* You have a working dart environment # TODO(adam): write up the setup scripts inline

In order to make API calls to the Datastore, pubspec.yaml file needs the following

```
dependencies:
  google_oauth2_client: '>=0.3.6 <0.3.7'
  google_datastore_v1beta2_api: ">=0.4.0 <0.5.0"
```

Then, get the `dart_datastore_example` sample:

```
git clone https://github.com/financeCoding/dart_datastore_example.git
cd dart_datastore_example
pub install
```

If you are not connected to a Compute Engine instance, make sure to run
the following commands (in a bash-like shell):

```
# convert the .p12 private key file to a .pem file
# if asked to enter import password, use "notasecret"

openssl pkcs12 -in <privatekey>.p12 -nocerts -passin pass:notasecret -nodes -out <rsa_private_key>.pem

# configure your credentials
export DATASTORE_SERVICE_ACCOUNT=<service-account>
export DATASTORE_PRIVATE_KEY_FILE=<path-to-pem-file>
export CLOUD_PROJECT_ID=<project-id>
export CLOUD_PROJECT_NUMBER=<project-number>
```

Alternatively the sample allows for passing parameters via commandline:

```
cd dart_datastore_example
pub install
cd bin
# dart dart_datastore_example.dart <project-id> <project-number> <path-to-pem-file> <service-account>
dart dart_datastore_example.dart dartcloud 657648630269 privatekey.pem 657648630269-ge2he8e46y4u42bd89nmgtj52j3ilzvv@developer.gserviceaccount.com
``` 

Example output on first run:

```
dartcloud
657648630269
privatekey.pem
657648630269-ge2he8e46y4u42bd89nmgtj52j3ilzvv@developer.gserviceaccount.com
did not found entity
> entity = {question: {"stringValue":"Meaning of life?"}, answer: {"integerValue":42}}
```

Example output on second run:

```
dartcloud
657648630269
privatekey.pem
657648630269-ge2he8e46y4u42bd89nmgtj52j3ilzvv@developer.gserviceaccount.com
found entity = {"key":{"partitionId":{"datasetId":"s~dartcloud"},"path":[{"kind":"Trivia","name":"hgtg"}]},"properties":{"question":{"stringValue":"Meaning of life?"},"answer":{"integerValue":42}}}
> entity = {question: {"stringValue":"Meaning of life?"}, answer: {"integerValue":42}}
```

The comments in the sample's source explain its behavior in detail:

```
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
```

With this example, you learned how to use the:

* [google_datastore_v1beta1_api](http://pub.dartlang.org/packages/google_datastore_v1beta1_api) dart package to connect to the Datastore API.
* [beginTransaction]() method to start a transaction.
* [lookup](https://developers.google.com/datastore/docs/apis/v1beta2/datasets/lookup) method to retrieve entities by key from your dataset.
* [commit](https://developers.google.com/datastore/docs/apis/v1beta2/datasets/commit) method to send mutations to entities in your dataset and commit the transaction.

Now, you are ready to learn more about the [Key Datastore Concepts](https://developers.google.com/datastore/docs/concepts/) and look at the [JSON API reference](https://developers.google.com/datastore/docs/apis/v1beta2/).

