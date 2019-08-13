import { ParameterizedContext } from 'koa';
import { txMode } from 'pg-promise';

const readOnlyMode = new txMode.TransactionMode({
  readOnly: true,
});

const readWriteMode = new txMode.TransactionMode({
  /* Defaults */
});

export default async function dbTransactionMiddleware(
  ctx: ParameterizedContext,
  next: () => Promise<void>
) {
  const mode = ['POST', 'PUT', 'PATCH', 'DELETE'].includes(ctx.request.method)
    ? readWriteMode
    : readOnlyMode;

  await ctx.db.tx({ mode }, async (tx: any) => {
    // Writing to ctx directly is easier to give typings for than using ctx.state
    ctx.tx = tx;
    await next();
  });
}
