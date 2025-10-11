\## 1) 下载并安装podman



在https://github.com/containers/podman/releases下载\[\*\*podman-5.6.2-setup.exe](https://github.com/containers/podman/releases/download/v5.6.2/podman-5.6.2-setup.exe)（或最新版）\*\*



安装，一路next



\## 2) 启动并配置1ms镜像



```jsx

podman machine init

podman machine start

podman machine ssh

sudo cp /etc/containers/registries.conf /etc/containers/registries.conf.bak

sudo vi /etc/containers/registries.conf

```



替换 registries.conf 的内容为：



```

unqualified-search-registries = \["docker.io"]



\[\[registry]]

prefix = "docker.io"

location = "docker.1ms.run"

```



```powershell

exit

podman machine stop

podman machine start

```



\## 3) 准备Dockerfile



```

FROM postgis/postgis:14-3.5



RUN echo "deb https://mirrors.aliyun.com/debian/ bullseye main non-free contrib" > /etc/apt/sources.list \&\& \\

&nbsp;   echo "deb-src https://mirrors.aliyun.com/debian/ bullseye main non-free contrib" >> /etc/apt/sources.list \&\& \\

&nbsp;   echo "deb https://mirrors.aliyun.com/debian-security/ bullseye-security main" >> /etc/apt/sources.list \&\& \\

&nbsp;   echo "deb-src https://mirrors.aliyun.com/debian-security/ bullseye-security main" >> /etc/apt/sources.list \&\& \\

&nbsp;   echo "deb https://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib" >> /etc/apt/sources.list \&\& \\

&nbsp;   echo "deb-src https://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib" >> /etc/apt/sources.list \&\& \\

&nbsp;     apt-get update \\

&nbsp;     \&\& apt-get install -y --no-install-recommends procps \\

&nbsp;     \&\& apt-get install -y --no-install-recommends postgresql-14-cron \\

&nbsp;     \&\& apt-get install -y --no-install-recommends postgis \\

&nbsp;     \&\& apt-get clean \\

&nbsp;     \&\& rm -rf /var/lib/apt/lists/\*



\# \[optional] set time zone

RUN ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \&\& echo "Asia/Shanghai" > /etc/timezone



EXPOSE 5432

VOLUME \["/var/lib/postgresql/"]



```



\## 4) 准备docker-compose.yml



```yaml

services:

&nbsp; postgis:

&nbsp;   build:  .

&nbsp;   ports:

&nbsp;     - "25432:5432"  # 此处表示宿主机端口25432，可按需修改

&nbsp;   environment:

&nbsp;     - "POSTGRES\_PASSWORD=ds123456"  # 设置数据库中postgres用户的密码

&nbsp;   volumes:

&nbsp;     # - ./postgres\_data:/var/lib/postgresql/data 

&nbsp;     # - ./postgres\_logs:/var/lib/postgresql/logs

&nbsp;     - ./postgresql.conf:/etc/postgresql/postgresql.conf

&nbsp;   command: \[ "-c", "config\_file=/etc/postgresql/postgresql.conf" ]  # 如按此文件默认在上面映射了postgresql.conf文件，则必须此行

```



\## 5) 准备postgresql.conf（见附录1）



\## 6) 准备podman-compose



如果没有uv，则先安装uv



```powershell

Set-ExecutionPolicy RemoteSigned -Scope Process

irm https://astral.sh/uv/install.ps1 | iex

```



```powershell

uv init .

uv venv

uv add podman-compose

.\\.venv\\Scripts\\activate

podman-compose up -d

```



\## 7) 进入容器并操作



```bash

psql -U postgres

```



\## 8) 使用本机的psql连接



```powershell

podman ps

podman exec -it ppg\_postgis\_1 bash

```



```bash

psql -h localhost -p 25432 -d postgres -U postgres

```



\## 附录1



```yaml

\# -----------------------------

\# PostgreSQL configuration file

\# -----------------------------

\#

\# This file consists of lines of the form:

\#

\#   name = value

\#

\# (The "=" is optional.)  Whitespace may be used.  Comments are introduced with

\# "#" anywhere on a line.  The complete list of parameter names and allowed

\# values can be found in the PostgreSQL documentation.

\#

\# The commented-out settings shown in this file represent the default values.

\# Re-commenting a setting is NOT sufficient to revert it to the default value;

\# you need to reload the server.

\#

\# This file is read on server startup and when the server receives a SIGHUP

\# signal.  If you edit the file on a running system, you have to SIGHUP the

\# server for the changes to take effect, run "pg\_ctl reload", or execute

\# "SELECT pg\_reload\_conf()".  Some parameters, which are marked below,

\# require a server shutdown and restart to take effect.

\#

\# Any parameter can also be given as a command-line option to the server, e.g.,

\# "postgres -c log\_connections=on".  Some parameters can be changed at run time

\# with the "SET" SQL command.

\#

\# Memory units:  B  = bytes            Time units:  us  = microseconds

\#                kB = kilobytes                     ms  = milliseconds

\#                MB = megabytes                     s   = seconds

\#                GB = gigabytes                     min = minutes

\#                TB = terabytes                     h   = hours

\#                                                   d   = days



\#------------------------------------------------------------------------------

\# FILE LOCATIONS

\#------------------------------------------------------------------------------



\# The default values of these variables are driven from the -D command-line

\# option or PGDATA environment variable, represented here as ConfigDir.



\#data\_directory = 'ConfigDir'		# use data in another directory

&nbsp;					# (change requires restart)

\#hba\_file = 'ConfigDir/pg\_hba.conf'	# host-based authentication file

&nbsp;					# (change requires restart)

\#ident\_file = 'ConfigDir/pg\_ident.conf'	# ident configuration file

&nbsp;					# (change requires restart)



\# If external\_pid\_file is not explicitly set, no extra PID file is written.

\#external\_pid\_file = ''			# write an extra PID file

&nbsp;					# (change requires restart)



\#------------------------------------------------------------------------------

\# CONNECTIONS AND AUTHENTICATION

\#------------------------------------------------------------------------------



\# - Connection Settings -



listen\_addresses = '\*'

&nbsp;					# comma-separated list of addresses;

&nbsp;					# defaults to 'localhost'; use '\*' for all

&nbsp;					# (change requires restart)

\#port = 5432				# (change requires restart)

max\_connections = 100			# (change requires restart)

\#superuser\_reserved\_connections = 3	# (change requires restart)

\#unix\_socket\_directories = '/var/run/postgresql'	# comma-separated list of directories

&nbsp;					# (change requires restart)

\#unix\_socket\_group = ''			# (change requires restart)

\#unix\_socket\_permissions = 0777		# begin with 0 to use octal notation

&nbsp;					# (change requires restart)

\#bonjour = off				# advertise server via Bonjour

&nbsp;					# (change requires restart)

\#bonjour\_name = ''			# defaults to the computer name

&nbsp;					# (change requires restart)



\# - TCP settings -

\# see "man tcp" for details



\#tcp\_keepalives\_idle = 0		# TCP\_KEEPIDLE, in seconds;

&nbsp;					# 0 selects the system default

\#tcp\_keepalives\_interval = 0		# TCP\_KEEPINTVL, in seconds;

&nbsp;					# 0 selects the system default

\#tcp\_keepalives\_count = 0		# TCP\_KEEPCNT;

&nbsp;					# 0 selects the system default

\#tcp\_user\_timeout = 0			# TCP\_USER\_TIMEOUT, in milliseconds;

&nbsp;					# 0 selects the system default



\#client\_connection\_check\_interval = 0	# time between checks for client

&nbsp;					# disconnection while running queries;

&nbsp;					# 0 for never



\# - Authentication -



\#authentication\_timeout = 1min		# 1s-600s

\#password\_encryption = scram-sha-256	# scram-sha-256 or md5

\#db\_user\_namespace = off



\# GSSAPI using Kerberos

\#krb\_server\_keyfile = 'FILE:${sysconfdir}/krb5.keytab'

\#krb\_caseins\_users = off



\# - SSL -



\#ssl = off

\#ssl\_ca\_file = ''

\#ssl\_cert\_file = 'server.crt'

\#ssl\_crl\_file = ''

\#ssl\_crl\_dir = ''

\#ssl\_key\_file = 'server.key'

\#ssl\_ciphers = 'HIGH:MEDIUM:+3DES:!aNULL' # allowed SSL ciphers

\#ssl\_prefer\_server\_ciphers = on

\#ssl\_ecdh\_curve = 'prime256v1'

\#ssl\_min\_protocol\_version = 'TLSv1.2'

\#ssl\_max\_protocol\_version = ''

\#ssl\_dh\_params\_file = ''

\#ssl\_passphrase\_command = ''

\#ssl\_passphrase\_command\_supports\_reload = off



\#------------------------------------------------------------------------------

\# RESOURCE USAGE (except WAL)

\#------------------------------------------------------------------------------



\# - Memory -



shared\_buffers = 128MB			# min 128kB

&nbsp;					# (change requires restart)

\#huge\_pages = try			# on, off, or try

&nbsp;					# (change requires restart)

\#huge\_page\_size = 0			# zero for system default

&nbsp;					# (change requires restart)

\#temp\_buffers = 8MB			# min 800kB

\#max\_prepared\_transactions = 0		# zero disables the feature

&nbsp;					# (change requires restart)

\# Caution: it is not advisable to set max\_prepared\_transactions nonzero unless

\# you actively intend to use prepared transactions.

\#work\_mem = 4MB				# min 64kB

\#hash\_mem\_multiplier = 1.0		# 1-1000.0 multiplier on hash table work\_mem

\#maintenance\_work\_mem = 64MB		# min 1MB

\#autovacuum\_work\_mem = -1		# min 1MB, or -1 to use maintenance\_work\_mem

\#logical\_decoding\_work\_mem = 64MB	# min 64kB

\#max\_stack\_depth = 2MB			# min 100kB

\#shared\_memory\_type = mmap		# the default is the first option

&nbsp;					# supported by the operating system:

&nbsp;					#   mmap

&nbsp;					#   sysv

&nbsp;					#   windows

&nbsp;					# (change requires restart)

dynamic\_shared\_memory\_type = posix	# the default is the first option

&nbsp;					# supported by the operating system:

&nbsp;					#   posix

&nbsp;					#   sysv

&nbsp;					#   windows

&nbsp;					#   mmap

&nbsp;					# (change requires restart)

\#min\_dynamic\_shared\_memory = 0MB	# (change requires restart)



\# - Disk -



\#temp\_file\_limit = -1			# limits per-process temp file space

&nbsp;					# in kilobytes, or -1 for no limit



\# - Kernel Resources -



\#max\_files\_per\_process = 1000		# min 64

&nbsp;					# (change requires restart)



\# - Cost-Based Vacuum Delay -



\#vacuum\_cost\_delay = 0			# 0-100 milliseconds (0 disables)

\#vacuum\_cost\_page\_hit = 1		# 0-10000 credits

\#vacuum\_cost\_page\_miss = 2		# 0-10000 credits

\#vacuum\_cost\_page\_dirty = 20		# 0-10000 credits

\#vacuum\_cost\_limit = 200		# 1-10000 credits



\# - Background Writer -



\#bgwriter\_delay = 200ms			# 10-10000ms between rounds

\#bgwriter\_lru\_maxpages = 100		# max buffers written/round, 0 disables

\#bgwriter\_lru\_multiplier = 2.0		# 0-10.0 multiplier on buffers scanned/round

\#bgwriter\_flush\_after = 512kB		# measured in pages, 0 disables



\# - Asynchronous Behavior -



\#backend\_flush\_after = 0		# measured in pages, 0 disables

\#effective\_io\_concurrency = 1		# 1-1000; 0 disables prefetching

\#maintenance\_io\_concurrency = 10	# 1-1000; 0 disables prefetching

\#max\_worker\_processes = 8		# (change requires restart)

\#max\_parallel\_workers\_per\_gather = 2	# taken from max\_parallel\_workers

\#max\_parallel\_maintenance\_workers = 2	# taken from max\_parallel\_workers

\#max\_parallel\_workers = 8		# maximum number of max\_worker\_processes that

&nbsp;					# can be used in parallel operations

\#parallel\_leader\_participation = on

\#old\_snapshot\_threshold = -1		# 1min-60d; -1 disables; 0 is immediate

&nbsp;					# (change requires restart)



\#------------------------------------------------------------------------------

\# WRITE-AHEAD LOG

\#------------------------------------------------------------------------------



\# - Settings -



\#wal\_level = replica			# minimal, replica, or logical

&nbsp;					# (change requires restart)

\#fsync = on				# flush data to disk for crash safety

&nbsp;					# (turning this off can cause

&nbsp;					# unrecoverable data corruption)

\#synchronous\_commit = on		# synchronization level;

&nbsp;					# off, local, remote\_write, remote\_apply, or on

\#wal\_sync\_method = fsync		# the default is the first option

&nbsp;					# supported by the operating system:

&nbsp;					#   open\_datasync

&nbsp;					#   fdatasync (default on Linux and FreeBSD)

&nbsp;					#   fsync

&nbsp;					#   fsync\_writethrough

&nbsp;					#   open\_sync

\#full\_page\_writes = on			# recover from partial page writes

\#wal\_log\_hints = off			# also do full page writes of non-critical updates

&nbsp;					# (change requires restart)

\#wal\_compression = off			# enable compression of full-page writes

\#wal\_init\_zero = on			# zero-fill new WAL files

\#wal\_recycle = on			# recycle WAL files

\#wal\_buffers = -1			# min 32kB, -1 sets based on shared\_buffers

&nbsp;					# (change requires restart)

\#wal\_writer\_delay = 200ms		# 1-10000 milliseconds

\#wal\_writer\_flush\_after = 1MB		# measured in pages, 0 disables

\#wal\_skip\_threshold = 2MB



\#commit\_delay = 0			# range 0-100000, in microseconds

\#commit\_siblings = 5			# range 1-1000



\# - Checkpoints -



\#checkpoint\_timeout = 5min		# range 30s-1d

\#checkpoint\_completion\_target = 0.9	# checkpoint target duration, 0.0 - 1.0

\#checkpoint\_flush\_after = 256kB		# measured in pages, 0 disables

\#checkpoint\_warning = 30s		# 0 disables

max\_wal\_size = 1GB

min\_wal\_size = 80MB



\# - Archiving -



\#archive\_mode = off		# enables archiving; off, on, or always

&nbsp;				# (change requires restart)

\#archive\_command = ''		# command to use to archive a logfile segment

&nbsp;				# placeholders: %p = path of file to archive

&nbsp;				#               %f = file name only

&nbsp;				# e.g. 'test ! -f /mnt/server/archivedir/%f \&\& cp %p /mnt/server/archivedir/%f'

\#archive\_timeout = 0		# force a logfile segment switch after this

&nbsp;				# number of seconds; 0 disables



\# - Archive Recovery -



\# These are only used in recovery mode.



\#restore\_command = ''		# command to use to restore an archived logfile segment

&nbsp;				# placeholders: %p = path of file to restore

&nbsp;				#               %f = file name only

&nbsp;				# e.g. 'cp /mnt/server/archivedir/%f %p'

\#archive\_cleanup\_command = ''	# command to execute at every restartpoint

\#recovery\_end\_command = ''	# command to execute at completion of recovery



\# - Recovery Target -



\# Set these only when performing a targeted recovery.



\#recovery\_target = ''		# 'immediate' to end recovery as soon as a

&nbsp;                               # consistent state is reached

&nbsp;				# (change requires restart)

\#recovery\_target\_name = ''	# the named restore point to which recovery will proceed

&nbsp;				# (change requires restart)

\#recovery\_target\_time = ''	# the time stamp up to which recovery will proceed

&nbsp;				# (change requires restart)

\#recovery\_target\_xid = ''	# the transaction ID up to which recovery will proceed

&nbsp;				# (change requires restart)

\#recovery\_target\_lsn = ''	# the WAL LSN up to which recovery will proceed

&nbsp;				# (change requires restart)

\#recovery\_target\_inclusive = on # Specifies whether to stop:

&nbsp;				# just after the specified recovery target (on)

&nbsp;				# just before the recovery target (off)

&nbsp;				# (change requires restart)

\#recovery\_target\_timeline = 'latest'	# 'current', 'latest', or timeline ID

&nbsp;				# (change requires restart)

\#recovery\_target\_action = 'pause'	# 'pause', 'promote', 'shutdown'

&nbsp;				# (change requires restart)



\#------------------------------------------------------------------------------

\# REPLICATION

\#------------------------------------------------------------------------------



\# - Sending Servers -



\# Set these on the primary and on any standby that will send replication data.



\#max\_wal\_senders = 10		# max number of walsender processes

&nbsp;				# (change requires restart)

\#max\_replication\_slots = 10	# max number of replication slots

&nbsp;				# (change requires restart)

\#wal\_keep\_size = 0		# in megabytes; 0 disables

\#max\_slot\_wal\_keep\_size = -1	# in megabytes; -1 disables

\#wal\_sender\_timeout = 60s	# in milliseconds; 0 disables

\#track\_commit\_timestamp = off	# collect timestamp of transaction commit

&nbsp;				# (change requires restart)



\# - Primary Server -



\# These settings are ignored on a standby server.



\#synchronous\_standby\_names = ''	# standby servers that provide sync rep

&nbsp;				# method to choose sync standbys, number of sync standbys,

&nbsp;				# and comma-separated list of application\_name

&nbsp;				# from standby(s); '\*' = all

\#vacuum\_defer\_cleanup\_age = 0	# number of xacts by which cleanup is delayed



\# - Standby Servers -



\# These settings are ignored on a primary server.



\#primary\_conninfo = ''			# connection string to sending server

\#primary\_slot\_name = ''			# replication slot on sending server

\#promote\_trigger\_file = ''		# file name whose presence ends recovery

\#hot\_standby = on			# "off" disallows queries during recovery

&nbsp;					# (change requires restart)

\#max\_standby\_archive\_delay = 30s	# max delay before canceling queries

&nbsp;					# when reading WAL from archive;

&nbsp;					# -1 allows indefinite delay

\#max\_standby\_streaming\_delay = 30s	# max delay before canceling queries

&nbsp;					# when reading streaming WAL;

&nbsp;					# -1 allows indefinite delay

\#wal\_receiver\_create\_temp\_slot = off	# create temp slot if primary\_slot\_name

&nbsp;					# is not set

\#wal\_receiver\_status\_interval = 10s	# send replies at least this often

&nbsp;					# 0 disables

\#hot\_standby\_feedback = off		# send info from standby to prevent

&nbsp;					# query conflicts

\#wal\_receiver\_timeout = 60s		# time that receiver waits for

&nbsp;					# communication from primary

&nbsp;					# in milliseconds; 0 disables

\#wal\_retrieve\_retry\_interval = 5s	# time to wait before retrying to

&nbsp;					# retrieve WAL after a failed attempt

\#recovery\_min\_apply\_delay = 0		# minimum delay for applying changes during recovery



\# - Subscribers -



\# These settings are ignored on a publisher.



\#max\_logical\_replication\_workers = 4	# taken from max\_worker\_processes

&nbsp;					# (change requires restart)

\#max\_sync\_workers\_per\_subscription = 2	# taken from max\_logical\_replication\_workers



\#------------------------------------------------------------------------------

\# QUERY TUNING

\#------------------------------------------------------------------------------



\# - Planner Method Configuration -



\#enable\_async\_append = on

\#enable\_bitmapscan = on

\#enable\_gathermerge = on

\#enable\_hashagg = on

\#enable\_hashjoin = on

\#enable\_incremental\_sort = on

\#enable\_indexscan = on

\#enable\_indexonlyscan = on

\#enable\_material = on

\#enable\_memoize = on

\#enable\_mergejoin = on

\#enable\_nestloop = on

\#enable\_parallel\_append = on

\#enable\_parallel\_hash = on

\#enable\_partition\_pruning = on

\#enable\_partitionwise\_join = off

\#enable\_partitionwise\_aggregate = off

\#enable\_seqscan = on

\#enable\_sort = on

\#enable\_tidscan = on



\# - Planner Cost Constants -



\#seq\_page\_cost = 1.0			# measured on an arbitrary scale

\#random\_page\_cost = 4.0			# same scale as above

\#cpu\_tuple\_cost = 0.01			# same scale as above

\#cpu\_index\_tuple\_cost = 0.005		# same scale as above

\#cpu\_operator\_cost = 0.0025		# same scale as above

\#parallel\_setup\_cost = 1000.0	# same scale as above

\#parallel\_tuple\_cost = 0.1		# same scale as above

\#min\_parallel\_table\_scan\_size = 8MB

\#min\_parallel\_index\_scan\_size = 512kB

\#effective\_cache\_size = 4GB



\#jit\_above\_cost = 100000		# perform JIT compilation if available

&nbsp;					# and query more expensive than this;

&nbsp;					# -1 disables

\#jit\_inline\_above\_cost = 500000		# inline small functions if query is

&nbsp;					# more expensive than this; -1 disables

\#jit\_optimize\_above\_cost = 500000	# use expensive JIT optimizations if

&nbsp;					# query is more expensive than this;

&nbsp;					# -1 disables



\# - Genetic Query Optimizer -



\#geqo = on

\#geqo\_threshold = 12

\#geqo\_effort = 5			# range 1-10

\#geqo\_pool\_size = 0			# selects default based on effort

\#geqo\_generations = 0			# selects default based on effort

\#geqo\_selection\_bias = 2.0		# range 1.5-2.0

\#geqo\_seed = 0.0			# range 0.0-1.0



\# - Other Planner Options -



\#default\_statistics\_target = 100	# range 1-10000

\#constraint\_exclusion = partition	# on, off, or partition

\#cursor\_tuple\_fraction = 0.1		# range 0.0-1.0

\#from\_collapse\_limit = 8

\#jit = on				# allow JIT compilation

\#join\_collapse\_limit = 8		# 1 disables collapsing of explicit

&nbsp;					# JOIN clauses

\#plan\_cache\_mode = auto			# auto, force\_generic\_plan or

&nbsp;					# force\_custom\_plan



\#------------------------------------------------------------------------------

\# REPORTING AND LOGGING

\#------------------------------------------------------------------------------



\# - Where to Log -



\#log\_destination = 'stderr'		# Valid values are combinations of

&nbsp;					# stderr, csvlog, syslog, and eventlog,

&nbsp;					# depending on platform.  csvlog

&nbsp;					# requires logging\_collector to be on.



\# This is used when logging to stderr:

logging\_collector = on

\#logging\_collector = off		# Enable capturing of stderr and csvlog

&nbsp;					# into log files. Required to be on for

&nbsp;					# csvlogs.

&nbsp;					# (change requires restart)



\# These are only used if logging\_collector is on:

log\_directory = '/var/lib/postgresql/logs'

\#log\_directory = 'log'			# directory where log files are written,

&nbsp;					# can be absolute or relative to PGDATA

\#log\_filename = 'postgresql-%Y-%m-%d\_%H%M%S.log'	# log file name pattern,

&nbsp;					# can include strftime() escapes

\#log\_file\_mode = 0600			# creation mode for log files,

&nbsp;					# begin with 0 to use octal notation

\#log\_rotation\_age = 1d			# Automatic rotation of logfiles will

&nbsp;					# happen after that time.  0 disables.

\#log\_rotation\_size = 10MB		# Automatic rotation of logfiles will

&nbsp;					# happen after that much log output.

&nbsp;					# 0 disables.

\#log\_truncate\_on\_rotation = off		# If on, an existing log file with the

&nbsp;					# same name as the new log file will be

&nbsp;					# truncated rather than appended to.

&nbsp;					# But such truncation only occurs on

&nbsp;					# time-driven rotation, not on restarts

&nbsp;					# or size-driven rotation.  Default is

&nbsp;					# off, meaning append to existing files

&nbsp;					# in all cases.



\# These are relevant when logging to syslog:

\#syslog\_facility = 'LOCAL0'

\#syslog\_ident = 'postgres'

\#syslog\_sequence\_numbers = on

\#syslog\_split\_messages = on



\# This is only relevant when logging to eventlog (Windows):

\# (change requires restart)

\#event\_source = 'PostgreSQL'



\# - When to Log -



\#log\_min\_messages = warning		# values in order of decreasing detail:

&nbsp;					#   debug5

&nbsp;					#   debug4

&nbsp;					#   debug3

&nbsp;					#   debug2

&nbsp;					#   debug1

&nbsp;					#   info

&nbsp;					#   notice

&nbsp;					#   warning

&nbsp;					#   error

&nbsp;					#   log

&nbsp;					#   fatal

&nbsp;					#   panic



\#log\_min\_error\_statement = error	# values in order of decreasing detail:

&nbsp;					#   debug5

&nbsp;					#   debug4

&nbsp;					#   debug3

&nbsp;					#   debug2

&nbsp;					#   debug1

&nbsp;					#   info

&nbsp;					#   notice

&nbsp;					#   warning

&nbsp;					#   error

&nbsp;					#   log

&nbsp;					#   fatal

&nbsp;					#   panic (effectively off)



\#log\_min\_duration\_statement = -1	# -1 is disabled, 0 logs all statements

&nbsp;					# and their durations, > 0 logs only

&nbsp;					# statements running at least this number

&nbsp;					# of milliseconds



\#log\_min\_duration\_sample = -1		# -1 is disabled, 0 logs a sample of statements

&nbsp;					# and their durations, > 0 logs only a sample of

&nbsp;					# statements running at least this number

&nbsp;					# of milliseconds;

&nbsp;					# sample fraction is determined by log\_statement\_sample\_rate



\#log\_statement\_sample\_rate = 1.0	# fraction of logged statements exceeding

&nbsp;					# log\_min\_duration\_sample to be logged;

&nbsp;					# 1.0 logs all such statements, 0.0 never logs



\#log\_transaction\_sample\_rate = 0.0	# fraction of transactions whose statements

&nbsp;					# are logged regardless of their duration; 1.0 logs all

&nbsp;					# statements from all transactions, 0.0 never logs



\# - What to Log -



\#debug\_print\_parse = off

\#debug\_print\_rewritten = off

\#debug\_print\_plan = off

\#debug\_pretty\_print = on

\#log\_autovacuum\_min\_duration = -1	# log autovacuum activity;

&nbsp;					# -1 disables, 0 logs all actions and

&nbsp;					# their durations, > 0 logs only

&nbsp;					# actions running at least this number

&nbsp;					# of milliseconds.

\#log\_checkpoints = off

\#log\_connections = off

\#log\_disconnections = off

\#log\_duration = off

\#log\_error\_verbosity = default		# terse, default, or verbose messages

\#log\_hostname = off

\#log\_line\_prefix = '%m \[%p] '		# special values:

&nbsp;					#   %a = application name

&nbsp;					#   %u = user name

&nbsp;					#   %d = database name

&nbsp;					#   %r = remote host and port

&nbsp;					#   %h = remote host

&nbsp;					#   %b = backend type

&nbsp;					#   %p = process ID

&nbsp;					#   %P = process ID of parallel group leader

&nbsp;					#   %t = timestamp without milliseconds

&nbsp;					#   %m = timestamp with milliseconds

&nbsp;					#   %n = timestamp with milliseconds (as a Unix epoch)

&nbsp;					#   %Q = query ID (0 if none or not computed)

&nbsp;					#   %i = command tag

&nbsp;					#   %e = SQL state

&nbsp;					#   %c = session ID

&nbsp;					#   %l = session line number

&nbsp;					#   %s = session start timestamp

&nbsp;					#   %v = virtual transaction ID

&nbsp;					#   %x = transaction ID (0 if none)

&nbsp;					#   %q = stop here in non-session

&nbsp;					#        processes

&nbsp;					#   %% = '%'

&nbsp;					# e.g. '<%u%%%d> '

\#log\_lock\_waits = off			# log lock waits >= deadlock\_timeout

\#log\_recovery\_conflict\_waits = off	# log standby recovery conflict waits

&nbsp;					# >= deadlock\_timeout

\#log\_parameter\_max\_length = -1		# when logging statements, limit logged

&nbsp;					# bind-parameter values to N bytes;

&nbsp;					# -1 means print in full, 0 disables

\#log\_parameter\_max\_length\_on\_error = 0	# when logging an error, limit logged

&nbsp;					# bind-parameter values to N bytes;

&nbsp;					# -1 means print in full, 0 disables

\#log\_statement = 'none'			# none, ddl, mod, all

\#log\_replication\_commands = off

\#log\_temp\_files = -1			# log temporary files equal or larger

&nbsp;					# than the specified size in kilobytes;

&nbsp;					# -1 disables, 0 logs all temp files

log\_timezone = 'Etc/UTC'



\#------------------------------------------------------------------------------

\# PROCESS TITLE

\#------------------------------------------------------------------------------



\#cluster\_name = ''			# added to process titles if nonempty

&nbsp;					# (change requires restart)

\#update\_process\_title = on



\#------------------------------------------------------------------------------

\# STATISTICS

\#------------------------------------------------------------------------------



\# - Query and Index Statistics Collector -



\#track\_activities = on

\#track\_activity\_query\_size = 1024	# (change requires restart)

\#track\_counts = on

\#track\_io\_timing = off

\#track\_wal\_io\_timing = off

\#track\_functions = none			# none, pl, all

\#stats\_temp\_directory = 'pg\_stat\_tmp'



\# - Monitoring -



\#compute\_query\_id = auto

\#log\_statement\_stats = off

\#log\_parser\_stats = off

\#log\_planner\_stats = off

\#log\_executor\_stats = off



\#------------------------------------------------------------------------------

\# AUTOVACUUM

\#------------------------------------------------------------------------------



\#autovacuum = on			# Enable autovacuum subprocess?  'on'

&nbsp;					# requires track\_counts to also be on.

\#autovacuum\_max\_workers = 3		# max number of autovacuum subprocesses

&nbsp;					# (change requires restart)

\#autovacuum\_naptime = 1min		# time between autovacuum runs

\#autovacuum\_vacuum\_threshold = 50	# min number of row updates before

&nbsp;					# vacuum

\#autovacuum\_vacuum\_insert\_threshold = 1000	# min number of row inserts

&nbsp;					# before vacuum; -1 disables insert

&nbsp;					# vacuums

\#autovacuum\_analyze\_threshold = 50	# min number of row updates before

&nbsp;					# analyze

\#autovacuum\_vacuum\_scale\_factor = 0.2	# fraction of table size before vacuum

\#autovacuum\_vacuum\_insert\_scale\_factor = 0.2	# fraction of inserts over table

&nbsp;					# size before insert vacuum

\#autovacuum\_analyze\_scale\_factor = 0.1	# fraction of table size before analyze

\#autovacuum\_freeze\_max\_age = 200000000	# maximum XID age before forced vacuum

&nbsp;					# (change requires restart)

\#autovacuum\_multixact\_freeze\_max\_age = 400000000	# maximum multixact age

&nbsp;					# before forced vacuum

&nbsp;					# (change requires restart)

\#autovacuum\_vacuum\_cost\_delay = 2ms	# default vacuum cost delay for

&nbsp;					# autovacuum, in milliseconds;

&nbsp;					# -1 means use vacuum\_cost\_delay

\#autovacuum\_vacuum\_cost\_limit = -1	# default vacuum cost limit for

&nbsp;					# autovacuum, -1 means use

&nbsp;					# vacuum\_cost\_limit



\#------------------------------------------------------------------------------

\# CLIENT CONNECTION DEFAULTS

\#------------------------------------------------------------------------------



\# - Statement Behavior -



\#client\_min\_messages = notice		# values in order of decreasing detail:

&nbsp;					#   debug5

&nbsp;					#   debug4

&nbsp;					#   debug3

&nbsp;					#   debug2

&nbsp;					#   debug1

&nbsp;					#   log

&nbsp;					#   notice

&nbsp;					#   warning

&nbsp;					#   error

\#search\_path = '"$user", public'	# schema names

\#row\_security = on

\#default\_table\_access\_method = 'heap'

\#default\_tablespace = ''		# a tablespace name, '' uses the default

\#default\_toast\_compression = 'pglz'	# 'pglz' or 'lz4'

\#temp\_tablespaces = ''			# a list of tablespace names, '' uses

&nbsp;					# only default tablespace

\#check\_function\_bodies = on

\#default\_transaction\_isolation = 'read committed'

\#default\_transaction\_read\_only = off

\#default\_transaction\_deferrable = off

\#session\_replication\_role = 'origin'

\#statement\_timeout = 0			# in milliseconds, 0 is disabled

\#lock\_timeout = 0			# in milliseconds, 0 is disabled

\#idle\_in\_transaction\_session\_timeout = 0	# in milliseconds, 0 is disabled

\#idle\_session\_timeout = 0		# in milliseconds, 0 is disabled

\#vacuum\_freeze\_table\_age = 150000000

\#vacuum\_freeze\_min\_age = 50000000

\#vacuum\_failsafe\_age = 1600000000

\#vacuum\_multixact\_freeze\_table\_age = 150000000

\#vacuum\_multixact\_freeze\_min\_age = 5000000

\#vacuum\_multixact\_failsafe\_age = 1600000000

\#bytea\_output = 'hex'			# hex, escape

\#xmlbinary = 'base64'

\#xmloption = 'content'

\#gin\_pending\_list\_limit = 4MB



\# - Locale and Formatting -



datestyle = 'iso, mdy'

\#intervalstyle = 'postgres'

timezone = 'Etc/UTC'

\#timezone\_abbreviations = 'Default'     # Select the set of available time zone

&nbsp;					# abbreviations.  Currently, there are

&nbsp;					#   Default

&nbsp;					#   Australia (historical usage)

&nbsp;					#   India

&nbsp;					# You can create your own file in

&nbsp;					# share/timezonesets/.

\#extra\_float\_digits = 1			# min -15, max 3; any value >0 actually

&nbsp;					# selects precise output mode

\#client\_encoding = sql\_ascii		# actually, defaults to database

&nbsp;					# encoding



\# These settings are initialized by initdb, but they can be changed.

lc\_messages = 'en\_US.utf8'			# locale for system error message

&nbsp;					# strings

lc\_monetary = 'en\_US.utf8'			# locale for monetary formatting

lc\_numeric = 'en\_US.utf8'			# locale for number formatting

lc\_time = 'en\_US.utf8'				# locale for time formatting



\# default configuration for text search

default\_text\_search\_config = 'pg\_catalog.english'



\# - Shared Library Preloading -



\#local\_preload\_libraries = ''

\#session\_preload\_libraries = ''

\#shared\_preload\_libraries = ''	# (change requires restart)

\#jit\_provider = 'llvmjit'		# JIT library to use



\# - Other Defaults -



\#dynamic\_library\_path = '$libdir'

\#extension\_destdir = ''			# prepend path when loading extensions

&nbsp;					# and shared objects (added by Debian)

\#gin\_fuzzy\_search\_limit = 0



\#------------------------------------------------------------------------------

\# LOCK MANAGEMENT

\#------------------------------------------------------------------------------



\#deadlock\_timeout = 1s

\#max\_locks\_per\_transaction = 64		# min 10

&nbsp;					# (change requires restart)

\#max\_pred\_locks\_per\_transaction = 64	# min 10

&nbsp;					# (change requires restart)

\#max\_pred\_locks\_per\_relation = -2	# negative values mean

&nbsp;					# (max\_pred\_locks\_per\_transaction

&nbsp;					#  / -max\_pred\_locks\_per\_relation) - 1

\#max\_pred\_locks\_per\_page = 2            # min 0



\#------------------------------------------------------------------------------

\# VERSION AND PLATFORM COMPATIBILITY

\#------------------------------------------------------------------------------



\# - Previous PostgreSQL Versions -



\#array\_nulls = on

\#backslash\_quote = safe\_encoding	# on, off, or safe\_encoding

\#escape\_string\_warning = on

\#lo\_compat\_privileges = off

\#quote\_all\_identifiers = off

\#standard\_conforming\_strings = on

\#synchronize\_seqscans = on



\# - Other Platforms and Clients -



\#transform\_null\_equals = off



\#------------------------------------------------------------------------------

\# ERROR HANDLING

\#------------------------------------------------------------------------------



\#exit\_on\_error = off			# terminate session on any error?

\#restart\_after\_crash = on		# reinitialize after backend crash?

\#data\_sync\_retry = off			# retry or panic on failure to fsync

&nbsp;					# data?

&nbsp;					# (change requires restart)

\#recovery\_init\_sync\_method = fsync	# fsync, syncfs (Linux 5.8+)



\#------------------------------------------------------------------------------

\# CONFIG FILE INCLUDES

\#------------------------------------------------------------------------------



\# These options allow settings to be loaded from files other than the

\# default postgresql.conf.  Note that these are directives, not variable

\# assignments, so they can usefully be given more than once.



\#include\_dir = '...'			# include files ending in '.conf' from

&nbsp;					# a directory, e.g., 'conf.d'

\#include\_if\_exists = '...'		# include file only if it exists

\#include = '...'			# include file



\#------------------------------------------------------------------------------

\# CUSTOMIZED OPTIONS

\#------------------------------------------------------------------------------



\# Add settings for extensions here

shared\_preload\_libraries = 'pg\_cron'

\# optionally, specify the database in which the pg\_cron background worker should run (defaults to postgres)

cron.database\_name = 'postgres'

\#######################################

\# other installations in psql:

\# - \\c {cron.database\_name}

\# - CREATE EXTENSION pg\_cron;

\# - SELECT cron.schedule('delete-job-run-details', '0 12 \* \* \*', $$DELETE FROM cron.job\_run\_details WHERE end\_time < now() - interval '7 days'$$);

\#######################################

\# optionally, specify the timezone in which the pg\_cron background worker should run (defaults to GMT). E.g:

cron.timezone = 'PRC'



```

