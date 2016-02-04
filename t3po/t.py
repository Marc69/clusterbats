import sh
import subprocess

#sh.bats('t.bats')
subprocess.call("bats t.bats", shell=True)
