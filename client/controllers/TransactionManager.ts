import { Request, Response } from 'express';
import {
  Contract,
  FileSystemWallet,
  Gateway,
  GatewayOptions,
  Network
} from 'fabric-network';
import * as fs from 'fs';
import { safeLoad } from 'js-yaml';
import { UserManager } from './UserManager';

const connectionProfile = safeLoad(fs.readFileSync('connections.yml', 'utf8'));
const userManager: UserManager = new UserManager();

export class ContractManager {
  public async getContract(
    user: string,
    req: Request,
    res: Response
  ): Promise<Contract> {
    const wallet: FileSystemWallet = await userManager.getWallet(
      user,
      req,
      res
    );
    const contract: Contract = await this.connectClient(wallet, user);
    return contract;
  }

  public async getAdminContract(
    user: string,
    req: Request,
    res: Response
  ): Promise<Contract> {
    const wallet: FileSystemWallet = await userManager.getAdminWallet(
      user,
      req,
      res
    );
    const contract: Contract = await this.connectClient(wallet, user);
    return contract;
  }

  public async getClient(
    user: string,
    req: Request,
    res: Response
  ): Promise<Contract> {
    const wallet: FileSystemWallet = await userManager.getWallet(
      user,
      req,
      res
    );
    const contract: Contract = await this.connectClient(wallet, user);
    return contract;
  }

  public async connectClient(
    wallet: FileSystemWallet,
    user: string
  ): Promise<Contract> {
    const connectionOptions: GatewayOptions = {
      discovery: { enabled: false, asLocalhost: true },
      identity: user.toString(),
      wallet
    };

    // Create a new gateway for connecting to our peer node.
    const gateway: Gateway = new Gateway();
    await gateway.connect(connectionProfile!, connectionOptions);
    // Get the network (channel) our contract is deployed to.
    const network: Network = await gateway.getNetwork('orgchannel');
    // Get the contract from the network.
    const contract: Contract = network.getContract('chaincode');
    return contract;
  }
}
