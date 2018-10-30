#!/usr/bin/env bash


if [[ -f "/certs/dhparam.pem" ]] ; then
  echo "==== Detected dhparam ===="
else
  echo "==== Generating 4096 dhparam ===="
  openssl dhparam -out /certs/dhparam.pem 4096
  chmod 644 /certs/dhparam.pem
fi

echo "==== Cleanup nginx/sites.d ===="
rm -f "/etc/nginx/sites.d/*"


if [[ ! -z $PROXY_DOMAINS ]]; then
  PROXY_DOMAINS="${PROXY_DOMAINS,,}" #convert to lowercase
  if [[ $PROXY_DOMAINS =~ [\,\;] ]]; then
    proxy_domain_array=$(echo "$PROXY_DOMAINS" | tr ";" "\\n")
    for proxy_domain in $proxy_domain_array ; do

      domain="${proxy_domain%%,*}"
      proxy="${proxy_domain##*,}"
      include="${proxy##*+}"
      proxy="${proxy%%+*}"

      if ! [[ "$proxy" =~ ^http:.*|^https:.* ]]; then
        #default to http if not supplied
        proxy="http://${proxy}"
      fi
      if [[ ! -z "${include}" ]]; then
        if [[ -r "/etc/nginx/includes/${include}" ]]; then
          echo "=== include found ${include} ==="
          include="include /etc/nginx/includes/${include};"
        else
          echo "=== include not found ${include}, ignoring ==="
          include=""
        fi
      fi
####"
      echo "### Processing ${domain} ###"

      # prevent empty domains
      if [[ ! -z "${domain}" ]] && [[ ! -z "${proxy}" ]]; then
        if [[ -r "/certs/${domain}/fullchain.pem" ]] && [[ -r "/certs/${domain}/privkey.pem" ]] && [[ -r "/certs/${domain}/chain.pem" ]] ; then
          echo "==== Detected ${domain}: fullchain,privkey,chain ===="
        else
          echo "==== Generating Self-signed certificate and key ===="
          mkdir -p "/certs/${domain}"
          openssl genrsa -des3 -passout pass:x -out "/certs/${domain}/server.pass.key" 2048
          openssl rsa -passin pass:x -in "/certs/${domain}/server.pass.key" -out "/certs/${domain}/privkey.pem"
          rm -f "/certs/${domain}/server.pass.key"
          openssl req -new -key "/certs/${domain}/privkey.pem" -out "/certs/${domain}/server.csr" -subj "/C=UK/ST=Warwickshire/L=Leamington/O=OrgName/OU=eXtremeSHOK.com/CN=${domain}"
          openssl x509 -req -days 3650 -in "/certs/${domain}/server.csr -signkey" "/certs/${domain}/privkey.pem" -out "/certs/${domain}/fullchain.pem"
          rm -f "/certs/${domain}/server.csr"
          cp -f "/certs/${domain}/fullchain.pem" "/certs/${domain}/chain.pem"
          chmod 644 "/certs/${domain}/chain.pem"
          chmod 644 "/certs/${domain}/fullchain.pem"
          chmod 644 "/certs/${domain}/privkey.pem"

          if [[ ! -r "/certs/${domain}/cefullchainrt.pem" ]] || [[ ! -r "/certs/${domain}/privkey.pem" ]] ; then
            echo "Failure: Generating certificate"
            sleep 60
            exit 1
          fi

        fi
        echo "==== Generating Nginx site config "====
        sed  -e "s|TMPL_DOMAIN|${domain}|g" -e "s|TMPL_PROXY|${proxy}|g" -e "s|TMPL_INCLUDE|${include}|g" /etc/nginx/templates/site.conf > "/etc/nginx/sites.d/${domain}"
      fi
    done
  else
    echo "ERROR: missing domain: ${domain} and/or proxy: ${proxy}"
  fi
fi


if ! nginx -t ; then
  echo "FATAL ERROR:"
  nginx -T
fi