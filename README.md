
### Создаем кластер k8s в proxmox при помощи tofu
1 мастер, 3 воркера

OpenTofu v1.7.1,

Proxmox 8.2.2

Используется:

- Debian 12 (Bookworm)
- Kubeadm 
- Cilium


При проблемах с аутификацей
***
eval "$(ssh-agent -s)"  # Запуск ssh-agent, если он не запущен

ssh-add -L  # Проверка загруженных ключей

ssh-add /path/to/private/key  # Добавление ключа, если его нет в списке