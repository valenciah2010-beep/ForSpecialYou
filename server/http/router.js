function compilePath(path) {
  const keys = [];
  const pattern = path
    .split('/')
    .map((part) => {
      if (!part.startsWith(':')) return part;
      keys.push(part.slice(1));
      return '([^/]+)';
    })
    .join('/');

  return {
    keys,
    regex: new RegExp(`^${pattern}$`)
  };
}

function compose(middleware) {
  return async (ctx, next) => {
    let index = -1;

    async function dispatch(position) {
      if (position <= index) {
        throw new Error('next() called multiple times');
      }

      index = position;
      const fn = middleware[position] || next;
      if (!fn) return undefined;
      return fn(ctx, () => dispatch(position + 1));
    }

    return dispatch(0);
  };
}

export class Router {
  constructor(prefix = '') {
    this.prefix = prefix;
    this.routes = [];
  }

  register(method, path, ...middleware) {
    const fullPath = `${this.prefix}${path}`;
    const { keys, regex } = compilePath(fullPath);
    this.routes.push({
      method: method.toUpperCase(),
      path: fullPath,
      keys,
      regex,
      middleware
    });
  }

  get(path, ...middleware) {
    this.register('GET', path, ...middleware);
  }

  post(path, ...middleware) {
    this.register('POST', path, ...middleware);
  }

  put(path, ...middleware) {
    this.register('PUT', path, ...middleware);
  }

  patch(path, ...middleware) {
    this.register('PATCH', path, ...middleware);
  }

  delete(path, ...middleware) {
    this.register('DELETE', path, ...middleware);
  }

  use(router) {
    this.routes.push(...router.routes);
  }

  middleware() {
    return async (ctx, next) => {
      const route = this.routes.find((item) => (
        item.method === ctx.method && item.regex.test(ctx.path)
      ));

      if (!route) {
        return next();
      }

      const match = ctx.path.match(route.regex);
      ctx.params = route.keys.reduce((params, key, index) => {
        params[key] = decodeURIComponent(match[index + 1]);
        return params;
      }, {});

      return compose(route.middleware)(ctx, next);
    };
  }
}
