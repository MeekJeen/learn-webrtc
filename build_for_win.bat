@echo off

:: 获取脚本绝对路径
set script_path=%~dp0
:: 进入脚本所在目录,因为这会影响脚本中执行的程序的工作目录
set old_cd=%cd%
cd /d %~dp0

:: 启动参数声明
set debug_mode="false"

echo=
echo=
echo ---------------------------------------------------------------
echo 检查编译参数[debug/release]
echo ---------------------------------------------------------------

:: 编译参数检查 /i忽略大小写
if /i "%1"=="debug" (
    set debug_mode="true"
    goto param_ok
)
if /i "%1"=="release" (
    set debug_mode="false"
    goto param_ok
)

echo "waring: unkonow build mode -- %1, default debug"
set debug_mode="true"
goto param_ok

:param_ok

:: 提示
if /i %debug_mode% == "true" (
    echo 当前编译版本为debug版本
) else (
    echo 当前编译版本为release版本
)

:: 环境变量设置
set depot_tools_path=%script_path%depot_tools
set PATH=%depot_tools_path%;%PATH%

set GYP_GENERATORS=ninja
set GYP_MSVS_OVERRIDE_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community
set GYP_MSVS_VERSION=2017

:: 设置相关路径
:: set gn=%script_path%buildtools\win\gn.exe
:: set ninja=%script_path%buildtools\win\ninja.exe
set gn=gn
set ninja=ninja
set dispatch_path=%script_path%out

if /i %debug_mode% == "true" (
    set dispatch_path=%script_path%out\debug
) else (
    set dispatch_path=%script_path%out\release
)

:: 进入webrtc目录
cd webrtc\src

echo=
echo=
echo ---------------------------------------------------------------
echo gn生成ninja脚本
echo ---------------------------------------------------------------

:: ninja file
:: is_component_build=false   static lib
:: rtc_use_h264=true
set args=is_debug=%debug_mode%
set args=%args% target_cpu=\"x86\"
set args=%args% proprietary_codecs=true
set args=%args% enable_iterator_debugging=true
set args=%args% is_win_fastlink=true
set args=%args% use_lld=false
set args=%args% is_clang=false
set args=%args% use_rtti=false
set args=%args% rtc_build_examples=true
set args=%args% rtc_build_tools=false
set args=%args% rtc_enable_protobuf=false
set args=%args% rtc_include_tests=false

call %gn% gen %dispatch_path% --ide=vs2017 --args="%args%"

if not %errorlevel%==0 (
    echo "generate ninja failed"
    exit 1
)

echo=
echo=
echo ---------------------------------------------------------------
echo 开始ninja编译
echo ---------------------------------------------------------------

:: build
:: call %ninja% -C %dispatch_path% examples     编译指定target：examples
:: 默认编译target：default
call %ninja% -C %dispatch_path%
if not %errorlevel%==0 (
    echo "ninja build failed"  
    exit 1
)

:: 恢复工作目录
cd %old_cd%

echo=
echo=
echo ---------------------------------------------------------------
echo 完成！
echo ---------------------------------------------------------------