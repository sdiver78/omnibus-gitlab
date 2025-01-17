# Redis settings

## Using a non-packaged Redis instance

If you want to use your own Redis instance instead of the bundled Redis, you
can use the `gitlab.rb` settings below. Run `gitlab-ctl reconfigure` for the
settings to take effect.

```ruby
redis['enable'] = false

# Redis via TCP
gitlab_rails['redis_host'] = 'redis.example.com'
gitlab_rails['redis_port'] = 6380

# OR Redis via Unix domain sockets
gitlab_rails['redis_socket'] = '/tmp/redis.sock' # defaults to /var/opt/gitlab/redis/redis.socket
```

## Using Google Cloud Memorystore

Google Cloud Memorystore [does not support the Redis `CLIENT`
command.](https://cloud.google.com/memorystore/docs/reference/redis-configs#blocked)
By default Sidekiq will attempt to set the `CLIENT` for debugging
purposes. This can be disabled via this config setting:

```ruby
gitlab_rails['redis_enable_client'] = false
```

## Making a bundled Redis instance reachable via TCP

Use the following settings if you want to make one of the Redis instances
managed by omnibus-gitlab reachable via TCP.

```ruby
redis['port'] = 6379
redis['bind'] = '127.0.0.1'
```

## Setting up a Redis-only server

If you'd like to setup a separate Redis server (e.g. in the case of scaling
issues) for use with GitLab you can do so using GitLab Omnibus.

> **Note:** Redis does not require authentication by default. See
  [Redis Security](http://redis.io/topics/security) documentation for more
  information. We recommend using a combination of a Redis password and tight
  firewall rules to secure your Redis service.

1. Download/install GitLab Omnibus using **steps 1 and 2** from
   [GitLab downloads](https://about.gitlab.com/downloads). Do not complete other
   steps on the download page.
1. Create/edit `/etc/gitlab/gitlab.rb` and use the following configuration.
   Be sure to change the `external_url` to match your eventual GitLab front-end
   URL:

    ```ruby
    external_url 'https://gitlab.example.com'

    # Disable all services except Redis
    redis_master_role['enable'] = true

    # Redis configuration
    redis['port'] = 6379
    redis['bind'] = '0.0.0.0'

    # If you wish to use Redis authentication (recommended)
    redis['password'] = 'Redis Password'
    gitlab_rails['redis_password'] = 'Redis Password'

    # Disable automatic database migrations
    #   Only the primary GitLab application server should handle migrations
    gitlab_rails['auto_migrate'] = false
    ```

    > **Note:** The `redis_master_role['enable']` option is only available as of
    GitLab 8.14, see [`gitlab_rails.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/libraries/gitlab_rails.rb)
    to understand which services are automatically disabled via that option.

1. Run `sudo gitlab-ctl reconfigure` to install and configure Redis.

## Increasing the number of Redis connections beyond the default

By default Redis will only accept 10,000 client connections. If you need
more that 10,000 connections set the 'maxclients' attribute to suite your needs.
Be advised that adjusting the maxclients attribute means that you will also need
to take into account your systems settings for fs.file-max (i.e. "sysctl -w fs.file-max=20000")

```ruby
redis['maxclients'] = 20000
```

## Tuning the TCP stack for Redis

The following settings are to enable a more performant Redis server instance. 'tcp_timeout' is
a value set in seconds that the Redis server waits before terminating an IDLE TCP connection.
The 'tcp_keepalive' is a tunable setting in seconds to TCP ACKs to clients in absence of
communication.

```ruby
redis['tcp_timeout'] = "60"
redis['tcp_keepalive'] = "300"
```

## Running with multiple Redis instances

GitLab includes support for running with separate redis instances for different persistence classes, currently: cache, queues, and shared_state.

1. Create a dedicated instance for each persistence class as per the instructions in [Setting up a Redis-only server](#setting-up-a-redis-only-server)
1. Set the appropriate variable in `/etc/gitlab/gitlab.rb` for each instance you are using:

    ```ruby
    gitlab_rails['redis_cache_instance'] = REDIS_CACHE_URL
    gitlab_rails['redis_queues_instance'] = REDIS_QUEUES_URL
    gitlab_rails['redis_shared_state_instance'] = REDIS_SHARED_STATE_URL
    ```

    **Note**: Redis URLs should be in the format: "redis://:PASSWORD@REDIS_HOST:PORT/2"
    Where
    * PASSWORD is the plaintext password for the Redis instance
    * REDIS_HOST is the hostname or IP address of the host
    * REDIS_PORT is the port Redis is listening on, the default is 6379

1. Run `gitlab-ctl reconfigure`

## Redis Sentinel

For details on configuring Redis Sentinel, see
<https://docs.gitlab.com/ce/administration/high_availability/redis.html>.

## Setting the Redis Cache instance as an LRU

Using multiple Redis instances allows you to configure Redis as a [Least
Recently Used cache](https://redis.io/topics/lru-cache). Note you should only
do this for the Redis cache class; the Redis queues and shared state cache
should never be configured as an LRU, since they contain data (e.g. Sidekiq
jobs) that is expected to be persistent.

To cap memory usage at 32GB, you can use:

```ruby
redis['maxmemory'] = "32gb"
redis['maxmemory_policy'] = "allkeys-lru"
redis['maxmemory_samples'] = 5
```

## Using a Redis HA setup

See <https://docs.gitlab.com/ce/administration/high_availability/redis.html>.

## Using Secure Sockets Layer (SSL)

Redis v3.2.x does NOT support SSL out of the box. However, you can encrypt a
Redis connection using [stunnel](https://redislabs.com/blog/stunnel-secure-redis-ssl/).
AWS ElasticCache also supports Redis over SSL.

### Limitations

- GitLab does NOT ship with stunnel or other tools to provide encryption
  for the Redis server. However, GitLab does provide client support via
  the `rediss://` (as opposed to `redis://`) URL scheme.

- Redis Sentinel does NOT support SSL yet. If you use Redis Sentinel, do
  not activate client support for SSL. [This pull
  request](https://github.com/antirez/redis/pull/4855) may bring native
  support to Redis 6.0.

### Activating SSL (client settings)

To activate GitLab client support for SSL, do the following:

1. Add the following line to `/etc/gitlab/gitlab.rb`:

    ```ruby
    gitlab_rails['redis_ssl'] = true
    ```

1. Run `sudo gitlab-ctl reconfigure` for the changes to take effect.

## SSL certificates

If you are using custom SSL certificates for Redis, be sure to add them
to the [trusted certificates](../settings/ssl.md#install-custom-public-certificates).

## Common Troubleshooting

### x509: certificate signed by unknown authority

This error message suggests that the SSL certificates have not been
properly added to the list of trusted certificates for the server. To
check whether this is an issue:

1. Check Workhorse logs in `/var/log/gitlab/gitlab-workhorse/current`.

1. If you see messages that look like:

    ```
    2018-11-14_05:52:16.71123 time="2018-11-14T05:52:16Z" level=info msg="redis: dialing" address="redis-server:6379" scheme=rediss
    2018-11-14_05:52:16.74397 time="2018-11-14T05:52:16Z" level=error msg="unknown error" error="keywatcher: x509: certificate signed by unknown authority"
    ```

    The first line should show `rediss` as the scheme with the address
    of the Redis server. The second line indicates the certificate is
    not properly trusted on this server. See the [previous section](#ssl-certificates).

1. Verify that the SSL certificate is working via [these troubleshooting
   steps](ssl.md#custom-certificates-missing-or-skipped).

### NOAUTH Authentication required

A Redis server may require a password sent via an `AUTH` message before
commands are accepted. A `NOAUTH Authentication required` error message
suggests the client is not sending a password. GitLab logs may help
troubleshoot this error:

1. Check Workhorse logs in `/var/log/gitlab/gitlab-workhorse/current`.

1. If you see messages that look like:

    ```
    2018-11-14_06:18:43.81636 time="2018-11-14T06:18:43Z" level=info msg="redis: dialing" address="redis-server:6379" scheme=rediss
    2018-11-14_06:18:43.86929 time="2018-11-14T06:18:43Z" level=error msg="unknown error" error="keywatcher: pubsub receive: NOAUTH Authentication required."
    ```

1. Check that the Redis client password specified in `/etc/gitlab/gitlab.rb` is correct:

    ```ruby
    gitlab_rails['redis_password'] = 'your-password-here'
    ```

1. If you are using the Omnibus-provided Redis server, check that the server has the same password:

    ```ruby
    redis['password'] = 'your-password-here'
    ```

### Redis connection reset (ECONNRESET)

If you see `Redis::ConnectionError: Connection lost (ECONNRESET)` in the
GitLab Rails logs (`/var/log/gitlab-rails/production.log`), this might
indicate that the server is expecting SSL but the client is not
configured to use it.

1. Check that the server is actually listening to the port via SSL.
   For example:

    ```sh
    /opt/gitlab/embedded/bin/openssl s_client -connect redis-server:6379
    ```

1. Check `/var/opt/gitlab/gitlab-rails/etc/resque.yml`. You
   should see something like:

    ```yaml
    production:
      url: rediss://:mypassword@redis-server:6379/
    ```

1. If `redis://` is present instead of `rediss://`, the `redis_ssl`
   parameter may not have been configured properly, or the reconfigure
   step may not have been run.
