<?php

class Password_hash {
    private $cost = 12; // bcrypt のコスト値（推奨: 10〜12）

    /**
     * パスワードをハッシュ化する
     * @param string $password ユーザーのパスワード
     * @return string ハッシュ化されたパスワード
     */
    public function HashPassword($password) {
        return password_hash($password, PASSWORD_BCRYPT, ['cost' => $this->cost]);
    }

    /**
     * パスワードを検証する
     * @param string $password ユーザーが入力したパスワード
     * @param string $hash 保存されているハッシュ
     * @return bool 検証成功なら true, 失敗なら false
     */
    public function CheckPassword($password, $hash) {
        return password_verify($password, $hash);
    }

    /**
     * ハッシュの再生成が必要かチェックする
     * @param string $hash 現在のハッシュ
     * @return bool 再ハッシュが必要なら true
     */
    public function NeedsRehash($hash) {
        return password_needs_rehash($hash, PASSWORD_BCRYPT, ['cost' => $this->cost]);
    }
}

?>
