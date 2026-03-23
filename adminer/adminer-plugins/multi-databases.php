<?php

/**
 * A plugin for Adminer that supports independent account configuration for database connections.
 *
 * @link https://github.com/xuanyan/adminer-multi-databases
 * @author Yan Xuan, https://out-man.top
 */

namespace Adminer;

class MultiDatabases extends Plugin {
    private $databases;
  
    public function __construct($config) {
        $this->databases = $config;
    }
    function name() {
        // custom name in title and heading
        return @$this->databases[@$_GET['username']]['desc'];
    }

    function credentials() {
      return @$this->databases[@$_GET['username']]['dsn'];
    }

    function login($login, $password) {

      return ($password == @$this->databases[@$_GET['username']]['password']);
    }

    function loginForm() {
        $databases = [];
        $quickSelect = [
          '' => ''
        ];
        foreach ($this->databases as $name => $config) {
            $databases[$name] = @$config['database'];
            if (empty($config['password'])) {
                $quickSelect[$name] = $name;
            }
        }
        count($quickSelect) == 1 && $quickSelect = [];
?>
<table class='layout'>
  <?= input_hidden('auth[driver]', DRIVER); ?>
  <?= input_hidden('auth[db]', ''); ?>
  <?php if ($quickSelect) { echo adminer()->loginFormField('quick-select', '<tr><th>'.lang('select').'<td>', html_select('mySelect', $quickSelect));} ?>
  <?= adminer()->loginFormField('username', '<tr><th>'.lang('Username').'<td>', '<input name="auth[username]" id="username" autofocus value="'.h($_GET["username"]).'" autocomplete="username" autocapitalize="off">'); ?>
  <?= adminer()->loginFormField('password', '<tr><th>'.lang('Password').'<td>', '<input type="password" name="auth[password]" autocomplete="current-password">'); ?>
</table>
<p><input id="myLogin" type="button" value="<?=lang('Login'); ?>"></p>
<script<?= nonce(); ?>>
var databases = <?= json_encode($databases); ?>;
qs('select[name="mySelect"]').onchange = function() {
  var username = qs('select[name="mySelect"]').value;
  qs('input[name="auth[username]"]').value = username;
  if (username != '') {
    qs('#myLogin').click();
  }
};
qs('#myLogin').onclick = function() {
  var username = qs('input[name="auth[username]"]').value;
  qs('input[name="auth[db]"]').value = databases[username] ? databases[username] : '';
  qs('form').submit();
};
qs('input[name="auth[password]"]').onkeydown = function(e) {
  if (e.keyCode == 13) {
    qs('#myLogin').click();
  }
}
</script>
<?php
        return true;
    }
}