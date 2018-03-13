Nginx
=====

Sets up nginx using sites-available / sites-enabled construct to manage site configs.

Role Variables
--------------


Example Playbook
----------------

Example assumes having a group var 'stage' set.

	- hosts: webservers
	  roles:
	  - nginx
	  vars:
	  - nginx_enable_monitor: false  # default=true, will setup default server responding to /monitor/monitor.html
	  - nginx_package_source: nginx  # default=nginx, options: nginx, openresty
	  - nginx_redirect_to_https: true # default=false, will redirect to https if $http_x_forwarded_proto != "https"
	  - nginx_sites:
	    - name: nunl
	      enabled: true
	      type: uwsgi
	      redirect_to_https: false # nginx_redirect_to_https can be overrided for specific sites
          client_max_body_size: 500m # default will be 10m
	      server: api.nu.nl api.{{ stage }}.nu.nl api.{{ ansible_hostname }} api.{{ ansible_fqdn }}
	      listen:
            - "*:80"
            - "*:81 http2 proxy_protocol"
	      uwsgi_sock: /data/home/nunl/{{ stage }}_runtime/uwsgi.sock
	      log_path: /data/logs/nunl
	      root_headers:
              - name: "Strict-Transport-Security"
                value: "max-age=31536000; includeSubDomains;"
              - name: "Cache-Control"
                value: "no-cache, no-store"
              - name: "X-Content-Type-Options"
                value: "nosniff"
	      locations:
	      - match: /static/
	        alias: /data/home/nunl/{{ stage }}_current/static/

Example usage of extra params and cors.

    vars:
      cors_whitelist: # You domain whitelist, http, https and subdomains are automatically allowed for those
        - sanomadefault # * wont work, it's regex escaped. We could aad something to handle * later
        - blah.com

    - role: nginx
      nginx_real_ip: true # if you want the IP logged to be the one from X-Forwarded-For (by the ELB) or
      nginx_enable_monitor: false  # default=true, will setup default server responding to /monitor/monitor.html
      nginx_log_formats:
        realip: '"$remote_addr -> $realip_remote_addr - $remote_user [$time_local] \"$request\" $status $body_bytes_sent \"$http_referer\" \"$http_user_agent\" \"$http_x_forwarded_for\" - $request_time"'
      nginx_sites:
        - name: commoncheckout_admin # Only internal ELB should point to this port
          listen: "*:8080" # Optional
          cors_domains: "{{ cors_whitelist }}" # Optionnal. You can also define inline
          enabled: true
          type: uwsgi
          client_max_body_size: 500m # default will be 10m
          server: "{{ ansible_fqdn }}"
          uwsgi_sock: /data/home/commoncheckout/{{ stage }}_runtime/uwsgi.sock
          auth_basic_user_file: /etc/nginx/blah
          log_path: /data/logs/commoncheckout
          locations:
            - match: /static/
              alias: /data/home/commoncheckout/{{ stage }}_current/public/static/
            - match: "=/testresult.xml"
              alias: /var/nginx/static/last_test_result.xml
              cors: true # Default is false. Enable CORS whitelist for this location
              allow_no_origin: false # if you wan to allow requests without an origin header (or not). Default: true
              params:
                auth_basic: "off"
                allow: all
                add_header: # this creates multiple lines
                   - "Content-type blah"
                   - "Header whatever"
            - name: commoncheckout
              enabled: true
              type: uwsgi
              client_max_body_size: 500m # default will be 10m
              server: "{{ ansible_fqdn }}"
              uwsgi_sock: /data/home/commoncheckout/{{ stage }}_runtime/uwsgi.sock

              log_path: /data/logs/commoncheckout
              log_format: realip # The key of the log format you specified in the higher scope
              log_ignore_urls:   # Nginx regex on the request path that should not be logged
                  - "~/monitoring.html"
              # Optionnal: Specify a .htpassword path  (you must create it somewhere else)
              auth_basic_user_file: "{% if stage not in ['development'] %}/etc/nginx/.htpasswd{% else %}False{% endif %}"
              locations:
                - match: /static/
                  alias: /data/home/commoncheckout/{{ stage }}_current/public/static/
                  params:
                    add_header: 'Cache-Control "public, max-age=604800"' # you don't need a list for only one
                    expires: 7d
                - match: /admin/
                  params:
                    deny: all
                - match: /dashboard/
                  params:
                    deny: all


Example usage of ordered extra params.

    nginx_sites:
      - name: "{{ app }}"
        enabled: true
        type: uwsgi
        client_max_body_size: 25m
        server: "{{ hostname }}"
        uwsgi_sock: "{{ uwsgi_socket }}"
        log_path: "{{ logdir }}/nginx"
        root_headers:
          - name: "Cache-Control"
            value: "no-cache, no-store"
          - name: "X-Content-Type-Options"
            value: "nosniff"
        locations:
          - match: /static/
            alias: "{{ static_files }}/"
          - match: /media/
            alias: "{{ media_files }}/"
          - match: /na-admin-place/
            params:  # if order matters, `params` can be the list of dictionaries
              - allow:
                - 158.127.224.147
              - deny: all
              - try_files: "$uri @uwsgi"

Installing Nginx OpenResty instead of default Nginx. (https://openresty.org/en/).
Using a Lua rewrite script and using cache.

    nginx_package_source: openresty
    nginx_lua_scripts: rewrite.lua  # add to /deploy/ansible/files/
    nginx_cache_paths:
      - key_zone: my_key_zone  # name of key zone, will also be created as folder /data/nginx_cache/zone1
        type: uwsgi  # uwsgi, proxy, fastcgi
        levels: "1:2"
        size: 50m
        max_size: 500m
        inactive: 10m
        use_temp_path: off  # optional, default : off
        raw: ""  # anything else needing to be appended to the _cache_path directive
    nginx_sites:
      - name: main
        locations: ~* ^\/special
          - match:
            raw: |
              rewrite_by_lua_file /etc/nginx/lua/rewrite.lua;
              try_files $uri @uwsgi;

To do
-----
- Make more of nginx conf template configurable
- Make more of site config template configurable
- Allow setting entire site config in playbook as variable
- Add site config types other than uwsgi
- ...


Author Information
------------------

- tibo.beijen@sanoma.com
- ...
