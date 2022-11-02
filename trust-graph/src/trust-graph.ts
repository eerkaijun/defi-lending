import { BigInt } from "@graphprotocol/graph-ts"
import {
  TrustGraph,
  Approval,
  ApprovalForAll,
  Transfer,
  newEdge
} from "../generated/TrustGraph/TrustGraph"
import { GraphEdge } from "../generated/schema"

export function handleApproval(event: Approval): void {}

export function handleApprovalForAll(event: ApprovalForAll): void {}

export function handleTransfer(event: Transfer): void {}

export function handlenewEdge(event: newEdge): void {
  // Use proper id to load an entity from store
  const id = event.transaction.hash.toHex();
  let edge = GraphEdge.load(id);

  // Create the entity if it doesn't already exist
  if (!edge) {
    edge = new GraphEdge(id);
  }

  // Set updated fields to entity
  edge.source = event.params.source;
  edge.destination = event.params.destination;

  // Save updated entity to store
  edge.save();
}
