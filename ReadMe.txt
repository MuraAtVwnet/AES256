◆ AES256 ファイル暗号/復号 ◆

■ これは何?
AES 256 共通鍵暗号を使ってファイルを暗号/復号します

■ 動作環境は?
PowerShell 3.0 以降環境で動作します

確認したバージョンは以下の通り

    3.0 (Windows 7)
    5.1 (Windows 10)
    6.0 beta 9(Windows 10)

■ 使用方法
・共通鍵の作成
以下スクリプトに共通鍵のフルパスを与えると、ランダムな 256 bit の共通鍵を生成します(Base64 でエンコード)

    Make256Key.ps1 共通鍵のフルパス

・暗号化
以下スクリプトに、暗号化するファイルのパス(又は Get-ChildItem で得られる fileinfo)と共通鍵のフルパス又は Base64 文字列(-KeyBase64)を与えると、AES256 で暗号化したファイルを作成します(拡張子 .enc)
暗号化するファイルは複数指定できます。

    AES256.ps1 -Encrypto -KeyPath 共通鍵のフルパス -OutPath 出力先フォルダ(省略可) -Path 暗号化するファイル
    AES256.ps1 -Encrypto -KeyBase64 Base64共通鍵 -OutPath 出力先フォルダ(省略可) -Path 暗号化するファイル

・復号化
以下スクリプトに、復号化するファイルのパス(又は Get-ChildItem で得られる fileinfo)と共通鍵のフルパス又は Base64 文字列(-KeyBase64)を与えると、復号ファイルを作成します(注意:既存ファイルがあれば上書き)
復号化するファイルは複数指定できます。

    AES256.ps1 -Decrypto -KeyPath 共通鍵のフルパス -OutPath 出力先フォルダ(省略可) -Path 復号化するファイル
    AES256.ps1 -Decrypto -KeyBase64 Base64共通鍵 -OutPath 出力先フォルダ(省略可) -Path 復号化するファイル

■ 実行例
・鍵ファイルを指定して暗号化
    PS C:\Script\aes256> .\AES256.ps1 -Encrypto -KeyPath "C:\Key\Shared.key" -Path "C:\Data\TestData.txt"

・複数ファイルを暗号化
    PS C:\Script\aes256> $EncFiles = dir C:\Data
    PS C:\Script\aes256> .\AES256.ps1 -Encrypto -KeyPath "C:\Key\Shared.key" -Path $EncFiles

・Base64鍵を指定して復号化
    PS C:\Script\aes256> .\AES256.ps1 -Decrypto -KeyBase64 "X6iFs1i1wB1nFJaRxAM3PuzduvRS/Kyh8+cfcE+7FxA=" -Path "C:\Data\TestData.txt.enc"

・共通鍵を作成
    PS C:\Script\aes256> .\Make256Key.ps1 "C:\Key\Shared.key"

■ 注意事項
AES256 のストリーミングを使わず、オンメモリーで暗号/復号しています。
このため、でかいファイルを暗号/復号する場合は、メモリーに余裕のある環境での実行をお勧めします。
