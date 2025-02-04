import KeycloakConnect, { Token } from 'keycloak-connect';
import { FastifyInstance } from 'fastify';
import { keycloakConfig, KeycloakConfig } from '../config/keycloak';
import { Result, success, failure } from '@pinaronu/fp';

export class KeycloakClient {
  private keycloak: KeycloakConnect.Keycloak;

  constructor(config: KeycloakConfig) {
    this.keycloak = new KeycloakConnect({}, {
      realm: config.realm,
      'auth-server-url': config.authServerUrl,
      'ssl-required': 'external',
      resource: config.clientId,
      'confidential-port': 0,
      'bearer-only': true
    });
  }

  async protect(token: Token): Promise<Result<boolean>> {
    try {
      
      const grant = await this.keycloak.grantManager.createGrant({ access_token: token });
      return success(true);
    } catch (error) {
      return failure({
        code: 'UNAUTHORIZED',
        message: 'Invalid token'
      });
    }
  }

  async verifyToken(token: Token): Promise<Result<Token>> {
    try {
      const maybeToken = await this.keycloak.grantManager.validateAccessToken<Token>(token);
      if (maybeToken === false) {
        return failure({
          code: 'UNAUTHORIZED',
          message: 'Invalid token'
        });
      }
      return success(maybeToken);
    } catch (error) {
      console.error('Token verification failed:', error);
      return failure({
        code: 'UNAUTHORIZED',
        message: 'Invalid token'
      });
    }
  }

  async parseToken(bearerToken: string): Promise<Result<Token>> {
    try {
      const token = await this.keycloak.grantManager.validateAccessToken(bearerToken);
      if (!token) {
        return failure({
          code: 'UNAUTHORIZED',
          message: 'Invalid token'
        });
      }
      return success(token as unknown as Token);
    } catch (error) {
      return failure({
        code: 'UNAUTHORIZED',
        message: 'Invalid token'
      });
    }
  } 
} 