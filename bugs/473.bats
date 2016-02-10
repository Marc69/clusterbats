@test "bug 473 - After deployment there are no valid repositories..." {
  yum repolist enabled | grep 'CentOS-7 - Base'
  yum repolist enabled | grep 'CentOS-7 - Extras'
  yum repolist enabled | grep 'CentOS-7 - Updates'
}
