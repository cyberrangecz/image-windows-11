:: Configuring Power Options for Virtual Machine
:: Commands will be displayed in the console

powercfg -change -monitor-timeout-ac 0

powercfg -change -standby-timeout-ac 0

powercfg -change -hibernate-timeout-ac 0

:: Completely disable hibernation and remove hiberfile.sys
powercfg -h off
