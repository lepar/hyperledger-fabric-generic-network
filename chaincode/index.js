/*
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

const Chaincode = require('./lib/chaincode');

module.exports.Chaincode = Chaincode;
module.exports.contracts = [ Chaincode ];
