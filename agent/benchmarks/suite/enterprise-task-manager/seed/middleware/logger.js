function requestLogger(req, res, next) {
  const start = Date.now();
  const method = req.method;
  const path = req.originalUrl;

  res.on('finish', function() {
    const duration = Date.now() - start;
    const status = res.statusCode;
    console.log(`${method} ${path} ${status} ${duration}ms`);
  });

  next();
}

module.exports = requestLogger;
