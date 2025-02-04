type KeycloakConfig = {
  realm: string;
  authServerUrl: string;
  clientId: string;
  secret: string;
  cookieKey: string;
};

const keycloakConfig: KeycloakConfig = {
  realm: process.env.KEYCLOAK_REALM || 'myrealm',
  authServerUrl: process.env.KEYCLOAK_AUTH_SERVER_URL || 'http://localhost:8080/auth',
  clientId: process.env.KEYCLOAK_CLIENT_ID || 'myclient',
  secret: process.env.KEYCLOAK_SECRET || '',
  cookieKey: process.env.COOKIE_KEY || 'my-secret-key'
};

export { KeycloakConfig, keycloakConfig }; 