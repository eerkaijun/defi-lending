const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Trust Graph", () => {

    let trustGraph;
    let referrer, user;

    beforeEach(async () => {
        [referrer, user] = await ethers.getSigners();
        const TrustGraph = await ethers.getContractFactory("TrustGraph");
        trustGraph = await TrustGraph.deploy();
    })

    it("User should be able to join the trust graph with a referral link", async () => {
        // encode message
        const message = ethers.utils.solidityKeccak256(
            ["address"],
            [user.address]
        )
        // signing
        const signature = await referrer.signMessage(
            ethers.utils.arrayify(message)
        );

        expect(await trustGraph.graphNodes(user.address)).equal(false);
        await trustGraph.connect(user).joinGraph(signature);
        expect(await trustGraph.graphNodes(user.address)).equal(true);

        let filter = trustGraph.filters.newEdge(); // we want to keep track of new edges formed
        const result = await trustGraph.queryFilter(filter);
        
        let graph = {};
        let source, destination;
        // construct the graph in the form of a dictionary
        for (let i = 0; i < result.length; i++) {
            source = result[i]["args"].source;
            destination = result[i]["args"].destination;
            if (source in graph) {
                graph[source].add(destination);
            } else {
                graph[source] = new Set([destination]);
            }
        }
    });
});