// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./lib/AddressSet.sol";
import "./lib/Bytes32Set.sol";

/// @notice : inheritable datastore layout and CRUD operations (WIP)

contract FactiivStore {

  using AddressSet for AddressSet.Set;
  using Bytes32Set for Bytes32Set.Set;

  enum Lifecycle {
    Proposed,
    Accepted,
    Closed,
    toRated,
    fromRated
  }
  bytes32 private constant NULL_BYTES32 = bytes32(0x0);
  uint256 public nonce; 
  uint256 public minimumAmount; 

  struct User {
    Bytes32Set.Set senderJoinSet; 
    Bytes32Set.Set receiverJoinSet; 
    Bytes32Set.Set attestationSet; 
  }
  AddressSet.Set userSet;
  mapping(address => User)  user; 

  struct Relationship {
    bytes32 typeId; 
    string description; 
    uint256 amount; 
    address from; 
    address to; 
    Stage[] history; 
    address arbitrator;
  }
  Bytes32Set.Set relationshipSet; 
  mapping(bytes32 => Relationship) public relationship; 

  struct Stage {
    Lifecycle lifecycle; 
    string metadata; 
  }

  struct Attestation {
    address signer;
    address user; 
    bytes32 typeId;
    string payload; 
  }
  Bytes32Set.Set attestationSet; 
  mapping(bytes32 => Attestation) public attestation; 

  Bytes32Set.Set relationshipTypeSet; 
  mapping(bytes32 => string) public relationshipTypeDesc; 
  
  Bytes32Set.Set attestationTypeSet; 
  mapping(bytes32 => string) public attestationTypeDesc;

  event NewRelationshipType(
    address indexed sender,
    bytes32 indexed id,
    string description
  );
  event UpdateRelationshipType(
    address indexed sender,
    bytes32 indexed id, 
    string desc
  );
  event NewAttestationType(
    address indexed sender,
    bytes32 indexed id,
    string description
  );
  event UpdateAttestionType(
    address indexed sender, 
    bytes32 indexed id, 
    string desc
  );
  event NewAttestation(
    address indexed signer,
    address indexed user,
    bytes32 indexed id,
    bytes32 typeId,
    string payload
  );
  event UpdateAttestation(
    address indexed signer,
    address indexed user,
    bytes32 indexed id,
    bytes32 typeId,
    string payload
  );
  event NewRelationship(
    address indexed from,
    address indexed to,
    bytes32 indexed id,
    bytes32 typeId,
    string desc,
    uint256 amount
  );
  event UpdateRelationship(
    address indexed from,
    bytes32 indexed id,
    Lifecycle lifecycle,
    string metadata
  );
  event DeleteRelationship(
      address indexed from, 
      bytes32 indexed id
  );
  event SetMinimum(
    address sender, 
    uint256 minimumAmount
  );

  /***************************
   * Master Tables
   ***************************/

  function _createRelationshipType(
    address from,
    string memory desc
  ) 
    internal
    returns(
      bytes32 id
    )
  {
    id = _keyGen();
    relationshipTypeSet.insert(
      id, 
      "FactiivStore._createRelationshipType : id exists");
    relationshipTypeDesc[id] = desc;
    emit NewRelationshipType(from, id, desc);
  }

  function _updateRelationshipType(
    address from,
    bytes32 id, 
    string memory desc
  )
    internal 
  {
    require(
      relationshipTypeSet.exists(id),
      "unknown relationshipType");
    relationshipTypeDesc[id]= desc;
    emit UpdateRelationshipType(from, id, desc);
  }

  function _createAttestationType(
    address from,
    string memory desc
  )
    internal 
    returns(
      bytes32 id
    )
  {
    id = _keyGen();
    attestationTypeSet.insert(
      id, 
      "FactiivStore._createAttestationType : id exists");
    attestationTypeDesc[id] = desc;
    emit NewAttestationType(from, id, desc);
  }

  function _updateAttestationType(
    address from,
    bytes32 id, 
    string memory desc
  )
    internal
  {
    require(
      attestationTypeSet.exists(id),
      "FactivvStore._updateAttestionType : unknown id"
    );
    attestationTypeDesc[id] = desc;
    emit UpdateAttestionType(from, id, desc);
  }

  /***************************
   * Attestations
   ***************************/

  function _createAttestation(
    address from,
    address subject,
    bytes32 typeId,
    string memory payload
  )
    internal 
    returns (bytes32 id) 
  {
    id = _keyGen();
    Attestation storage a = attestation[id];
    User storage u = user[subject];
    a.signer = from;
    a.user = subject;
    a.typeId = typeId;
    a.payload = payload;
    u.attestationSet.insert(
      id,
      "FactiivStore._createAttestation : id exists (user)"
    );
    attestationSet.insert(
      id,
      "FactiivStore._createAttestation : id exists"
    );
    emit NewAttestation(from, subject, id, typeId, payload);
  }

  /// @dev : attestion type is unchangeable, by design

  function _updateAttestation(
    address from,
    address subject,
    bytes32 id,
    string memory payload
  ) 
    internal 
  {
    require(
      attestationSet.exists(id),
      "FactiivStore.updateAttestion : unknown attestation"
    );
    Attestation storage a = attestation[id];
    a.payload = payload;
    emit UpdateAttestation(from, subject, id, a.typeId, payload);
  }

  /***************************
   * Relationships
   ***************************/

  function _createRelationship(
    address from,
    bytes32 typeId,
    string memory desc,
    uint256 amount,
    address to
  ) 
    internal 
    returns (bytes32 id) 
  {
    require(
      relationshipTypeSet.exists(typeId),
      "FactiivStore.createRelationship : unknown typeId"
    );
    require(
      amount > minimumAmount,
      "FactiivStore.createRelationship : amount below minimum"
    );
    require(
      msg.sender != to, 
      "FactiivStore.createRelationship: to = sender");
    id = _keyGen();
    Stage memory s = Stage({
      lifecycle: Lifecycle.Proposed,
      metadata: ""
    });
    Relationship storage r = relationship[id];
    User storage f = user[from];
    User storage t = user[to];
    r.typeId = typeId;
    r.amount = amount;
    r.from = from;
    r.to = to;
    r.history.push(s);
    relationshipSet.insert(
      id, 
      "FactiivStore.createRelationship : id exists");
    // the next two checks should never fail

    t.receiverJoinSet.insert(
      id,
      "FactiivStore.createRelationship : 500 (to)"
    );
    f.senderJoinSet.insert(
      id,
      "FactiivStore.createRelationship : 500 (from)"
    );
    emit NewRelationship(from, to, id, typeId, desc, amount);
  }

  function _updateRelationship(
    address from,
    bytes32 id,
    Lifecycle lifecycle,
    string memory metadata
  ) 
    internal 
  {
    Relationship storage r = relationship[id];
    require(
      relationshipSet.exists(id),
      "FactiivStore.acceptRelationship : unknown id"
    );
    Stage memory s = Stage({
      lifecycle: lifecycle,
      metadata: metadata
    });
    r.history.push(s);

    emit UpdateRelationship(
      from,
      id,
      lifecycle,
      metadata
    );
  }

  /***************************
   * Arbitration
   ***************************/

  function _deleteRelationship(
    address from,
    bytes32 id
  ) 
    internal 
  {
    Relationship storage r = relationship[id];
    User storage f = user[r.from];
    User storage t = user[r.to];
    delete relationship[id];
    relationshipSet.remove(
      id,
      "unknown relationship id"
    );
    f.senderJoinSet.remove(
      id,
      "unknown relationship id"
    );
    t.receiverJoinSet.remove(
      id,
      "unknown relationship id"
    );
    emit DeleteRelationship(
      from, 
      id
    );
  }

  /***************************
   * Internal
   ***************************/  

  function _keyGen() private returns (bytes32 uid) {
    nonce++;
    uid = keccak256(abi.encodePacked(address(this), nonce));
  }
}
