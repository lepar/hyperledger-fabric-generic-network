import { Request, Response } from "express";
import { Contract } from "fabric-network";
import { ContractManager } from "./TransactionManager";

export class OperationsManager {
  public async query(req: Request, res: Response) {
    if (req.body === undefined) {
      throw new Error("Invalid JSON");
    }

    const user = req.body.user;
    const key = req.body.key;

    try {
      const contractManager: ContractManager = new ContractManager();
      const contract: Contract = await contractManager.getContract(user, req, res);

      const result = await contract.evaluateTransaction("queryBlockchain", key);

      res.status(200).send(JSON.parse(result.toString()));
      }
     catch (error) {
      console.log(error.toString());
      res.status(500).send(error.toString());
    }
  }

  public async invoke(req: Request, res: Response) {
    if (req.body === undefined) {
      throw new Error("Invalid JSON, selector object is required");
    }

    const user = req.body.user.toString();
    const key = req.body.key.toString();
    const data = req.body;
    
    try {
      const contractManager: ContractManager = new ContractManager();
      const contract: Contract = await contractManager.getContract(user, req, res);

      await contract.submitTransaction("invokeTransaction", key, JSON.stringify(data));

      res.status(200).send('Succesfully invoked');
    } catch (error) {
      console.log(error.toString());
      res.status(500).send(error.toString());
    }
  }

}

export default OperationsManager;
