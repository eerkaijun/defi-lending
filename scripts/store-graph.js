const hre = require("hardhat");

async function main(contractAddress) {
    const trustGraph = await hre.ethers.getContractAt("TrustGraph", contractAddress);
  
    let filter = trustGraph.filters.newEdge(); // we want to keep track of new edges formed
    const result = await trustGraph.queryFilter(filter);
        
    let graph = {};
    let source, destination;
    // construct the graph in the form of a dictionary
    for (let i = 0; i < result.length; i++) {
        source = result[i]["args"].source;
        destination = result[i]["args"].destination;
        if (source in graph) {
            graph[source][destination] = true;
        } else {
            graph[source] = {};
            graph[source][destination] = true;
        }
    }
    console.log("Graph: ", graph);

    // store the graph in IPFS / Filecoin
    const { create } = await import('ipfs-core');
    const node = await create({
        // ... config here
    });
    // store these public inputs into ipfs
    let { cid } = await node.add(JSON.stringify(graph));
    console.log("Stored in IPFS: ", cid.toString());
    node.stop();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
// TODO: change the trust graph smart contract address before running the script
main("0x569e71c8d688e61BbaDaA5c24372EBcD404d28FF").catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
