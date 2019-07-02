{% from 'radicale/map.jinja' import radicale with context %}

python-pip:
  pkg.installed:
    - pkgs:
      - python-pip
      - python3-pip
      - git

radicale:
  pip.installed:
    - name: Radicale
    - bin_env: '/usr/bin/pip3'
    - require:
      - pkg: python-pip

radicale-user:
  user.present:
    - name: radicale

radicale-ldap:
  cmd.run:
    - name: "git clone https://github.com/marcoh00/radicale-auth-ldap.git"
    - cwd: /tmp/
    - require:
      - radicale

radicale-ldap-install:
  cmd.run:
    - cwd: /tmp/radicale-auth-ldap
    - name: "python3 setup.py install"
    - require:
      - radicale-ldap

radicale-ldap-cleanup:
  file.absent:
    - name: /tmp/radicale-auth-ldap
    - require:
      - radicale-ldap-install

radicale-storage:
  file.directory:
    - name: {{ radicale.storage }}
    - user: radicale
    - dir_mode: 700
    - require:
      - radicale-user

radicale-config:
  file.managed:
    - name: /etc/radicale/config
    - source: salt://radicale/files/config
    - makedirs: True
    - template: jinja
    - mode: 755
    - defaults:
        storage: {{ radicale.storage | yaml_encode }}
        ldap: {{ radicale.ldap | yaml }}

radicale-logging-config:
  file.managed:
    - name: /etc/radicale/logging
    - source: salt://radicale/files/logging
    - makedirs: True
    - template: jinja
    - mode: 755
    - defaults:
        storage: {{ radicale.storage | yaml_encode }}

radicale-logging-dir:
  file.directory:
    - name: /var/log/radicale
    - user: radicale

radicale-service-config:
  file.managed:
    - name: /etc/systemd/system/radicale.service
    - source: salt://radicale/files/radicale.service
    - template: jinja
    - mode: 755
    - defaults:
        storage: {{ radicale.storage | yaml_encode }}

radicale-service:
  service.running:
    - name: radicale
    - enable: true
    - require:
      - radicale-service-config
      - radicale-config
      - radicale-storage
      - radicale-logging-dir
