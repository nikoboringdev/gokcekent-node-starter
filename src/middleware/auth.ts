
import { FastifyRequest, FastifyReply } from 'fastify';
import { KeycloakClient } from '../auth/keycloak-client';

export const createAuthMiddleware = (keycloakClient: KeycloakClient) => {
  return async (request: FastifyRequest, reply: FastifyReply) => {

    const authHeader = request.headers.authorization;
    if (!authHeader) {
      return reply.status(401).send({
        kind: 'error',
        error: {
          code: 'UNAUTHORIZED',
          message: 'No authorization header'
        }
      });
    }

    const rawToken = authHeader.split(' ')[1];
    const token = await keycloakClient.parseToken(rawToken);

    switch (token.kind) { 
      case 'success':
        break;
      case 'failure':
        return reply.status(401).send({
          kind: 'error',
        error: {
          code: 'UNAUTHORIZED',
          message: 'No authorization header'
        }
      });
    }
  };
};
