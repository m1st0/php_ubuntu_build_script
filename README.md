# PHP Build Script for Ubuntu

**`php_build_ubuntu.sh`**  
Automates building and installing PHP 8.x from source for testing on Ubuntu flavors with optional MySQL/MariaDB support and Apache integration.

---

## 🚀 About

This script compiles PHP 8.x by version choice from source, installs common extensions (mbstring, GD, curl, LDAP, etc.), and sets up MySQL or MariaDB support. It also configures Apache integration and handles alternative PHP paths.

Built and maintained by Maulik Mistry (m1st0) ([original Gist](https://gist.github.com/m1st0/1c41b8d0eb42169ce71a))

---

## ✅ Features

- Compile PHP 8 from source with popular extensions
- Auto-detect MySQL vs. MariaDB
- Apache module configuration and update-alternatives
- Error-handling and environment setup
- Color-coded script output for clarity

---

## 🛠️ Usage

1. Clone the repo:

```bash
git clone https://github.com/yourusername/php-build-ubuntu.git
cd php-build-ubuntu
```

2. Make executable:

```bash
chmod +x php_build_ubuntu.sh
```

3. Run (may require sudo):

```bash
sudo ./php_build_ubuntu.sh
```

4. Follow the prompts to select PHP version (default is 8.4.9) and confirm compilation options.
5. You may change the default version by obtaining tags from the [php-src repository](https://github.com/php/php-src/tags) or by checking out a version tag inside the `php-src` folder that the script creates on first run, and updating the `PHP_VERSION` variable accordingly.

---

## 📄 License

This project is licensed under the **BSD-2-Clause** license.  
See [`LICENSE.txt`](LICENSE.txt) for full details.

---

## 🙏 Support

If you find this script helpful, consider supporting me:

- **PayPal**: [Paypal](https://www.paypal.com/paypalme/m1st0)
- **Venmo**: [Venmo](https://venmo.com/code?user_id=3319592654995456106&created=1753283702)

_Lets keep each other going, safe, and well._
