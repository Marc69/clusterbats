#title          : t3po
#description    : Test runner script for Trinity
#author         : Hans Then
#email          : hans.then@clustervision.com

import tap
import tap.parser
import sqlite3
import logging as logger
import argparse
import datetime
import sh
import tempfile
import os


def connection():
    """Get a database connection."""
    return sqlite3.connect('/var/lib/t3po/test_log.db', 
        detect_types=sqlite3.PARSE_DECLTYPES|sqlite3.PARSE_COLNAMES)

def initialize():
    """Initialize the database."""
    if os.path.exists('/var/lib/t3po/test_log.db'):
        return
    if not os.path.exists('/var/lib/t3po/'):
        os.makedirs('/var/lib/t3po/')
    conn = connection()
    c = conn.cursor()
    try:
        c.execute('''CREATE TABLE test
                     (id text primary key, desc text)''')
        c.execute('''CREATE TABLE testrun
                     (run timestamp primary key, branch text, revision text, 
                      user text, configuration text)''')
        c.execute('''CREATE TABLE testresult
                     (run timestamp, id text, result text, comment text, 
                     primary key(run, id))''')
    except Exception, error:
        print error


def run(branch, rev=None, user=None, configuration=None, tests=[]):
    """Run a set of tests"""
    if not tests: 
        tests = ['/root/hans/clusterbats/master/t1.1.bats']

    # Setup the correct version on the master node
    tmpdir = '/tmp/t3po'
    if not os.path.exists(tmpdir + '/trinity'):
        if not os.path.exists(tmpdir):
            os.makedirs(tmpdir)
        os.chdir(tmpdir)
        for line in sh.git.clone('http://github.com/clustervision/trinity', 
                                 _iter=True):
            print line

    os.chdir(tmpdir+ '/trinity')
    # Collect branch and or revision information
    if rev:
        sh.git.checkout(rev)
        if branch != sh.git('rev-parse', '--abbrev-ref', 'HEAD').strip():
            logger.warning("Specified revision %s is not in branch %s", 
                            revision, branch)
    else:
        sh.git.checkout(branch)
        rev = sh.git('rev-parse', 'HEAD')
    sh.bash('update', 'master')

    # Write the testrun 
    time = datetime.datetime.now()
    conn = connection()
    c = conn.cursor()

    c.execute('insert into testrun (run, branch, revision, user) ' + 
              'values (?,?,?,?)', \
              (time, branch, str(rev).strip(), user))

    conn.commit()

    for test in tests:
        stream = sh.bats(test, _iter=True)
        store_tap(time, stream)


def store_tap(run, stream):
    """Store a TAP stream into the database"""
    # Add the testrun to the database
    conn = connection()
    c = conn.cursor()
    parser = tap.parser.Parser()
    for line in stream:
        line = parser.parse_line(line)
        if isinstance(line, tap.line.Result):
            if line.skip:
                testid = line.directive.text[len('skip'):].strip()
                testid = testid.split('-')[0].strip()
            else:
                testid = line.description.split('-')[0].strip()

            try:
                ids = testid.split('.')
                testid = '.'.join(["%02d" % (int(digit)) for digit in ids])
            except:
                logger.warn("invalid testid %s", testid)
            result = 'PASS' if line.ok else 'FAIL'
            result = 'SKIP' if line.skip else result

            c.execute('insert or replace into test (id, desc) values (?,?)', 
                      (testid, line.description))
            c.execute('insert into testresult (run, id, result) ' + \
                      'values (?,?,?)', \
                      (run, testid, result))
            # FIXME:
            # attach the diagnostics lines
            conn.commit()

def html():
    """Ugly hack to create an HTML table for the test runs"""
    conn = connection()
    c = conn.cursor()
    c.execute('select * from testrun')
    print '<table><tr><th></th>'
    runs = []
    r = c.fetchone()
    while r:
        print '<th>' + str(r) + '</th>'
        runs.append(r[0])
        r = c.fetchone()
    print '</tr>'
    # collect test descriptions
    c.execute('select * from test')
    ids = []
    r = c.fetchone()
    while r:
        ids.append((r[0], r[1]))
        r = c.fetchone()
    # collect matches between tests and runs
    for id, desc in ids:
        print '<tr>'
        print '<th>' + id + '</th>'
        print '<th>' + desc + '</th>'
        for run in runs:
            c.execute('select * from testresult where run = ? and id = ?', 
                      (run, id))
            r = c.fetchone()
            if r:
                print '<td>' + str(r[2]) + '</td>'
            else:
                print '<td> </td>'
        print '</tr>'
    print '</table>'


#------------------------------------------------
# A few lines of test code
#------------------------------------------------
initialize()
run('r7', tests=['/root/hans/clusterbats/master/t1.2.bats'])
html()
