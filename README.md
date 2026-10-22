<!--
SPDX-FileCopyrightText: Copyright (c) 2019–2026 Maulik Mistry
SPDX-License-Identifier: Apache-2.0
-->
# PHP Build Script for Ubuntu

**`php_build_ubuntu.sh`**

Automates building and installing PHP 8.x from source for independent developer
testing on Ubuntu flavors, with optional MySQL/MariaDB support and Apache 
integration.

**Development history and compatibility**

The Git commit history documents the project's development and version-specific
changes per Ubuntu release, Apache version, PHP version, and selected build 
options.

**Important considerations**

This script compiles PHP 8.x from source, builds common extensions such as 
mbstring, GD, cURL, and LDAP, and configures MySQL or MariaDB support. It also 
configures Apache integration and handles Ubuntu's `update-alternatives` paths. 
Run it in a virtual machine or another non-production environment first,
particularly when testing PHP versions or configuration changes. Review the 
script before running it and back up any existing configuration you need to 
preserve.

**Scope**

This project is intended for local development and testing by independent 
developers. It is not a substitute for official security updates or a guarantee
of production readiness. We can discuss CI/CD and automated testing separately,
of course.

Author: Maulik Mistry

Please share support:

- **PayPal**: [Paypal](https://www.paypal.com/paypalme/m1st0)
- **Venmo**: [Venmo](https://venmo.com/code?user_id=3319592654995456106&created=1753283702)

## ✅ Features

- Compile PHP 8.x from source with popular extensions
- Auto-detect MySQL vs. MariaDB
- Apache module configuration and `update-alternatives`
- Some error-handling and environment setup

## 🛠️ Usage

1. Clone the repo:

    ```bash
    git clone --recurse-submodules https://github.com/m1st0/php_ubuntu_build_script php_ubuntu_build_script
    cd php_ubuntu_build_script
    ```

    If the project was already cloned without its submodules:

    ```bash
    git submodule update --init --recursive
    ```

2. Make executable:

    ```bash
    chmod +x php_build_ubuntu.sh
    ```

3. Run (may require sudo):

    ```bash
    ./php_build_ubuntu.sh
    ```

4. You may change the default version by obtaining tags from the 
    [php-src repository](https://github.com/php/php-src/tags) and updating the `PHP_VERSION` variable accordingly.

## 📄 License

This project is licensed under **Apache License 2.0**. See [`LICENSE.txt`](LICENSE.txt) for full 
details.
