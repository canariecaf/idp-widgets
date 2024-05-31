<#
.SYNOPSIS
    Retrieves an SSL/TLS certificate from a specified server and port, then saves it as a PEM encoded certificate file.

.DESCRIPTION
    This function connects to a specified server and port to retrieve the SSL/TLS certificate. 
    It then converts the certificate to PEM format and saves it to the specified output file.

.PARAMETER server
    The DNS name or IP address of the server from which to retrieve the SSL/TLS certificate.
    This parameter is mandatory.

.PARAMETER port
    The port on the server to connect to for retrieving the SSL/TLS certificate.
    The default value is 636.

.PARAMETER outputFile
    The file path where the PEM encoded certificate will be saved.
    The default value is the server name with a .crt extension.

.EXAMPLE
    Get-SSLCert -server "ldap.example.com" -port 636 -outputFile "ldap-server.crt"
.NOTES
    This script ignores certificate validation errors.

    Licensed under the Apache License, Version 2.0 (the "License");
        http://www.apache.org/licenses/LICENSE-2.0

    Software distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    Author: Chris Phillips, chris.phillips@canarie.ca

    Acknowledgement: This script was inspired by a discussion on Reddit:
    https://www.reddit.com/r/PowerShell/comments/7quep4/download_cer_cert_file_from_web_server/

    Change log
    2024-05-30:CP:adaptation created, enhanced to ignore validation for self signed certs,write file out
#>
function Get-SSLCert {
    param(
        [parameter(Mandatory=$true)]
        [string]$server,

        [int]$port=636,

        [string]$outputFile = "$server.crt"
    )

    try {
        $tcpsocket = New-Object Net.Sockets.TcpClient($Server, $port)
        $tcpstream = $tcpsocket.GetStream()
        $sslStream = New-Object System.Net.Security.SslStream($tcpstream, $false, 
            { param($sender, $certificate, $chain, $sslPolicyErrors) return $true }) # Ignore certificate validation
        $sslStream.AuthenticateAsClient($Server)
        $certinfo = New-Object system.security.cryptography.x509certificates.x509certificate2($sslStream.RemoteCertificate)
        
        # Get the certificate in PEM format
        $certBytes = $certinfo.GetRawCertData()
        $certBase64 = [Convert]::ToBase64String($certBytes)
        $pemContent = "-----BEGIN CERTIFICATE-----`n$certBase64`n-----END CERTIFICATE-----"
        
        # Write the PEM encoded certificate to a file
        $pemContent | Out-File -FilePath $outputFile
        
        Write-Output "Certificate saved to $outputFile"
    } catch {           
        Write-Error $_.exception.message
    }
}

# Example usage
# Get-SSLCert -server "example.com" -port 636 -outputFile "example.com.crt"
