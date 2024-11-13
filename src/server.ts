import Fastify from 'fastify';
import { config } from 'dotenv';

config();

const server = Fastify({
  logger: {
    level: 'info',
    transport: {
      target: 'pino-pretty',
    },
  },
});

server.get('/', async () => {
  return { hello: 'world' };
});

const start = async () => {
  try {
    const port = process.env.PORT ? parseInt(process.env.PORT, 10) : 3000;
    await server.listen({ port });
    console.log(`Server listening on ${port}`);

  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
};

start();
