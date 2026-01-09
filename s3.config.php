<?php
$CONFIG = array(
  'objectstore' => array(
    'class' => '\\OC\\Files\\ObjectStore\\S3',
    'arguments' => array(
      'bucket' => 'nextcloud-data',
      'autocreate' => true,
      'key'    => 'nextcloud-user', // Votre user MinIO
      'secret' => 'nextcloud-secret-key', // Votre password MinIO
      'hostname' => '10.3.54.165', // Mettez l'adresse IP privée ou publique de la VM2
      'port' => 9000,
      'use_ssl' => false,
      'use_path_style'=>true
    ),
  ),
);