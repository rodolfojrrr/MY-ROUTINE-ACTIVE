# Assinatura Android fixa

A assinatura é a identidade criptográfica do APK. Para que o Android aceite uma versão nova por cima da antiga, as duas versões precisam usar a mesma chave.

## Configuração única

1. Faça um backup `.mra` se já houver dados importantes no celular.
2. Execute `09_GERAR_ASSINATURA_ANDROID.bat`.
3. Guarde `android\app\mra-release.jks` e a senha em um local seguro fora do GitHub.
4. Abra `ASSINATURA_ANDROID_SECRETS.txt`.
5. No GitHub, entre no repositório → **Settings → Secrets and variables → Actions**.
6. Crie estes quatro Repository secrets com os valores do arquivo:
   - `MRA_KEYSTORE_B64`
   - `MRA_KEYSTORE_PASSWORD`
   - `MRA_KEY_ALIAS`
   - `MRA_KEY_PASSWORD`
7. Execute `07_SUBIR_GITHUB.bat` e baixe o novo APK em Actions.

## Primeira migração

Se o APK instalado anteriormente tiver outra assinatura, o Android poderá recusar a instalação por cima. Nesse caso, confirme primeiro que o backup `.mra` está salvo, desinstale a versão antiga, instale o APK assinado pela chave fixa e importe o backup.

Depois dessa migração, não gere outra chave. Todas as atualizações futuras devem usar a mesma `mra-release.jks` e os mesmos Secrets.

## Segurança

`.jks` e `ASSINATURA_ANDROID_SECRETS.txt` estão no `.gitignore`. Nunca faça commit deles.
