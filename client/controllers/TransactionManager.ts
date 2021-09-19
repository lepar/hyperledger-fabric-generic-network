import { Request, Response } from 'express';
import { Contract, Gateway, } from 'fabric-network';
import yaml from 'js-yaml';
import fs from 'fs';
import { UserManager } from './UserManager';

export class ContractManager {

  userMngr: UserManager = new UserManager();
  gateway: Gateway = new Gateway();

  public async getContract(user: string, req: Request, res: Response): Promise<Contract> {

    const ORG_LOWERCASE = process.env.ORGANIZATION_NAME_LOWERCASE || 'test';
    let userIdentity = await this.userMngr.getWallet(user, req, res);
    const connectionProfileJson = yaml.load(fs.readFileSync('connections.yml', 'utf8'));

    await this.gateway.connect(connectionProfileJson, {
      identity: userIdentity,
      discovery: { enabled: false, asLocalhost: true },
    });

    const network = await this.gateway.getNetwork(ORG_LOWERCASE + 'channel');
    const contract = network.getContract('chaincode');

    return contract;
  }

  public async disconnect(): Promise<any> {
    this.gateway.disconnect();
  }
}
