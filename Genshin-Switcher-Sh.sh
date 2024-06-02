#!/bin/bash

# Function to display error message and exit
display_error() {
    echo -e "\e[31m脚本运行错误！${BASH_SOURCE[1]}: 第 ${BASH_LINENO[0]} 行: 命令执行出错：$1"
    echo -e "\e[31m请检查权限等是否正确配置，然后重试。"
    exit 1
}

# Trap any error
trap 'display_error "$BASH_COMMAND"' ERR

# Exit immediately if a command exits with a non-zero status
set -e

folders=(
    "com.miHoYo.Yuanshen"
    "com.miHoYo.GenshinImpact"
    "com.miHoYo.ys.bilibili"
    "com.miHoYo.ys.mi"
)

# Define the corresponding options
options=(
    "1. 中国大陆官服"
    "2. 国际服"
    "3. Bilibili 渠道服"
    "4. 小米 渠道服"
)

# Base path
base_path="/storage/emulated/0/Android/data"

echo "================
Genshin-Switcher-Sh
by siergtc
================"
echo -e "\e[32m提示：\e[39m本脚本正常运行需要能正常访问 Android/data 目录。请先检查权限是否正常可用。"
echo -e "\e[31m警告！\e[39m对于使用本脚本可能造成的任何预期外的后果，您需要\e[33m自行承担\e[39m，开发者不负任何责任。"

echo "================
01 选择具有完整数据源的版本
================"
found=false
available_count=0
available_option_index=0
echo "正在检查数据目录..."
# Check for the existence of folders and display options
for i in "${!folders[@]}"; do
    full_path="${base_path}/${folders[$i]}"
    if [ -d "$full_path" ]; then
        echo -e "\e[32m（可用）\e[39m${options[$i]}"
        found=true
        available_count=$((available_count + 1))
        available_option_index=$i
    else
        echo -e "\e[33m（不可用）\e[39m${options[$i]}"
    fi
done

if [ "$found" = false ]; then
    echo -e "\e[31m无可用选项，退出..."
    exit 1
fi

# If only one option is available, automatically select it
if [ "$available_count" -eq 1 ]; then
    echo -e "\e[32m仅有一个可用选项，已自动选中。\e[39m"
    version_number=$((available_option_index + 1))
else
    # Prompt user to choose the version to export
    echo -e "请输入具有完整数据源的版本编号 \e[32m[1 - 4]\e[39m："
    read -p "请输入一个整数：" version_number
    # Check if the entered input is an integer
    if ! [[ "$version_number" =~ ^[0-9]+$ ]]; then
        echo -e "\e[31m输入格式错误，退出..."
        exit 1
    fi

    # Check if the entered version number is valid
    if [ "$version_number" -lt 1 ] || [ "$version_number" -gt "${#options[@]}" ]; then
        echo -e "\e[31m无效选项，退出..."
        exit 1
    fi
fi

# Check if the chosen option is available
chosen_option=$(($version_number - 1))
if [ ! -d "${base_path}/${folders[$chosen_option]}" ]; then
    echo -e "\e[31m选项不可用，退出..."
    exit 1
fi
echo -e "已选择：\e[32m${options[$chosen_option]}\e[39m"

# Prompt user for confirmation before copying
echo "================
02 复制各版本特有文件
================"
echo "建议仅在没有进行过游戏版本更新的情况下跳过此步骤。如果是第一次使用本脚本，请不要跳过此步骤，否则下一步会失败！"
read -p "是否要将各版本特有文件复制到 /storage/emulated/0/Documents/Genshin-Switcher-Sh 目录（如果不存在则自动创建）？ (Y/n): " confirm_copy

# Convert input to lowercase (if any)
confirm_copy=$(echo "$confirm_copy" | tr '[:upper:]' '[:lower:]')

# Check user's response
if [ "$confirm_copy" = "n" ]; then
    echo -e "\e[32m已跳过复制操作。\e[39m"
# If user doesn't provide input or inputs 'y', proceed with copying
elif [ -z "$confirm_copy" ] || [ "$confirm_copy" = "y" ]; then
    # Create directory if it doesn't exist
    mkdir -p "/storage/emulated/0/Documents/Genshin-Switcher-Sh"
    # Loop through available folders and copy them to the new directory, excluding specified folders
    for i in "${!folders[@]}"; do
        if [ -d "${base_path}/${folders[$i]}" ]; then
            destination_folder="/storage/emulated/0/Documents/Genshin-Switcher-Sh/${folders[$i]}"
            if [ -d "$destination_folder" ]; then
                read -p "目标文件夹已存在: $destination_folder。确认自动删除吗？(Y/n): " confirm_delete
                # Convert input to lowercase (if any)
                confirm_delete=$(echo "$confirm_delete" | tr '[:upper:]' '[:lower:]')

                # Check user's response
                if [ "$confirm_delete" = "n" ]; then
                    echo -e "\e[33m操作终止，请手动删除对应文件夹后重新运行脚本。"
                    exit 1
                # If user doesn't provide input or inputs 'y', proceed with deleting
                elif [ -z "$confirm_delete" ] || [ "$confirm_delete" = "y" ]; then
                    echo "正在删除已存在的文件夹: $destination_folder"
                    rm -rf "$destination_folder"
                else
                    echo -e "\e[31m输入无效，退出..."
                    exit 1
                fi
            fi
            echo "正在复制 ${folders[$i]} 中部分内容到 /storage/emulated/0/Documents/Genshin-Switcher-Sh"
            rsync -aq --exclude=files/AssetBundles --exclude=files/AudioAssets --exclude=files/VideoAssets --exclude=files/ctable.dat --exclude=files/revision --exclude=files/BLKVERSION --exclude=files/data_revision --exclude=files/data_versions_persist --exclude=files/res_revision --exclude=files/res_versions_persist --exclude=files/silence_revision --exclude=files/silence_data_versions_persist "${base_path}/${folders[$i]}" "/storage/emulated/0/Documents/Genshin-Switcher-Sh"
        fi
    done
    echo -e "\e[32m复制完成。请不要删除该文件夹中内容。\e[39m"
else
    echo -e "\e[31m输入无效，退出..."
    exit 1
fi

echo "================
03 选择要导入的目标版本
================"
echo "正在检查已保存的目标目录..."
found_import=false

# Check for the existence of target directories in /storage/emulated/0/Documents/Genshin-Switcher-Sh
for i in "${!folders[@]}"; do
    import_path="/storage/emulated/0/Documents/Genshin-Switcher-Sh/${folders[$i]}"
    if [ -d "$import_path" ]; then
        echo -e "\e[32m（可用）\e[39m${options[$i]}"
        found_import=true
    else
        echo -e "\e[33m（不可用）\e[39m${options[$i]}"
    fi
done

if [ "$found_import" = false ]; then
    echo -e "\e[31m未找到已保存的目标目录，退出..."
    exit 1
fi

# Prompt user to choose the target version to import
echo -e "请输入要导入的目标版本编号 \e[32m[1 - 4]\e[39m："
read -p "请输入一个整数：" target_version_number

# Check if the entered input is an integer
if ! [[ "$target_version_number" =~ ^[0-9]+$ ]]; then
    echo -e "\e[31m输入格式错误，退出..."
    exit 1
fi

# Check if the entered target version number is valid
if [ "$target_version_number" -lt 1 ] || [ "$target_version_number" -gt "${#options[@]}" ]; then
    echo -e "\e[31m无效选项，退出..."
    exit 1
fi

# Check if the chosen option is available
if [ ! -d "/storage/emulated/0/Documents/Genshin-Switcher-Sh/${folders[$(($target_version_number - 1))]}" ]; then
    echo -e "\e[31m选项不可用，退出..."
    exit 1
fi

# Check if source version and target version are the same
if [ "$version_number" -eq "$target_version_number" ]; then
    echo -e "\e[33m数据源版本与目标版本相同，无需操作，退出..."
    exit 1
fi

echo -e "已选择要导入的目标版本：\e[32m${options[$(($target_version_number - 1))]}\e[39m"

echo "================
04 导入数据
================"

# Remove existing target version folder if it exists
target_version_folder="${base_path}/${folders[$(($target_version_number - 1))]}"
if [ -d "$target_version_folder" ]; then
    read -p "已发现现有的目标版本文件夹：$target_version_folder，它将被自动移除。确认继续操作吗？(Y/n): " confirm_delete_target
    # Convert input to lowercase (if any)
    confirm_delete_target=$(echo "$confirm_delete_target" | tr '[:upper:]' '[:lower:]')

    # Check user's response
    if [ "$confirm_delete_target" = "n" ]; then
        echo -e "\e[33m操作终止，请手动删除对应文件夹后重新运行脚本。"
        exit 1
    # If user doesn't provide input or inputs 'y', proceed with deleting
    elif [ -z "$confirm_delete_target" ] || [ "$confirm_delete_target" = "y" ]; then
        echo "正在删除现有的目标版本文件夹: $target_version_folder"
        rm -rf "$target_version_folder"
    else
        echo -e "\e[31m输入无效，退出..."
        exit 1
    fi
fi

# Rename the source version folder to the target version folder name
echo "正在重命名数据源文件夹..."
mv "${base_path}/${folders[$(($available_option_index))]}" "$target_version_folder"

# Remove all contents from the renamed folder except specified folders
echo "正在移除文件夹中资源数据外的所有内容..."
find "$target_version_folder/files" -type f \
  -not -path "$target_version_folder/files/AssetBundles/*" \
  -not -path "$target_version_folder/files/AudioAssets/*" \
  -not -path "$target_version_folder/files/VideoAssets/*" \
  -not -path "$target_version_folder/files/ctable.dat" \
  -not -path "$target_version_folder/files/revision" \
  -not -path "$target_version_folder/files/BLKVERSION" \
  -not -path "$target_version_folder/files/data_revision" \
  -not -path "$target_version_folder/files/data_versions_persist" \
  -not -path "$target_version_folder/files/res_revision" \
  -not -path "$target_version_folder/files/res_versions_persist" \
  -not -path "$target_version_folder/files/silence_revision" \
  -not -path "$target_version_folder/files/silence_data_versions_persist" \
  -exec rm -rf {} +
  
# Merge content of selected folder from /storage/emulated/0/Documents/Genshin-Switcher-Sh into target version folder
echo "正在将 /storage/emulated/0/Documents/Genshin-Switcher-Sh 中保存的目标版本文件合并到文件夹中..."
selected_folder="/storage/emulated/0/Documents/Genshin-Switcher-Sh/${folders[$(($target_version_number - 1))]}"
rsync -aq "$selected_folder"/ "$target_version_folder"/
echo -e "\e[32m版本切换完成，感谢使用本脚本。"
