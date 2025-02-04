import { failure, Result, success } from '@pinaronu/fp';
import { config } from 'dotenv';

config();



import fastify, { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import { z } from 'zod';
import { zodToJsonSchema } from 'zod-to-json-schema';
import { KeycloakClient } from './auth/keycloak-client';
import { createAuthMiddleware } from './middleware/auth';
import { keycloakConfig } from './config/keycloak';

// Schema Definitions
const UserSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1),
  email: z.string().email(),
});

type User = z.infer<typeof UserSchema>;

const ResultSchema = <T extends z.ZodType>(valueSchema: T) =>
  z.discriminatedUnion('kind', [
    z.object({
      kind: z.literal('success'),
      value: valueSchema,
    }),
    z.object({
      kind: z.literal('error'),
      error: z.object({
        code: z.string(),
        message: z.string(),
      }),
    }),
  ]);

function createHandler<TParams, TBody, TResponse>(
  config: {
    params?: z.ZodType<TParams>,
    body?: z.ZodType<TBody>,
    response: z.ZodType<TResponse>,
  },
  handler: (
    params: TParams,
    body: TBody,
  ) => Promise<Result<TResponse>>
) {
  return {
    schema: {
      params: config.params && zodToJsonSchema(config.params),
      body: config.body && zodToJsonSchema(config.body),
      response: {
        200: zodToJsonSchema(ResultSchema(config.response)),
      },
    },
    handler: async (
      request: FastifyRequest<{
        Params: TParams;
        Body: TBody;
      }>,
      reply: FastifyReply,
    ) => {
      try {
        const result = await handler(
          request.params as TParams,
          request.body as TBody
        );
        return reply.send(result);
      } catch (error) {
        return reply.send(failure(error));
      }
    },
  };
}

async function start() {
  const app: FastifyInstance = fastify({
    logger: {
      level: 'info',
      transport: {
        target: 'pino-pretty',
      },
    },
    ajv: {
      customOptions: {
        strict: 'log',
        keywords: ['kind'],
      },
    },
  });
  
  // Register CORS
  await app.register(import('@fastify/cors'), {
    // You can customize these options based on your needs
    origin: true, // Reflects the request origin. Set to specific origins in production
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true
  });
  
  // Register Swagger
  await app.register(import('@fastify/swagger'), {
    openapi: {
      info: {
        title: 'User API',
        version: '1.0.0',
      },
    },
  });
  
  await app.register(import('@fastify/swagger-ui'), {
    routePrefix: '/docs',
  });
  
  // Initialize Keycloak
  const keycloakClient = new KeycloakClient(keycloakConfig);
  
  // Register auth middleware for protected routes
  app.addHook('preHandler', createAuthMiddleware(keycloakClient));
  
  // Create a type-safe wrapper for our handlers
  
  // API Endpoints
  app.post(
    '/users/getUserProfile',
    createHandler(
      {
        body: z.object({
          userId: z.string().uuid(),
        }),
        response: UserSchema,
      },
      async (_, body) => {
        try {
          // Your actual database query would go here
          const user: User = {
            id: body.userId,
            name: 'John Doe',
            email: 'john@example.com'
          };
          
          return success(user);
        } catch (error) {
          return failure({
            code: 'USER_NOT_FOUND',
            message: 'User not found'
          });
        }
      }
    )
  );

  app.post(
    '/users/updateUser',
    createHandler(
      {
        body: z.object({
          userId: z.string().uuid(),
          name: z.string().min(1).optional(),
          email: z.string().email().optional(),
        }),
        response: UserSchema,
      },
      async (_, body) => {
        try {
          // Your actual database update would go here
          const user: User = {
            id: body.userId,
            name: body.name ?? 'John Doe',
            email: body.email ?? 'john@example.com',
          };
          
          return success(user);
        } catch (error) {
          return failure({
            code: 'UPDATE_FAILED',
            message: 'Failed to update user',
          });
        }
      }
    )
  );
  
  // Error Handler
  app.setErrorHandler((error, _, reply) => {
    const result = failure({
      code: 'INTERNAL_ERROR',
      message: error.message,
    });
    
    reply.status(500).send(result);
  });
  
  await app.listen({ port: 3000 });
}

start();