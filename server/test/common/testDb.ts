import pgpInit, { IDatabase } from 'pg-promise';
import testConfig from './testConfig';

const pgp = pgpInit({
  // Initialization options
});

const cn = {
  host: testConfig.DATABASE_HOST,
  port: testConfig.DATABASE_PORT,
  database: testConfig.DATABASE_NAME,
  user: testConfig.DATABASE_USER,
  password: testConfig.DATABASE_PASSWORD,
  poolSize: testConfig.DATABASE_POOL_MAX,
  ssl:
    testConfig.DATABASE_SSL_ENABLED &&
    testConfig.DATABASE_SSL_CLIENT_CERT_ENABLED
      ? {
          ca: testConfig.DATABASE_SSL_CA,
          cert: testConfig.DATABASE_SSL_CERT,
          key: testConfig.DATABASE_SSL_KEY,
        }
      : testConfig.DATABASE_SSL_ENABLED,
};

const testDb: IDatabase<{}> = pgp(cn);

export default testDb;
