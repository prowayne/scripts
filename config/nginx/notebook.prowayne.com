server {
  listen          80;       # Listen on port 80 for IPv4 requests
  listen          443 ssl;
  server_name     notebook.prowayne.com;

  ssl_certificate       /var/www/jupyterhub/ca.crt;
  ssl_certificate_key   /var/www/jupyterhub/ca.key;
  ssl_protocols         TLSv1 TLSv1.1 TLSv1.2;

  access_log      /var/log/nginx/jupyterhub/access.log;
  error_log       /var/log/nginx/jupyterhub/error.log;

  location @ipython {
      sendfile off;
      proxy_pass         http://127.0.0.1:8000;
      proxy_redirect     default;

      proxy_http_version 1.1;
      proxy_set_header   Upgrade $http_upgrade;
      proxy_set_header   Connection "upgrade";
      proxy_set_header   Origin "";

      proxy_set_header   Host             $host;
      proxy_set_header   X-Real-IP        $remote_addr;
      proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
      proxy_max_temp_file_size 0;

      #this is the maximum upload size
      client_max_body_size       10m;
      client_body_buffer_size    128k;

      proxy_connect_timeout      90;
      proxy_send_timeout         90;
      proxy_read_timeout         90;

      proxy_buffer_size          4k;
      proxy_buffers              4 32k;
      proxy_busy_buffers_size    64k;
      proxy_temp_file_write_size 64k;
}

  location / {
      try_files $uri @ipython;
   }
}
