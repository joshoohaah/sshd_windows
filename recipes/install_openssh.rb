openssh_dir = 'C:\Program Files\OpenSSH'
pstools_dir = 'C:\tools\pstools'
directory openssh_dir do
  recursive true
  action :create
end


windows_zipfile openssh_dir do
  source 'https://github.com/PowerShell/Win32-OpenSSH/releases/download/v0.0.19.0/OpenSSH-Win64.zip'
  action :unzip
  not_if {::File.exists?(#{openssh_dir}/sshd.exe)}
  notifies :run, 'powershell_script[install ssh_server]', :immediately
end

powershell_script 'install ssh_server' do
  cwd openssh_dir
  code <<-EOH
install-sshd.ps1
.\ssh-keygen.exe -A
.\FixHostFilePermissions.ps1 -Confirm:$false
Start-Service ssh-agent
Set-Service sshd -StartupType Automatic
Set-Service ssh-agent -StartupType Automatic
  EOH
  action :nothing
end


windows_service 'ssh-agent' do
  action :configure_startup
  startup_type [:enable, :start]
end

windows_zipfile pstools_dir do
  source 'https://download.sysinternals.com/files/PSTools.zip'
  action :unzip
#   not_if {::File.exists?(#{openssh_dir}/sshd.exe)}
#   notifies :run, 'powershell_script[install ssh_server]', :immediately
end

powershell_script 'install ssh_server' do
  cwd pstools_dir
  code <<-EOH
.\psexec.exe -i -s cmd.exe
ssh-add ssh_host_dsa_key
ssh-add ssh_host_rsa_key
ssh-add ssh_host_ecdsa_key
ssh-add ssh_host_ed25519_key

  EOH
  action :run
end

powershell_script 'add firewall rule' do
  cwd pstools_dir
  code <<-EOH
New-NetFirewallRule -Protocol TCP -LocalPort 22 -Direction Inbound -Action Allow -DisplayName SSH

  EOH
  action :run
end
