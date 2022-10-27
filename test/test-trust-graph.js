const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Trust Graph", () => {

    let trustGraph;
    let referrer, user1, user2;

    beforeEach(async () => {
        [referrer, user1, user2] = await ethers.getSigners();
        const TrustGraph = await ethers.getContractFactory("TrustGraph");
        trustGraph = await TrustGraph.deploy();
    })

    it("user1 should be able to join the trust graph with a referral link", async () => {
        // encode message
        let message = ethers.utils.solidityKeccak256(
            ["address"],
            [user1.address]
        )
        // signing
        let signature = await referrer.signMessage(
            ethers.utils.arrayify(message)
        );

        expect(await trustGraph.graphNodes(user1.address)).equal(false);
        await trustGraph.connect(user1).joinGraph(signature);
        expect(await trustGraph.graphNodes(user1.address)).equal(true);

        // encode message
        message = ethers.utils.solidityKeccak256(
            ["address"],
            [user2.address]
        )
        // signing
        signature = await referrer.signMessage(
            ethers.utils.arrayify(message)
        );

        expect(await trustGraph.graphNodes(user2.address)).equal(false);
        await trustGraph.connect(user2).joinGraph(signature);
        expect(await trustGraph.graphNodes(user2.address)).equal(true);

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

        expect(graph[user1.address].has(referrer.address)).equal(true);
        expect(graph[user2.address].has(referrer.address)).equal(true);
    });
});