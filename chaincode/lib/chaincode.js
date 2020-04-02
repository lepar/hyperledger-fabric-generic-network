/*
SPDX-License-Identifier: Apache-2.0
*/

'use strict';

const { Contract } = require('fabric-contract-api');

class Chaincode extends Contract {

    async initLedger(ctx) {
        console.info('Initialized Ledger');
    }

    async queryBlockchain(ctx, key) {
        const apostaAsBytes = await ctx.stub.getState(key);
        if (!apostaAsBytes || apostaAsBytes.length === 0) {
            throw new Error(`${key} does not exist`);

        }
        console.info(apostaAsBytes.toString());
        return apostaAsBytes.toString();
    }

    async invokeTransaction(ctx, id, jsonPayload) {

        await ctx.stub.putState(id, JSON.stringify(jsonPayload));
        console.info('Transaction commited to the ledger');
    }
}

module.exports = Chaincode;
