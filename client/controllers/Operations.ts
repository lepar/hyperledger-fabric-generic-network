import { Request, Response } from "express";
import { Contract } from "fabric-network";
import { ContractManager } from "./TransactionManager";

export class OperationsManager {
  public async query(req: Request, res: Response) {
    if (req.body === undefined) {
      throw new Error("Invalid JSON");
    }

    const contractManager: ContractManager = new ContractManager();
    const { user, key } = req.body;

    try {
      const contract: Contract = await contractManager.getContract(user, req, res);
      const result = await contract.evaluateTransaction("queryBlockchain", key);
      res.status(200).send(JSON.parse(result.toString()));
    }
    catch (error) {
      console.log(error);
      res.status(500).send(error);
    }

    contractManager.disconnect();
  }

  public async invoke(req: Request, res: Response) {
    if (req.body === undefined) {
      throw new Error("Invalid JSON, selector object is required");
    }

    const { user, key } = req.body;
    const data = req.body;

    try {
      const contractManager: ContractManager = new ContractManager();
      const contract: Contract = await contractManager.getContract(user, req, res);

      const result = await contract.submitTransaction("invokeTransaction", key, JSON.stringify(data));

      res.status(200).send(result);
    } catch (error) {
      console.log(error);
      res.status(500).send(error);
    }
  }
}

export default OperationsManager;
