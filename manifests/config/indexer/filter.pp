define logstash::config::indexer::filter (
  $type,
  $params,
  $file = undef,
  $order = '00') {
  $config_order = "1${order}"

  include concat::setup

  if !$file {
    $filename = "${name}.filter"
  } else {
    $filename = $file
  }

  if $type == 'grok' {
    $params['patterns_dir'] = "[\"${::logstash::config::grok_patterns_dir}\"]"
  }

  $target  = "${::logstash::config::logstash_etc}/indexer/${filename}"
  $service = 'logstash-indexer'

  if !defined(Concat[$target]) {
    ::concat { $target:
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify => Service[$service],
    }
  }

  if !defined(Concat::Fragment['logstash-indexer_${filename}_filter_header']) {
    ::concat::fragment { 'logstash-indexer_${filename}_filter_header':
      target  => $target,
      order   => '000',
      content => "filter {\n",
    }
  }

  if !defined(Concat::Fragment['logstash-indexer_${filename}_filter_footer']) {
    ::concat::fragment { 'logstash-indexer_${filename}_filter_footer':
      target  => $target,
      order   => '200',
      content => "}\n",
    }
  }

  ::concat::fragment { "logstash_indexer_filter_${type}_${name}":
    target  => $target,
    order   => $config_order,
    content => template('logstash/config/fragment.erb'),
    notify  => Service[$service],
  }
}
