FROM httpd:2.4-alpine

COPY httpd.conf /usr/local/apache2/conf/httpd.conf

RUN echo '<!DOCTYPE html><html><body><h1>Internal App Server</h1><p>Apache running on non-standard port.</p><!-- FLAG{apache_on_8888} --></body></html>' > /usr/local/apache2/htdocs/index.html

EXPOSE 8888
