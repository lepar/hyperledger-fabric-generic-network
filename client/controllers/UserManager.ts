import { Request, Response } from 'express';
import FabricCAServices from 'fabric-ca-client';
import { Identity, Wallets, X509Identity } from 'fabric-network';
import * as fs from 'fs';
import * as path from 'path';

const ccpJSON = fs.readFileSync('connection-org.json', 'utf8');
const connectionProfile = JSON.parse(ccpJSON);
const walletPath = path.join(process.cwd(), 'wallet');
const orgMsp = process.env.ORG_MSP || 'OrgMSP';
const ORG_DOMAIN = process.env.DOMAIN_OF_ORGANIZATION || 'OrgMSP';

export class UserManager {

  public async enrollAdmin(req: Request, res: Response): Promise<void> {

    try {
      const wallet = await Wallets.newFileSystemWallet(walletPath);

      const identity = await wallet.get('admin');
      if (identity) {
        return Promise.reject(new Error('An identity for the admin user "admin" already exists in the wallet'));
      }
      const caInfo = connectionProfile.certificateAuthorities['ca.' + ORG_DOMAIN];
      const caTLSCACerts = caInfo.tlsCACerts.pem;

      const ca = new FabricCAServices(
        caInfo.url,
        { trustedRoots: caTLSCACerts, verify: false },
        caInfo.caName
      );
      const enrollment = await ca.enroll({
        enrollmentID: 'admin',
        enrollmentSecret: 'adminpw'
      });

      const x509Identity: X509Identity = {
        credentials: {
          certificate: enrollment.certificate,
          privateKey: enrollment.key.toBytes(),
        },
        mspId: orgMsp,
        type: 'X.509',
      };

      await wallet.put('admin', x509Identity);
      res.status(200).send('Successfully enrolled admin and imported it into the wallet');
    } catch (error) {
      console.error(`Failed to enroll admin: ${error}`);
      res.status(500).send(`Failed to enroll admin: ${error}`);
    }
  }

  public async registerUser(req: Request, res: Response): Promise<void> {
    try {

      const wallet = await Wallets.newFileSystemWallet(walletPath);

      let { user } = req.body;

      // Check to see if we've already enrolled the user.
      const userExists = await wallet.get(`${user}`);

      if (userExists != undefined) {
        res.status(409).send(`An identity for the user ${user} already exists in the wallet`);
      }

      // Check to see if we've already enrolled the admin user.
      const adminExists = await wallet.get('admin');
      if (!adminExists) {
        res.status(404).send(`An identity for the ADMIN does not exist in the wallet`);
      }

      const caInfo = connectionProfile.certificateAuthorities['ca.' + ORG_DOMAIN];
      const caTLSCACerts = caInfo.tlsCACerts.pem;

      const ca = new FabricCAServices(
        caInfo.url,
        { trustedRoots: caTLSCACerts, verify: false },
        caInfo.caName
      );
      const adminIdentity = await wallet.get('admin');
      if (!adminIdentity) {
        throw new Error('An identity for the admin user "admin" does not exist in the wallet');
      }

      const provider = wallet.getProviderRegistry().getProvider(adminIdentity.type);
      const adminUser = await provider.getUserContext(adminIdentity, 'admin');

      const secret = await ca.register(
        { affiliation: 'org1.department1', enrollmentID: user, role: 'client' },
        adminUser
      );

      const enrollment = await ca.enroll({
        enrollmentID: `${user}`,
        enrollmentSecret: secret
      });
      const x509Identity: X509Identity = {
        credentials: {
          certificate: enrollment.certificate,
          privateKey: enrollment.key.toBytes(),
        },
        mspId: orgMsp,
        type: 'X.509',
      };
      await wallet.put(user, x509Identity);
      res.status(500).send(`User ${user} registered successfully`);

    } catch (error) {
      console.log(`UserManager error `, error);
      res.status(500).send(error);
    }
  }

  public async getWallet(user: string, req: Request, res: Response): Promise<Identity> {
    const wallet = await Wallets.newFileSystemWallet(walletPath);

    const userWallet = await wallet.get(user);

    if (!userWallet) {
      res.status(403).send('User not allowed');
      throw new Error('User not allowed');
    }
    return userWallet;
  }

}

export default UserManager;
