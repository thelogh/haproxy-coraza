# WAF Configuration Guide with Coraza-spoa and HAProxy v2.4.22 on Ubuntu Server 22.04 LTS.
## Basic version:
Basic example configuration Familiarize yourself with the OWASP ModSecurity Core Rule Set (CRS) 4.0, Coraza, and HAProxy rules.
The complete guide with step-by-step instructions for the basic installation of Coraza-spoa based on Coraza WAF v3.0.1 is available here: https://www.alldiscoveries.com/installation-and-configuration-haproxy-v2-4-22-with-waf-coraza-spoa-on-ubuntu-server-22-04-lts/
I also created an automatic installation script **"[install-coraza_basic.sh](https://github.com/thelogh/haproxy-coraza/blob/main/install-coraza_basic.sh)"** with basic Coraza-Spoa configuration for haproxy on Ubuntu Server 22.04, it can be installed on a clean machine for testing.
## Advanced version:
Advanced configuration for real use on multiple domains, with customized configurations based on the requested domain, with in addition specific plugins for the WordPress site based on OWASP ModSecurity Core Rule Set (CRS) 4.0.
