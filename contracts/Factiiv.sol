// SPDX-License-Identifier: MIT

pragma solidity 0.8.4; 

import "./FactiivStore.sol";
import "./_openZeppelin/AccessControl.sol";

contract Factiiv is FactiivStore, AccessControl {

  using Bytes32Set for Bytes32Set.Set;

  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
  bytes32 public constant ATTESTOR_ROLE = keccak256("ATTESTER_ROLE");
  bytes32 public constant ARBITRATOR_ROLE = keccak256("ARBITRATOR ROLE");

  //Testing Errors 

  // function createRelationship()
  // function createAttestation()
  // and probably every other function using Bytes as arguments 
  // Error: invalid arrayify value ()

  constructor(address root, address forwarder) {
    _setupRole(DEFAULT_ADMIN_ROLE, root);
    _setupRole(GOVERNANCE_ROLE, root);
    _setTrustedForwarder(forwarder);
  }

  string public override versionRecipient = "2.2.0";
  /***************************
   * Master Tables
   ***************************/

  function setMinimumAmount(uint256 minimum) external onlyRole(GOVERNANCE_ROLE) {
    minimumAmount = minimum;
    emit SetMinimum(_msgSender(), minimum);
  }
  function getCurrentAccount() external view returns (address) {
    return address(_msgSender());
  }

  function createRelationshipType(string memory desc)  external onlyRole(GOVERNANCE_ROLE)  returns (bytes32 id) {
    id = _createRelationshipType(_msgSender(), desc);
  }

  function updateRelationshipType(bytes32 id, string memory desc) external onlyRole(GOVERNANCE_ROLE) {
    _updateRelationshipType(_msgSender(), id, desc);
  }

  function createAttestationType(string memory desc) external onlyRole(GOVERNANCE_ROLE)  returns (bytes32 id) {
    id = _createAttestationType(_msgSender(), desc);
  }

  function updateAttestationType(bytes32 id, string memory desc) external  onlyRole(GOVERNANCE_ROLE) {
    _updateAttestationType(_msgSender(), id, desc);
  }

  /***************************
   * Attestations
   ***************************/
  function createAttestation(address subject, bytes32 typeId, string memory payload) external onlyRole(ATTESTOR_ROLE) returns (bytes32 id) {
    id = _createAttestation(_msgSender(), subject, typeId, payload);
  }

  function updateAttestation(address subject, bytes32 id, string memory payload) external onlyRole(ATTESTOR_ROLE) {
    _updateAttestation(_msgSender(), subject, id, payload);
  }

  /***************************
   * Relationships
   ***************************/
  function createRelationship(bytes32 typeId, string memory desc, uint256 amount, address to) external returns(bytes32 id) {
    id = _createRelationship(_msgSender(), typeId, desc, amount, to);
  }

  function updateRelationship(bytes32 id, Lifecycle lifecycle, string memory metadata) external {
    require(
      canUpdateRelationship(_msgSender(), id), 
      "Factiiv.updateRelationship : permission denied"
    );

    // TODO: Logical rules
    /* 
    Strict order of events:
    1. Propose
    2. Accept
    3. Close
    4. Ratings (both kinds)

    Only "to" can "Accept"
    Only "from" can close
    Both can offer Ratings, only once

    Ratings:
    Require normalized input (e.g. "1" to "5") for ratings strings. Consider efficiency.
    */

    _updateRelationship(_msgSender(), id, lifecycle, metadata);
  }

  /***************************
   * delete relationship
   ***************************/  

  function deleteRelationship(bytes32 id) external {
    // require(
    //   canUpdateRelationship(_msgSender(), id),
    //   "Factiiv.deleteRelationship : not a participant, arbitrator or goverance");
    // require(
    //   relationshipStage(id) == Lifecycle.Proposed,
    //   "Factiiv.deleteRelationship : relationship is accepted"
    // );
    _deleteRelationship(_msgSender(), id);
  }

  function arbitrationDelete(bytes32 id) external  {
    _deleteRelationship(_msgSender(), id);
  }

  /***************************
   * Access
   ***************************/ 

  function relationshipStage(bytes32 id) public view returns(Lifecycle lifecycle) {
    Relationship storage r = relationship[id];
    uint256 historyCount = r.history.length;
    Stage storage s = r.history[historyCount-1];
    lifecycle = s.lifecycle;
  }

  function canUpdateRelationship(address updater, bytes32 id) public view returns(bool) {
    Relationship storage r = relationship[id];
    return(
      r.from == updater ||
      r.to == updater ||
      hasRole(ARBITRATOR_ROLE, _msgSender()) ||
      hasRole(GOVERNANCE_ROLE, _msgSender())
    );
  }  

  /***************************
   * UID Generator
   ***************************/    

  function genUid() private returns (bytes32) {
    nonce++;
    return keccak256(abi.encodePacked(address(this), nonce));
  }  

  /***************************
   * View 
   ***************************/  

  /*** master tables ***/  

  function relationshipTypeCount() external view returns(uint256 count) {
    count = relationshipTypeSet.count();
  }

  function relationshipTypeIdAtIndex(uint256 row) external view returns(bytes32 id) {
    id = relationshipTypeSet.keyAtIndex(row);
  }

  function attestationTypeCount() external view returns(uint256 count) {
    count = attestationTypeSet.count();
  }

  function attestationTypeAtIndex(uint256 row) external view returns(bytes32 id) {
    id = attestationTypeSet.keyAtIndex(row);
  }

    /*** users ***/ 

  function userMeta(address userAddr) external view returns(uint256 linksOut, uint256 linksIn, uint256 attestations) {
    User storage u = user[userAddr];
    return(
      u.senderJoinSet.count(),
      u.receiverJoinSet.count(),
      u.attestationSet.count()
    );
  }

  function userSendRelationshipAtIndex(address userAddr, uint256 row) external view returns(bytes32 id) {
    User storage u = user[userAddr];
    id = u.senderJoinSet.keyAtIndex(row);
  }

  function userReceiveRelationshipAtIndex(address userAddr, uint256 row) external view returns(bytes32 id) {
    User storage u = user[userAddr];
    id = u.receiverJoinSet.keyAtIndex(row);
  }

  function userAttestationAtIndex(address userAddr, uint256 row) external view returns(bytes32 id) {
    User storage u = user[userAddr];
    id = u.attestationSet.keyAtIndex(row);
  }

    /*** global ***/ 

  function relationshipCount() external view returns(uint256 count) {
    count = relationshipSet.count();
  }

  function attestationCount() external view returns(uint256 count) {
    count = attestationSet.count();
  }

  function relationshipAtIndex(uint256 row) external view returns(bytes32 id) {
    id = relationshipSet.keyAtIndex(row);
  }

  function attestationAtIndex(uint256 row) external view returns(bytes32 id) {
    id = attestationSet.keyAtIndex(row);
  }

}
