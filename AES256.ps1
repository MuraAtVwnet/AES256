##################################################
# AES256 暗号/復号
##################################################
Param(
	[switch]$Encrypto,	# 暗号化
	[switch]$Decrypto,	# 復号化
	$KeyPath,			# 共通鍵ファイルの Path
	$KeyBase64,			# 共通鍵(Base64)
	[array]$Path		# 処理対象ファイル
)

# 暗号ファイルの拡張子
$ExtName = "enc"

# AES 定数
$AES_KeySize = 256
$AES_BlockSize = 128
$AES_IVSize = $AES_BlockSize / 8
$AES_Mode = "CBC"
$AES_Padding = "PKCS7"

##################################################
# Base64 をバイト配列にする
##################################################
function Base642Byte( $Base64 ){
	$Byte = [System.Convert]::FromBase64String($Base64)
	return $Byte
}

##################################################
# AES 暗号化
##################################################
function AESEncrypto($ByteKey, $BytePlain){

	if( $ByteKey.Length * 8 -ne $AES_KeySize ){
		echo "[FAIL] Key size error"
		return $null
	}

	# アセンブリロード
	Add-Type -AssemblyName System.Security

	# AES オブジェクトの生成
	$AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider

	# 各値セット
	$AES.KeySize = $AES_KeySize
	$AES.BlockSize = $AES_BlockSize
	$AES.Mode = $AES_Mode
	$AES.Padding = $AES_Padding

	# IV 生成
	$AES.GenerateIV()

	# 生成した IV
	$IV = $AES.IV

	# 鍵セット
	$AES.Key = $ByteKey

	# 暗号化オブジェクト生成
	$Encryptor = $AES.CreateEncryptor()

	# 暗号化
	$EncryptoByte = $Encryptor.TransformFinalBlock($BytePlain, 0, $BytePlain.Length)

	# IV と暗号化した文字列を結合
	$DataByte = $IV + $EncryptoByte

	# オブジェクト削除
	$Encryptor.Dispose()
	$AES.Dispose()

	return $DataByte
}

##################################################
# AES 復号化
##################################################
function AESDecrypto($ByteKey, $ByteEncrypto){

	if( $ByteKey.Length * 8 -ne $AES_KeySize ){
		echo "[FAIL] Key size error"
		return $null
	}

	# IV を取り出す
	$IV = @()
	for( $i = 0; $i -lt $AES_IVSize; $i++){
		$IV += $ByteEncrypto[$i]
	}

	# アセンブリロード
	Add-Type -AssemblyName System.Security

	# オブジェクトの生成
	$AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider

	# 各値セット
	$AES.KeySize = $AES_KeySize
	$AES.BlockSize = $AES_BlockSize
	$AES.Mode = $AES_Mode
	$AES.Padding = $AES_Padding

	# IV セット
	$AES.IV = $IV

	# 鍵セット
	$AES.Key = $ByteKey

	# 復号化オブジェクト生成
	$Decryptor = $AES.CreateDecryptor()

	try{
		# 復号化
		$DecryptoByte = $Decryptor.TransformFinalBlock($ByteEncrypto, $AES_IVSize, $ByteEncrypto.Length - $AES_IVSize)
	}
	catch{
		$DecryptoByte = $null
	}

	# オブジェクト削除
	$Decryptor.Dispose()
	$AES.Dispose()

	return $DecryptoByte
}

##################################################
# main
##################################################
$PsMajorVertion = $PSVersionTable.PSVersion.Major
if( $PsMajorVertion -le 2 ){
	echo "[FAIL] PowerSehll 2.0 以下はサポートしていません"
	exit
}

if( $Path -eq $null ){
	echo "Usage..."
	echo " .\aes256.ps1 [-Encrypto|-Decrypto] [-KeyPath KeyFilePath|-KeyBase64 KeyText] -Path InputFilePath(s)"
	exit
}

# 鍵指定
if( ($KeyPath -eq $null) -and `
	($KeyBase64 -eq $null)){
	echo "[FAIL] Set -KeyPath or KeyBase64"
	exit
}

# 暗号/復号オプション
if( (($Encrypto -eq $fals) -and ( $Decrypto -eq $false)) -or `
	(($Encrypto -eq $true) -and ( $Decrypto -eq $true))){
	echo "[FAIL] select -Encrypto or -Decrypto"
	exit
}

### 鍵読み込み
# ファイルを読む
if( $KeyPath -ne $null ){

	if( -not (Test-Path $KeyPath )){
		echo "[FAIL] $KeyPath not found."
		exit
	}

	$Base64Key = Get-Content $KeyPath
}
# 引数に指定された値を使う
else{
	$Base64Key = $KeyBase64
}

$ByteKey = Base642Byte $Base64Key
if( $ByteKey -eq $null ){
	echo "[FAIL] 鍵エラー"
	exit
}


foreach($TergetFile in $Path){
	# 文字列の場合
	if( $TergetFile.GetType().Name -eq "String" ){
		# フルパスにする
		$TergetFileName = Convert-Path $TergetFile -ErrorAction SilentlyContinue
	}
	# fileinfo
	elseif( $TergetFile.GetType().Name -eq "FileInfo" ){
		$TergetFileName = $TergetFile.FullName
	}
	# 意図しないデータ
	else{
		echo "[ERROR] $TergetFile is bad data."
		continue
	}

	# 正常にフルパスが取れなかった
	if( $TergetFileName -eq $null ){
		echo "[ERROR] $TergetFile is not file name."
		continue
	}

	# Data
	if( -not (Test-Path $TergetFileName )){
		echo "[ERROR] $TergetFileName not found."
		continue
	}

	# 暗号化
	if( $Encrypto ){

		echo "[INFO] Encrypto : $TergetFileName"

		# 暗号化ファイル名
		$EncryptoFileName = $TergetFileName + "." + $ExtName

		# データファイル読み込み
		$BytePlainData = [System.IO.File]::ReadAllBytes($TergetFileName)

		# 暗号
		$ByteEncryptoData = AESEncrypto $ByteKey $BytePlainData
		if( $ByteEncryptoData -eq $null ){
			echo "[FAIL] 暗号失敗"
			exit
		}

		# ファイル出力
		[System.IO.File]::WriteAllBytes($EncryptoFileName, $ByteEncryptoData)
	}
	# 復号化
	else{
		# 拡張子確認
		if( $TergetFileName -notmatch "$ExtName$" ){
			echo "[ERROR] $TergetFileName は暗号化ファイルではない"
			continue
		}

		echo "[INFO] Decrypto : $TergetFileName"

		# 復号ファイル名
		$ChangeString = "."+ $ExtName
		$DecryptoFileName = $TergetFileName.Replace($ChangeString,"")

		# 暗号化ファイル読み込み
		$ByteEncryptoData = [System.IO.File]::ReadAllBytes($TergetFileName)

		# 復号
		$BytePlainData = AESDecrypto $ByteKey $ByteEncryptoData
		if( $BytePlainData -eq $null ){
			echo "[ERROR] 復号失敗"
			continue
		}

		# 平文ファイル出力
		[System.IO.File]::WriteAllBytes($DecryptoFileName, $BytePlainData)
	}
}
