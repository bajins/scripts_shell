#!/bin/bash
# Shebang: 这是一个特殊的指令，告诉操作系统使用哪个解释器来执行这个脚本。
# `/bin/bash` 表示使用 Bash shell。

# ==============================================================================
# Hybrid Git Project Batch Processor (教科书级全面注释版)
#
# 功能:
#   该脚本是一个强大的工具，支持两种运行模式，使其兼具易用性和自动化能力。
#
#   1. 交互模式 (Interactive Mode):
#      - 触发方式: 直接运行脚本，不带任何命令行参数。
#      - 特点: 脚本会像一个向导一样，一步步提示用户输入所需信息，如Token、目录等。
#      - 优点: 非常适合手动操作，用户无需记忆复杂的参数顺序。
#
#   2. 参数模式 (Argument/Scripting Mode):
#      - 触发方式: 运行时在脚本名后跟随参数。
#      - 特点: 脚本会直接使用提供的参数执行，不会有任何交互提示。
#      - 优点: 非常适合集成到其他自动化脚本、CI/CD流水线或定时任务(cron job)中。
#
# --- 用法 ---
#
# 1. 交互模式 (最简单的用法):
#   ./git_pull.sh
#
# 2. 参数模式 (用于自动化):
#   ./git_pull.sh <TOKEN> [DIRECTORY] [PROXY]
#
#   参数详细说明:
#     <TOKEN>:      (必须) 新的 GitHub Token。
#                   特别地，如果你不想执行Token替换操作，请在此位置传入字符串 "none"。
#                   这是一个预设的关键字，用于跳过Token替换逻辑。
#
#     [DIRECTORY]:  (可选) 要扫描的目标目录。如果省略此参数，脚本将默认使用当前工作目录 ("./")。
#
#     [PROXY]:      (可选) 要为Git设置的代理地址。
#                   例如: "socks5://127.0.0.1:10808" 或 "http://user:pass@host:port"。
#                   如果省略此参数，则不设置任何代理。
#
#   参数模式示例:
#     # 场景A: 替换Token，在指定目录 /data/projects 中操作，并设置代理
#     ./git_pull.sh ghp_yourSecretToken123 /data/projects socks5://127.0.0.1:10808
#
#     # 场景B: 只想对当前目录下的所有项目执行 git pull (不替换Token，不设置代理)
#     ./git_pull.sh none
#
#     # 场景C: 替换Token，但在当前目录操作
#     ./git_pull.sh ghp_yourSecretToken123
#
# ==============================================================================


# --- 第 1 部分: 模式选择与配置获取 ---
# 这里的核心是判断脚本是如何被调用的，并据此获取配置信息。

# `$#` 是一个Bash的特殊变量，它存储了传递给脚本的命令行参数的数量。
# `if [ "$#" -eq 0 ]` 这句代码的意思是: "如果参数的数量等于0"。
# `-eq` 是用于整数比较的 "equal" 操作符。
if [ "$#" -eq 0 ]; then
    # --- 分支 A: 交互模式 ---
    # 如果没有提供任何参数，脚本将进入此代码块，与用户进行交互。
    
    echo "未检测到参数，进入交互模式..."
    echo "-------------------------------------------------"

    # 1.1: 获取Token
    echo "请输入新的 GitHub Token (如果不需要替换，请直接按 Enter):"
    # `read` 命令用于从标准输入读取用户输入。
    # -s (silent): 使输入内容不显示在屏幕上。这是处理密码、Token等敏感信息的最佳实践。
    # -p (prompt): 在同一行显示提示信息，而不是在新的一行。
    read -sp "新 Token: " NEW_TOKEN_INPUT
    # `read -s` 不会自动换行，所以我们手动 `echo` 一个空行来改善终端输出的格式。
    echo ""

    # 1.2: 获取目标目录
    read -p "请输入要扫描的目标目录 [默认为当前目录 '.']: " TARGET_DIR_INPUT

    # 1.3: 获取代理地址
    echo "请输入要设置的 Git 代理 (如果不需要，请直接按 Enter):"
    read -p "代理地址 (例如 socks5://127.0.0.1:10808): " PROXY_URL_INPUT
    echo ""

    # 1.4: 处理交互式输入，设置变量
    # `${VAR:-default}` 是Bash强大的 "参数扩展" 功能。
    # 它的意思是：如果变量 `VAR` 已设置且非空，则使用它的值；否则，使用 `default` 值。
    # 这里，如果用户对Token直接按了回车 (`NEW_TOKEN_INPUT`为空)，`NEW_TOKEN` 就会被设置为 "none"。
    NEW_TOKEN="${NEW_TOKEN_INPUT:-none}"
    # 同理，如果用户对目录直接按了回车，`TARGET_DIR` 就会被设置为 "." (当前目录)。
    TARGET_DIR="${TARGET_DIR_INPUT:-.}"
    # 代理URL直接使用用户的输入，如果为空，则变量也为空。
    PROXY_URL="$PROXY_URL_INPUT"

    # 1.5: 操作前最终确认，这是一个非常重要的安全特性。
    echo "--- 请确认您的操作 ---"
    echo "  目标目录: $TARGET_DIR"
    if [ "$NEW_TOKEN" != "none" ]; then
        echo "  Token 操作: 将替换为新的 Token (输入已隐藏)"
    else
        echo "  Token 操作: 跳过替换"
    fi
    # `-n` 是一个测试操作符，检查字符串的长度是否非零 (即，字符串不为空)。
    if [ -n "$PROXY_URL" ]; then
        echo "  Git 代理:   将设置为 $PROXY_URL"
    else
        echo "  Git 代理:   不设置"
    fi
    echo "-------------------------------------------------"
    
    read -p "是否继续执行? (y/N): " CONFIRM
    # `tr` (translate) 命令用于字符转换。这里我们将用户输入全部转为小写，
    # 这样后续的判断就不用同时检查 'y' 和 'Y' 了，使代码更健壮。
    CONFIRM_LOWER=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')
    
    # `[[ ... ]]` 是一个更现代、更强大的条件表达式，比 `[ ... ]` 更推荐使用。
    # 它能更好地处理变量为空或包含特殊字符的情况。
    if [[ "$CONFIRM_LOWER" != "y" && "$CONFIRM_LOWER" != "yes" ]]; then
        echo "操作已取消。"
        exit 0 # `exit 0` 表示脚本正常、成功地退出。
    fi

else
    # --- 分支 B: 参数模式 ---
    # 如果脚本收到了一个或多个参数，则进入此代码块。

    echo "检测到参数，进入参数模式..."
    
    # 2.1: 直接从位置参数解析配置
    # `$1`, `$2`, `$3`... 是位置参数，分别代表第一个、第二个、第三个参数。
    NEW_TOKEN="$1"                  # 第一个参数总是Token或"none"
    TARGET_DIR="${2:-.}"            # 第二个参数是目录，如果未提供(即$2为空)，则默认为"."
    PROXY_URL="$3"                  # 第三个参数是代理地址，如果未提供，则为空字符串。

fi


# --- 第 2 部分: 执行前最终检查与汇总 (对两种模式都通用) ---
# 无论配置来自交互还是参数，都会在这里进行最后的检查和展示。

# 2.1: 验证目标目录的有效性。
# `!` 是逻辑"非"。`-d` 是文件测试操作符，检查路径是否存在且是一个目录。
# `[ ! -d "$TARGET_DIR" ]` 意为 "如果 '$TARGET_DIR' 不是一个目录"。
# 变量用双引号包围是一个极其重要的习惯，可以防止因路径中包含空格或特殊字符而导致脚本出错。
if [ ! -d "$TARGET_DIR" ]; then
    echo "错误: 目标目录 '$TARGET_DIR' 不存在或不是一个有效的目录。"
    exit 1 # `exit 1` (或任何非零数字) 表示脚本因错误而中止。
fi

# 2.2: 向用户展示最终将要执行的配置。
echo ""
echo "================================================="
echo "准备执行操作，最终配置如下:"
echo "  目标目录: $TARGET_DIR"

if [ "$NEW_TOKEN" != "none" ]; then
    echo "  Token 操作: 将替换 Token"
else
    echo "  Token 操作: 已跳过"
fi

if [ -n "$PROXY_URL" ]; then
    echo "  Git 代理:   将设置为 $PROXY_URL"
else
    echo "  Git 代理:   不设置"
fi
echo "================================================="
echo ""

# 2.3: 在参数模式下提供一个缓冲时间。
# 这给自动化场景中的用户一个最后的机会，如果发现参数错误，可以按 Ctrl+C 来中止脚本。
if [ "$#" -gt 0 ]; then # `-gt` 是 "greater than"，如果参数数量大于0
    echo "将在 3 秒后开始执行..."
    sleep 3
fi


# --- 第 3 部分: 主逻辑 - 查找并处理所有 Git 项目 ---
# 这是脚本的核心执行部分，对两种模式都通用。

# 使用 `find | while read` 管道是处理文件列表的黄金标准，非常健壮。
# -------------------------------------------------------------------------
# `find "$TARGET_DIR" -type d -name ".git"`:
#   - `find`: 在文件系统中查找文件和目录。
#   - `"$TARGET_DIR"`: 从指定的目录开始递归查找。
#   - `-type d`: 只查找类型为目录 (directory) 的对象。
#   - `-name ".git"`: 查找名字完全匹配 ".git" 的目录。
#
# `|` (管道):
#   - 将 `find` 命令的输出（每个找到的.git目录路径，每行一个）作为下一个命令的输入。
#
# `while read -r git_dir`:
#   - `while`: 循环，只要管道中还有数据就一直执行。
#   - `read`: 读取一行输入并赋值给变量。
#   - `-r`: (raw) 选项，至关重要。它防止`read`命令解释路径中的反斜杠字符，确保路径的完整性。
#   - `git_dir`: 变量名，在每次循环中存储当前处理的 `.git` 目录的完整路径。
#
# 这种方法远优于 `for file in $(ls ...)`，因为后者在处理带空格或特殊字符的文件名时会出错。
# -------------------------------------------------------------------------
find "$TARGET_DIR" -type d -name ".git" | while read -r git_dir; do
    # `dirname` 命令用于获取一个路径的父目录部分。
    # 例如，如果 `git_dir` 是 "/path/to/my-project/.git"，`project_dir` 就会是 "/path/to/my-project"。
    project_dir=$(dirname "$git_dir")
    
    echo "--- 正在处理项目: $project_dir ---"

    # --- 任务 A: 替换 Token ---
    if [ "$NEW_TOKEN" != "none" ]; then
        config_file="${project_dir}/.git/config"
        if [ -f "$config_file" ]; then # `-f` 检查文件是否存在且为普通文件
            # `grep -q` 是一个高效的检查方式。
            # `-q` (quiet) 选项让`grep`不打印任何匹配结果，而是通过退出状态码来表明是否找到匹配。
            # 如果找到，退出码为0 (true)；否则为非0 (false)。非常适合在 `if` 语句中使用。
            if grep -q "https://ghp_.*@" "$config_file"; then
                # `sed` (Stream EDitor) 用于流式文本编辑。
                # `-i.bak`: 这是 `sed` 的一个安全特性。`-i` 表示直接修改文件 (in-place)。
                #           后缀 `.bak` 表示在修改前，自动创建一个名为 `config.bak` 的备份文件。
                # `s|regex|replacement|g`: 这是替换命令。
                #   - `s`: substitute (替换)。
                #   - `|`: 分隔符。通常用 `/`，但当内容中包含 `/` (如URL)时，用其他字符如`|`或`#`可避免复杂的转义。
                #   - `https://ghp_[a-zA-Z0-9]\+@`: 要匹配的正则表达式。`\+`匹配前一个字符集一次或多次。
                #   - `https://${NEW_TOKEN}@`: 替换后的字符串。
                #   - `g`: global，替换行内所有匹配项，而不仅仅是第一个。
                sed -i.bak "s|https://ghp_[a-zA-Z0-9]\+@|https://${NEW_TOKEN}@|g" "$config_file"
                echo "  [Token]  成功替换 Token。"
            else
                echo "  [Token]  未找到旧 Token 格式 (ghp_...)，无需替换。"
            fi
        else
            echo "  [警告] 未找到 .git/config 文件，跳过 Token 替换。"
        fi
    fi

    # --- 任务 B: Git 操作 ---
    # `( ... )` 创建一个子 shell (subshell)。
    # 这是一个极其重要的技巧：在子 shell 中执行的所有命令，如 `cd`，都只影响子 shell 内部的环境。
    # 当子 shell 结束时，主脚本的当前工作目录不会有任何改变。这保证了循环的稳定性。
    (
        # `cd "$project_dir" || exit 1`: 这是一个健壮的目录切换命令。
        # `||` 是逻辑 "OR"。它表示：如果 `cd` 命令执行失败（例如目录不存在或无权限），
        # 则 (`||` 后面的命令) `exit 1` 将被执行，立即终止这个子 shell，防止后续的 git 命令在错误的目录中运行。
        cd "$project_dir" || exit 1
        
        echo "  [Info]   当前远程仓库信息:"
        # `git remote -v` 的输出通过管道传给 `sed`，在每行的开头(`^`)插入几个空格，以实现美观的缩进。
        git remote -v | sed 's/^/           /'

        if [ -n "$PROXY_URL" ]; then
            git config remote.origin.proxy "$PROXY_URL"
            echo "  [Proxy]  已为 origin 设置代理: $PROXY_URL"
        fi

        echo "  [Pull]   正在执行 git pull..."
        # `if command; then...`: 这个结构检查的是 `command` 的退出状态码。成功为0，失败为非0。
        # `git_pull_output=$(git pull 2>&1)`:
        #   - `2>&1`: 这是重定向。它将标准错误流(stderr, 文件描述符2)合并到标准输出流(stdout, 文件描述符1)。
        #             这样，无论是成功信息还是错误信息，都会被捕获。
        #   - `$(...)`: 这是命令替换。Shell会执行括号内的命令，并将其全部输出捕获到变量 `git_pull_output` 中。
        # 整个 `if` 语句的判断依据是 `git pull` 的退出码，而 `git_pull_output` 变量则保存了它的输出，供后续使用。
        if git_pull_output=$(git pull 2>&1); then
            echo "  [Pull]   成功更新。"
        else
            echo "  [Pull]   !!! 更新失败 !!!"
            # 如果更新失败，打印之前捕获的详细输出，方便用户诊断问题。
            echo "-------------------- Git 输出 --------------------"
            echo "$git_pull_output"
            echo "------------------------------------------------"
        fi
    ) # 子 shell 在这里结束。
    echo "" # 每个项目处理完后加一个空行，使总输出更清晰。
done


# --- 结束语 ---
echo "================================================="
echo "所有操作完成！"
if [ "$NEW_TOKEN" != "none" ]; then
    echo "提示: 已在每个修改过的 .git 目录中创建了 config.bak 备份文件。"
fi
echo "================================================="