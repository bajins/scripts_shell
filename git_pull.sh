#!/bin/bash
# Shebang: 这是一个特殊的指令，告诉操作系统使用哪个解释器来执行这个脚本。
# `/bin/bash` 表示使用 Bash shell。

# ==============================================================================
# Hybrid Git Project Batch Processor
#
# 功能:
#   该脚本是一个强大的工具，支持两种运行模式，兼具易用性、自动化能力和幂等性。
#
#   1. 交互模式 (Interactive Mode):
#      - 触发方式: 直接运行脚本，不带任何命令行参数。
#      - 特点: 脚本会像向导一样提示用户，且支持读取脚本内的“预设配置”。
#
#   2. 参数模式 (Argument/Scripting Mode):
#      - 触发方式: 运行时在脚本名后跟随参数。
#      - 特点: 适合集成到 CI/CD 或定时任务中。
#
#
# --- 用法 ---
#   ./git_pull.sh [TOKEN] [DIRECTORY] [PROXY]
#
#   特殊参数:
#     <TOKEN>: 传入 "none" 可跳过 Token 替换。
# ==============================================================================

# ==============================================================================
# 用户配置区域 (在此处填入默认值，避免每次重复输入)
# ==============================================================================
# 1. 预设 Token: 如果不想每次都输入，请填入 (例如 "ghp_xxxx")。留空则在运行时询问。
DEFAULT_TOKEN=""

# 2. 预设 目录: 默认为当前目录 "."。可填入绝对路径 (例如 "/data/projects")。
DEFAULT_DIR=""

# 3. 预设 代理: 例如 "socks5://127.0.0.1:10808"。留空则不设置。
DEFAULT_PROXY=""
# ==============================================================================


# --- 第 1 部分: 模式选择与配置获取 ---
# 这里的核心是判断脚本是如何被调用的，并据此获取配置信息。

# `$#` 是一个Bash的特殊变量，它存储了传递给脚本的命令行参数的数量。
if [ "$#" -eq 0 ]; then
    # --- 交互模式 ---
    # 如果没有提供任何参数，脚本将进入此代码块。
    
    echo "未检测到命令行参数，进入交互模式..."
    echo "-------------------------------------------------"

    # 1.1: 获取 Token
    # 优先检查是否有预设值 (DEFAULT_TOKEN)。
    if [ -n "$DEFAULT_TOKEN" ]; then
        echo "检测到预设 Token: [已隐藏]"
        # `read` 命令用于从标准输入读取用户输入。
	    # -s (silent): 使输入内容不显示在屏幕上。这是处理密码、Token等敏感信息的最佳实践。
	    # -p (prompt): 在同一行显示提示信息，而不是在新的一行。
        read -sp "请输入新 Token (直接回车将使用预设值): " NEW_TOKEN_INPUT
    else
        read -sp "请输入新 Token (如果不需要替换，请直接按 Enter): " NEW_TOKEN_INPUT
    fi
    echo "" # `read -s` 不会自动换行，手动补一个空行

    # 处理变量: 嵌套的参数扩展。
    # `${VAR:-default}` 是Bash强大的 "参数扩展" 功能。
    # 它的意思是：如果变量 `VAR` 已设置且非空，则使用它的值；否则，使用 `default` 值。
    # 逻辑: 优先用输入值 -> 如果输入为空，用预设值 -> 如果预设也为空，用 "none"。
    NEW_TOKEN="${NEW_TOKEN_INPUT:-${DEFAULT_TOKEN:-none}}"


    # 1.2: 获取目标目录
    # 设置提示语中显示的默认路径
    DIR_PROMPT_DEFAULT="${DEFAULT_DIR:-.}"
    read -p "请输入要扫描的目标目录 [默认: $DIR_PROMPT_DEFAULT]: " TARGET_DIR_INPUT
    
    # 逻辑: 输入值 -> 预设值 -> 当前目录 "."
    TARGET_DIR="${TARGET_DIR_INPUT:-${DEFAULT_DIR:-.}}"


    # 1.3: 获取代理地址
    if [ -n "$DEFAULT_PROXY" ]; then
        PROXY_PROMPT_TEXT="[默认: $DEFAULT_PROXY]"
    else
        PROXY_PROMPT_TEXT="(无预设, 直接回车则不设置)"
    fi
    read -p "请输入代理地址 $PROXY_PROMPT_TEXT: " PROXY_URL_INPUT
    
    # 逻辑: 输入值 -> 预设值 (如果都为空，变量就是空字符串)
    PROXY_URL="${PROXY_URL_INPUT:-$DEFAULT_PROXY}"


    # 1.4: 操作前最终确认
    echo "-------------------------------------------------"
    echo "--- 请确认您的操作 ---"
    echo "  目标目录: $TARGET_DIR"
    
    if [ "$NEW_TOKEN" != "none" ]; then
        echo "  Token 操作: 将执行替换/注入 (输入已隐藏)"
    else
        echo "  Token 操作: 跳过替换 (保持原样)"
    fi

    # `-n` 测试字符串长度是否非零 (即，字符串不为空)。
    if [ -n "$PROXY_URL" ]; then
        echo "  Git 代理:   将设置为 $PROXY_URL"
    else
        echo "  Git 代理:   不设置"
    fi
    echo "-------------------------------------------------"
    
    read -p "是否继续执行? (直接回车默认 Yes / n): " CONFIRM
    # `${VAR:-y}`: 如果用户直接回车，默认为 "y"
    CONFIRM="${CONFIRM:-y}"
    # `tr` (translate) 命令用于字符转换。这里我们将用户输入全部转为小写，
    # 这样后续的判断就不用同时检查 'y' 和 'Y' 了，使代码更健壮。
    #CONFIRM_LOWER=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')
    
    # `[[ ... ]]` 是一个更现代、更强大的条件表达式，比 `[ ... ]` 更推荐使用。
    # 正则匹配: 允许 y, Y, yes, YES 等变体。
    if [[ ! "$CONFIRM" =~ ^[yY]([eE][sS])?$ ]]; then
        echo "操作已取消。"
        # 暂停以防窗口秒关
        read -n 1 -s -r -p "按任意键退出窗口..."
        exit 0
    fi

else
    # --- 参数模式 ---
    # 如果脚本收到了参数，则直接使用参数，不进行交互。

    echo "检测到参数，进入参数模式..."
    
    # `$1`, `$2`, `$3`... 是位置参数，分别代表第一个、第二个、第三个参数。
    NEW_TOKEN="$1"                  # 总是Token或"none"
    TARGET_DIR="${2:-.}"            # 如果为空，默认为 "."
    PROXY_URL="$3"                  # 如果未提供，则为空字符串。

fi


# --- 第 2 部分: 执行前最终检查 ---

# 2.1: 验证目标目录有效性。
# `[ ! -d ... ]`: 如果不是一个目录。
if [ ! -d "$TARGET_DIR" ]; then
    echo "错误: 目标目录 '$TARGET_DIR' 不存在或不是一个有效的目录。"
    read -n 1 -s -r -p "按任意键退出窗口..."
    exit 1 # 非零退出码表示错误
fi

# 2.2: 参数模式下的缓冲时间。
# 这给自动化场景中的用户一个最后的机会，如果发现参数错误，可以按 Ctrl+C 来中止脚本。
if [ "$#" -gt 0 ]; then # `-gt` 是 "greater than"，如果参数数量大于0
    echo "将在 3 秒后开始执行..."
    sleep 3
fi


# --- 第 3 部分: 主逻辑 - 查找并处理所有 Git 项目 ---

# 使用 `find | while read` 管道处理文件列表，能正确处理带空格的路径。
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

    # --- 替换 Token ---
    if [ "$NEW_TOKEN" != "none" ]; then
        config_file="${project_dir}/.git/config"
        
        if [ -f "$config_file" ]; then # `-f` 检查文件是否存在且为普通文件
        	# `-q` (quiet) 选项让`grep`不打印任何匹配结果，而是通过退出状态码来表明是否找到匹配。
            # 如果找到，退出码为0 (true)；否则为非0 (false)。非常适合在 `if` 语句中使用。
            # 仅处理 http/https 协议，避免误伤 ssh 协议 (git@github.com...)
            if grep -q "url = http" "$config_file"; then
            	# `sed` (Stream EDitor) 用于流式文本编辑。
            	# `-i .bak`: 这是 `sed` 的一个安全特性。`-i` 表示直接修改文件 (in-place)。
                #           后缀 `.bak` 表示在修改前，自动创建一个名为 `config.bak` 的备份文件。
                # `-e` 选项执行链式操作，确保操作的 "幂等性" (Idempotency)。
                # `s|regex|replacement|g`: 这是替换命令。
                #   - `s`: substitute (替换)。
                #   - `|`: 分隔符。通常用 `/`，但当内容中包含 `/` (如URL)时，用其他字符如`|`或`#`可避免复杂的转义。
                #   - `g`: global，替换行内所有匹配项，而不仅仅是第一个。
                # 步骤 1: s|https://[^@]*@|https://|g
                #   - 正则 `[^@]*@` 匹配 `https://` 后直到 `@` 的所有内容。
                #   - 作用: 无论现有链接是 `https://oldToken@...` 还是 `https://user:pass@...`，统统清理为干净的 `https://`。
                # 步骤 2: s|https://|https://${NEW_TOKEN}@|g
                #   - 作用: 在清理后的 `https://` 后面插入新的 Token。
                
                # 兼容性检查: macOS (BSD sed) 和 Linux (GNU sed) 对 -i 参数的处理不同。
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    # macOS: -i 后面必须强制跟备份扩展名
                    sed -i .bak -e "s|https://[^@]*@|https://|g" -e "s|https://|https://${NEW_TOKEN}@|g" "$config_file"
                else
                    # Linux: 通常写法
                    sed -i.bak -e "s|https://[^@]*@|https://|g" -e "s|https://|https://${NEW_TOKEN}@|g" "$config_file"
                fi
                echo "  [Token]  成功更新/注入 Token。"
            else
                echo "  [Token]  非 HTTP/HTTPS 协议 (可能是 SSH)，跳过 Token 替换。"
            fi
        else
            echo "  [警告] 未找到 .git/config 文件，跳过 Token 替换。"
        fi
    fi

    # --- Git 操作 ---
    # `( ... )`: 开启子 Shell (subshell)。
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
        # 设置代理
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
            # 修复: 去掉双引号中的感叹号，避免 history expansion 错误
            echo "  [Pull]   [x] 更新失败 (详情如下):" 
            # 如果更新失败，打印之前捕获的详细输出，方便用户诊断问题。
            echo "-------------------- Git 输出 --------------------"
            # 打印错误详情，每行前面加缩进，只显示前10行
            #echo "$git_pull_output" | head -n 10 | sed 's/^/    | /'
            echo "$git_pull_output"
            echo "------------------------------------------------"
        fi
    ) # 子 Shell 结束，自动切回原目录
    echo "" # 每个项目处理完后加一个空行，使总输出更清晰。
done


# --- 结束语与暂停 ---
echo "================================================="
echo "所有操作完成！"
if [ "$NEW_TOKEN" != "none" ]; then
    echo "提示: 已在修改过的 .git 目录中创建 config.bak 备份。"
fi
echo "================================================="

# 防止窗口关闭
# 很多时候在 Windows 上直接运行脚本，执行完窗口会瞬间消失。
# `read -n 1`: 只读取 1 个字符，用户按任意键即继续。
# `-s`: Silent，不回显按下的键。
# `-r`: Raw mode，不转义特殊字符。
# `-p`: Prompt，提示语。
echo ""
read -n 1 -s -r -p "按任意键退出窗口..."
echo ""