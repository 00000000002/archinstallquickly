    red='\033[1;31m'; green='\033[1;32m'  
    yellow='\033[1;33m'; blue='\033[1;36m'  
    white='\033[1;37m'; suffix='\033[0m'  
    whites='\033[1;30m';   
    #-----------------------------#
    # rw='\033[1;41m'  #--红白
    wg='\033[1;42m'; ws='\033[1;43m'      #白绿 \ 白褐
    #wb='\033[1;44m'; wq='\033[1;45m'    #白蓝 \ 白紫
    # wa='\033[1;46m';  #白青
    bx='\033[1;4;36m' # 蓝 下划线
printf "         _                              
                | |                             
 __  __ _ __  __| | _ __  ___   __ _  _ __ ___  
 \ \/ /|  __|/ _  ||  __|/ _ \ / _  || _  _   \ 
  >  < | |  | (_| || |  |  __/| (_| || | | | | |
 /_/\_\|_|   \__,_||_|   \___| \__,_||_| |_| |_|                                                                                                                        
${white}         _             _       _     _                           
${green}        / \   _ __ ___| |__   | |   (_)_ __  _%s   
${blue}       / _ \ | '__/ __| '_ \  | |   | | '_ \| | | \ \/ /    
${yellow}      / ___ \| | | (__| | | | | |___| | | | | |_| |>  <   
${red}     /_/   \_\_|  \___|_| |_| |_____|_|_| |_|\__,_/_/\_\ 
${bx}-----------------------  Auins Info  ------------------------${suffix}
%s
%s
%s
${red}--=--*--=--*--=--*--=--*--=--=*=--=--*--=--*--=--*--=--*--=--${suffix}" \

## 在使用此脚本之前需先确认以下条目:
## 首先查看安装设备是否名为 sda，若不是需将脚本中出现的 sda 全部替换为对应设备名
## 脚本的主机名为 arch，用户名为 wine，源地址为 ustc，微码为 amd-ucode 若有需要自行替换

## 同步网络时钟
time datectl set-ntp true

## 注意分区磁盘是否为 sda，若不是需要更改。
cfdisk /dev/sda

## 注意分区为三个对应 /boot  swap  / 需按顺序分区，分区磁盘是否为 sda，若不是需更改。
## 格式化
mkswap /dev/sda2   #swap
mkfs.fat -F 32 /dev/sda1 #EFI分区
mkfs.ext4 /dev/sda3

## 挂载
mount /dev/sda3 /mnt

mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

swapon /dev/sda2

## 更换下载源地址，留意需转义的字符要使用反斜杠 \
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
echo "Server = https://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
pacman -Syy

## 通过 pacstrap 安装相应的包，注意 cpu 微码，写入 fstab
## base base-devel linux linux-firmware vim grub efibootmgr networkmanager amd-ucode
#pacstrap /mnt base base-devel linux linux-firmware vim grub efibootmgr networkmanager amd-ucode

pacstrap -K /mnt base linux linux-firmware base-devel
genfstab -U /mnt >> /mnt/etc/fstab
## 本地化配置，注意要切换用户 arch-chroot
## 设置时区，同步硬件时钟，设置语言
arch-chroot /mnt bash -c "ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && hwclock --systohc && sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen && echo 'LANG=en_US.UTF-8' > /etc/locale.conf && exit"

## 设置主机名为 arch，配置 hosts，>> 两个 > 代表 从文件的最后添加，一个 > 代表，删除文件内容后添加
arch-chroot /mnt bash -c "echo arch > /etc/hostname && exit"

## 添加用户 wine 到用户组 wheel，并提权
arch-chroot /mnt bash -c "useradd -m wine && passwd wine && exit"

## 安装 grub
arch-chroot /mnt bash -c "pacman -Sy && grub-install --target=i386-pc /dev/sda && grub-mkconfig -o /boot/grub/grub.cfg && exit"

## 启动相应的服务
## NetworkManager
## bluetooth
## cups.service
## sshd
## fstrim.timer
## libvirtd
## firewalld
## acpid
## 例如：systemctl enable NetworkManager && systemctl enable bluetooth
arch-chroot /mnt bash -c "systemctl enable NetworkManager && exit"

## 取消挂载
umount -R /mnt


## 注意要移除安装介质后再重启
echo "Done! Reboot!"