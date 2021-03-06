class logstash::lumberjack::config (
  $servers,
  $timeout,
  $files,
  $ssl_cert_path,
  $ssl_cert_source,
  $ssl_key_path,
  $ssl_key_source,
  $ssl_ca_path,
  $ssl_ca_source,
) {

  file { '/etc/init.d/lumberjack':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/logstash/lumberjack.init'
  }

  service { 'lumberjack':
    ensure    => running,
    hasstatus => true,
  }

  File['/etc/init.d/lumberjack'] -> Service['lumberjack']

  file { '/etc/lumberjack':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  if $ssl_cert_source {
    file { $ssl_cert_path:
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => $ssl_cert_source,
      require => File['/etc/lumberjack'],
      before  => Service['lumberjack'],
    }
  }

  if $ssl_key_source {
    file { $ssl_key_path:
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => $ssl_key_source,
      require => File['/etc/lumberjack'],
      before  => Service['lumberjack'],
    }
  }

  if $ssl_ca_source {
    file { $ssl_ca_path:
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => $ssl_ca_source,
      require => File['/etc/lumberjack'],
      before  => Service['lumberjack'],
    }
  }

  if !is_array($files) or size($files) < 1 {
    fail('Missing or invalid files parameter for Lumberjack. Expected an array of hashes. See https://github.com/jordansissel/lumberjack#configuring.')
  }

  if !is_array($servers) or size($servers) < 1 {
    fail('Missing or invalid servers parameter for Lumberjack. Expected an array of "host:port" server definitions.')
  }

  $base_network_config = {
    'servers' => $servers,
    'ssl ca'  => $ssl_ca_path,
    'timeout' => $timeout,
  }

  if $ssl_cert_path {
    $network_config_with_cert = merge($base_network_config, {
      'ssl certificate' => $ssl_cert_path,
    })
  }
  else {
    $network_config_with_cert = $base_network_config
  }

  if $ssl_key_path {
    $network_config = merge($network_config_with_cert, {
      'ssl key' => $ssl_key_path,
    })
  }
  else {
    $network_config = $network_config_with_cert
  }

  # see config hash format at https://github.com/jordansissel/lumberjack#configuring.
  $config = {
    network => $network_config,
    files   => $files,
  }

  file { '/etc/lumberjack/lumberjack.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => sorted_json($config),
    notify  => Service['lumberjack'],
  }

  File['/etc/lumberjack'] -> File['/etc/lumberjack/lumberjack.conf']
}
