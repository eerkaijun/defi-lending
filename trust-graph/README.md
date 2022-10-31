# trust-graph

We use the Graph Protocol to index on-chain data to provide social and trust context for users looking to participate in a DeFi platform.

### Getting Started

To build and deploy the subgraph, run the following. 

```
npm install -g @graphprotocol/graph-cli
graph init --studio trust-graph
graph auth --studio <AUTH KEY>
graph codegen && graph build
graph deploy --studio test-graph
```

Subgraph endpoints available for querying: 
* [https://api.studio.thegraph.com/query/37342/trust-graph/v0.0.1](https://api.studio.thegraph.com/query/37342/trust-graph/v0.0.1)