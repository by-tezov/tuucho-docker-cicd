- add certificats folder, put your last fullchain.pem and privkey.pem
- add conf folder, put your options-ssl-nginx.conf and ssl-dhparams.pem

- if expired, a new one will be requested, don't forget to change all necessary domain variable
(entrypoint nginx, conf nginx, ...)
- !!! Once a new one has been requested, don't forget to save it from volume to update certificats folder here,
else on each build a new keys will be requested