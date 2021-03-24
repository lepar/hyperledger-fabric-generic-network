import { Request, Response } from 'express';
import FabricCAServices from 'fabric-ca-client';
import { FileSystemWallet, X509WalletMixin, Gateway } from 'fabric-network';
import * as fs from 'fs';
import { join, resolve } from 'path';

const ccpPath = resolve('connection-org.json');
const ccpJSON = fs.readFileSync(ccpPath, 'utf8');
const ccp = JSON.parse(ccpJSON);

export class UserManager {
  public async enrollAdmin(req: Request, res: Response): Promise<void> {
    try {
      // Create a new CA client for interacting with the CA.
      const caInfo = ccp.certificateAuthorities['ca.example.com'];
      const caTLSCACerts = caInfo.tlsCACerts.pem;
      const ca = new FabricCAServices(
        caInfo.url,
        { trustedRoots: caTLSCACerts, verify: false },
        caInfo.caName
      );

      // Create a new file system based wallet for managing identities.
      const walletPath = join(process.cwd(), 'wallet');
      const wallet = new FileSystemWallet(walletPath);

      // Check to see if we've already enrolled the admin user.
      const adminExists = await wallet.exists('admin');
      if (adminExists) {
        console.log(
          'An identity for the admin already exists in the wallet'
        );
        res
          .status(409)
          .send(
            'An identity for the admin already exists in the wallet'
          );
        return;
      }

      // Enroll the admin user, and import the new identity into the wallet.
      const enrollment = await ca.enroll({
        enrollmentID: 'admin',
        enrollmentSecret: 'adminpw'
      });
      const identity = X509WalletMixin.createIdentity(
        'OrgMSP',
        enrollment.certificate,
        enrollment.key.toBytes()
      );
      await wallet.import('admin', identity);
      console.log(
        'Successfully enrolled admin and imported it into the wallet'
      );
      res
        .status(200)
        .send(
          'Successfully enrolled admin and imported it into the wallet'
        );
    } catch (error) {
      console.error(`Failed to enroll admin: ${error}`);
      res.status(500).send(`Failed to enroll admin: ${error}`);
    }
  }

  public async registerUser(req: Request, res: Response): Promise<void> {
    try {
      // Create a new file system based wallet for managing identities.
      const walletPath = join(process.cwd(), 'wallet');
      const wallet = new FileSystemWallet(walletPath);

      const user = req.body.user;

      // Check to see if we've already enrolled the user.
      const userExists = await wallet.exists(`${user}`);
      if (userExists) {
        res
          .status(409)
          .send(
            `An identity for the user ${user} already exists in the wallet`
          );
        return;
      }

      // Check to see if we've already enrolled the admin user.
      const adminExists = await wallet.exists('admin');
      if (!adminExists) {
        res
          .status(404)
          .send(
            `An identity for the ADMIN does not exist in the wallet`
          );
        return;
      }

      // Create a new gateway for connecting to our peer node.
      const gateway = new Gateway();
      await gateway.connect(ccpPath, {
        discovery: { enabled: true, asLocalhost: true },
        identity: 'admin',
        wallet
      });

      // Get the CA client object from the gateway for interacting with the CA.
      const ca = gateway.getClient().getCertificateAuthority();
      const adminIdentity = gateway.getCurrentIdentity();

      // Register the user, enroll the user, and import the new identity into the wallet.
      const secret = await ca.register(
        {
          affiliation: '',
          enrollmentID: `${user}`,
          role: 'client'
        },
        adminIdentity
      );
      const enrollment = await ca.enroll({
        enrollmentID: `${user}`,
        enrollmentSecret: secret
      });

      const userIdentity = X509WalletMixin.createIdentity('OrgMSP', enrollment.certificate, enrollment.key.toBytes());
      await wallet.import(`${user}`, userIdentity);

      res
      .status(200)
      .send(
        'Successfully registered user'
      );

    } catch (error) {
      res.status(500).send(`User with the user ${error} already exists`);
      
    }
  }

  public async getWallet(
    user: string,
    req: Request,
    res: Response
  ): Promise<FileSystemWallet> {
    const walletPath: string = join(process.cwd(), 'wallet');
    const wallet: FileSystemWallet = new FileSystemWallet(walletPath);
    const userWallet: boolean = await wallet.exists(user.toString());
    // In case of a admin transacion which does not have
    // its identity stored on the wallet.
    if (!userWallet) {
      res.status(403).send('User not allowed');
      throw new Error('User not allowed');
    }
    return wallet;
  }

  public async getAdminWallet(
    user: string,
    req: Request,
    res: Response
  ): Promise<FileSystemWallet> {
    const walletPath: string = join(process.cwd(), 'wallet');
    const wallet: FileSystemWallet = new FileSystemWallet(walletPath);

    try {
      const userWallet: boolean = await wallet.exists(user.toString());

      if (!userWallet) {
        const user: UserManager = new UserManager();
        await user.enrollAdmin(req, res);
      }
      console.log('Admin wallet ', wallet);
    } catch (error) {
      console.error(error);
      res.json();
    }

    return wallet;
  }
}

export default UserManager;
