// Lightweight in-memory job queue that mimics the small subset of the Bull API
// used by this project (.add, .process, .on('failed')).
//
// WHY: Bull keeps a persistent Redis connection open and polls Redis continuously
// (blocking pops, stalled-job checks, delayed-job scans) even when the app is idle.
// On an always-on host that silently burns through hundreds of thousands of Upstash
// commands per month. Since submissions are processed in-process anyway, an in-memory
// queue removes the Redis dependency entirely while preserving concurrency limits.
//
// Trade-off: jobs live only in memory. If the process restarts with jobs still
// queued/processing, those jobs are lost (the submission row stays 'pending').
// For a single-instance deployment this is an acceptable trade vs. the quota leak.

export class InMemoryQueue {
  constructor(name) {
    this.name = name;
    this._queue = [];
    this._processor = null;
    this._concurrency = 1;
    this._active = 0;
    this._failedHandlers = [];
    this._completedHandlers = [];
    this._jobIdCounter = 0;
  }

  /**
   * Register the job processor. Signature mirrors Bull:
   *   queue.process(concurrency, async (job) => { ... })
   * or queue.process(async (job) => { ... })
   */
  process(concurrencyOrHandler, maybeHandler) {
    if (typeof concurrencyOrHandler === 'function') {
      this._processor = concurrencyOrHandler;
      this._concurrency = 1;
    } else {
      this._concurrency = Math.max(1, parseInt(concurrencyOrHandler, 10) || 1);
      this._processor = maybeHandler;
    }
    // Kick off any jobs that were added before the processor was registered.
    this._drain();
  }

  /**
   * Enqueue a job. Returns a minimal job-like object.
   * Mirrors `await queue.add(data)`.
   */
  async add(data) {
    const job = {
      id: ++this._jobIdCounter,
      data,
    };
    this._queue.push(job);
    // Defer draining so add() resolves quickly (like Bull returning after enqueue).
    setImmediate(() => this._drain());
    return job;
  }

  on(event, handler) {
    if (event === 'failed') this._failedHandlers.push(handler);
    else if (event === 'completed') this._completedHandlers.push(handler);
    return this;
  }

  _drain() {
    if (!this._processor) return;
    while (this._active < this._concurrency && this._queue.length > 0) {
      const job = this._queue.shift();
      this._active++;
      this._runJob(job);
    }
  }

  async _runJob(job) {
    try {
      const result = await this._processor(job);
      for (const handler of this._completedHandlers) {
        try {
          await handler(job, result);
        } catch (err) {
          console.error('Queue completed-handler error:', err);
        }
      }
    } catch (error) {
      for (const handler of this._failedHandlers) {
        try {
          await handler(job, error);
        } catch (err) {
          console.error('Queue failed-handler error:', err);
        }
      }
    } finally {
      this._active--;
      // Continue with any remaining queued jobs.
      this._drain();
    }
  }
}
