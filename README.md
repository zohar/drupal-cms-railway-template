## Deploy Drupal CMS on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/template/JajTQh?referralCode=T4b_Cr)

This template includes a native Railway MySQL database and a configured Drupal service with a mounted volume for `sites/default/files` .

### Optional configuration

The variables are available for the configuration of deployments:
- `DRUPAL_SITE_INSTALL` determines whether or not to run `drush site:install` which initializes a Drupal website. It is reasonable to set this variable to `false` after the first deployment (default: `false`)
- `DRUPAL_RECIPE` determines the recipe to install (default: `standard`)
- `DRUPAL_ADMIN_PASSWORD` Optionally set your admin user password. Leave untouched and one will be generated for you during Build time. The password can be seen at the end of the build log. Note that this value is reset after the deployment, so you should copy it from the logs and not from your service's variables (default: auto-generated)
