
import "package:google_oauth2_client/google_oauth2_console.dart";
import "package:google_datastore_v1beta2_api/datastore_v1beta2_api_client.dart" as client;
import "package:google_datastore_v1beta2_api/datastore_v1beta2_api_console.dart" as console;

void main(args) {
  print("Hello, World!");
  var projectId = args[0];
  var projectNumber = args[1];
  print("project id = $projectId");
  print("project number = $projectNumber");
  ComputeOAuth2Console computeEngineClient = new ComputeOAuth2Console(projectNumber);

  console.Datastore datastore = new console.Datastore(computeEngineClient);
  datastore.makeAuthRequests = true;

  var beginTransactionRequest = new client.BeginTransactionRequest.fromJson({});

  // client.Client
  datastore.datasets.beginTransaction(beginTransactionRequest, projectId)
  .then((client.BeginTransactionResponse beginTransactionResponse) {
    // beginTransactionResponse = resp;
    var transaction = beginTransactionResponse.transaction;
    var lookupRequest = new client.LookupRequest.fromJson({});
    var key = new client.Key.fromJson({});
    var path = new client.KeyPathElement.fromJson({'kind': 'Trivia', 'name': 'hgtg'});
    key.path = new List<client.KeyPathElement>();
    key.path.add(path);
    lookupRequest.keys = new List<client.Key>();
    lookupRequest.keys.add(key);
    lookupRequest.readOptions =  new client.ReadOptions.fromJson({'transaction': transaction});
    datastore.datasets.lookup(lookupRequest, projectId)
        .then((client.LookupResponse lookupResponse) {
      var req = new client.CommitRequest.fromJson({});
      req.transaction = transaction;

      client.Entity entity;
      if (lookupResponse.found.isNotEmpty) {
        // Get the entity from the response if foudn
        entity = lookupResponse.found.first.entity;
      } else {
        // If no entity was found, insert a new one in the commit request mutation.
        entity = new client.Entity.fromJson({});
        req.mutation.insert.add(entity);
        entity.key = new client.Key.fromJson(key.toJson());

        client.Property property = new client.Property.fromJson({});
        property.stringValue = "Meaning of life?";
        entity.properties['question'] = property;

        property = new client.Property.fromJson({});
        property.integerValue = 42;
        entity.properties['answer'] = property;

        datastore.datasets.commit(req, projectId)
        .then((client.CommitResponse commitResponse) { });

        print("> entity = ${entity.properties}");

      }
    });
  });
}

//import logging
//import sys
//
//import googledatastore as datastore
//
//def main():
//  # Set dataset id from command line argument.
//  if len(sys.argv) < 2:
//    print 'Usage: adams.py <DATASET_ID>'
//    sys.exit(1)
//  # Set the dataset from the command line parameters.
//  datastore.set_options(dataset=sys.argv[1])
//  try:
//    # Create a RPC request to begin a new transaction.
//    req = datastore.BeginTransactionRequest()
//    # Execute the RPC synchronously.
//    resp = datastore.begin_transaction(req)
//    # Get the transaction handle from the response.
//    tx = resp.transaction
//    # Create a RPC request to get entities by key.
//    req = datastore.LookupRequest()
//    # Create a new entity key.
//    key = datastore.Key()
//    # Set the entity key with only one `path_element`: no parent.
//    path = key.path_element.add()
//    path.kind = 'Trivia'
//    path.name = 'hgtg'
//    # Add one key to the lookup request.
//    req.key.extend([key])
//    # Set the transaction, so we get a consistent snapshot of the
//    # entity at the time the transaction started.
//    req.read_options.transaction = tx
//    # Execute the RPC and get the response.
//    resp = datastore.lookup(req)
//    # Create a RPC request to commit the transaction.
//    req = datastore.CommitRequest()
//    # Set the transaction to commit.
//    req.transaction = tx
//    if resp.found:
//      # Get the entity from the response if found.
//      entity = resp.found[0].entity
//    else:
//      # If no entity was found, insert a new one in the commit request mutation.
//      entity = req.mutation.insert.add()
//      # Copy the entity key.
//      entity.key.CopyFrom(key)
//      # Add two entity properties:
//      # - a utf-8 string: `question`
//      prop = entity.property.add()
//      prop.name = 'question'
//      prop.value.string_value = 'Meaning of life?'
//      # - a 64bit integer: `answer`
//      prop = entity.property.add()
//      prop.name = 'answer'
//      prop.value.integer_value = 42
//    # Execute the Commit RPC synchronously and ignore the response:
//    # Apply the insert mutation if the entity was not found and close
//    # the transaction.
//    datastore.commit(req)
//    # Get question property value.
//    question = entity.property[0].value.string_value
//    # Get answer property value.
//    answer = entity.property[1].value.integer_value
//    # Print the question and read one line from stdin.
//    print question
//    result = raw_input('> ')
//    if result == str(answer):
//      print ('fascinating, extraordinary and, '
//             'when you think hard about it, completely obvious.')
//    else:
//      print "Don't Panic!"
//  except datastore.RPCError as e:
//    # RPCError is raised if any error happened during a RPC.
//    # It includes the `method` called and the `reason` of the
//    # failure as well as the original `HTTPResponse` object.
//    logging.error('Error while doing datastore operation')
//    logging.error('RPCError: %(method)s %(reason)s',
//                  {'method': e.method,
//                   'reason': e.reason})
//    logging.error('HTTPError: %(status)s %(reason)s',
//                  {'status': e.response.status,
//                   'reason': e.response.reason})
//    return
//
//if __name__ == '__main__':
//  main()
