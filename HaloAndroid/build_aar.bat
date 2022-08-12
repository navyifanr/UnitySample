@if "%DEBUG%" == "" @echo off
@rem ##########################################################################
@rem
@rem  build unity aar script for Windows
@rem
@rem ##########################################################################
@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

set argC=0
for %%x in (%*) do Set /A argC+=1
set count=%argC%

goto start
@rem 注意，注释使用 rem, 尽量不要双冒号，如果是在复合语句里面使用，有可能警告“系统找不到指定驱动器”
@rem 假设文件为C:\Documents and Settings\jinsun\桌面\ParseSinglePkgs.bat
@rem    %0        C:\Documents and Settings\jinsun\桌面\ParseSinglePkgs.bat
@rem    %~dp0 C:\Documents and Settings\jinsun\桌面\
@rem    %cd%   C:\Documents and Settings\jinsun\桌面
@rem    %~nx0   ParseSinglePkgs.bat
@rem    %~n0     ParseSinglePkgs
@rem    %~x0     .bat
:start

REM if %count% LSS 1 (
REM         echo USAGE: %0 [unityProjectPath]
REM         echo    or: %0 [unityProjectPath] [versionName]
REM         echo e.g: %0 D:\AndroidStudio\v1.6.3_test
REM         echo  or: %0 D:\AndroidStudio\v1.6.3_test 1.6.00
REM         goto END
REM     )

SET myDir=%cd%
@rem echo %myDir%

SET localPropFile=%myDir%\local.properties
@rem echo %localPropFile%
if not exist %localPropFile% (
        echo Error: current path: %myDir% not exist local.properties file
        goto END
    )

set gradlewFile=%myDir%\gradlew.bat
if not exist %gradlewFile% (
        echo Error: current path: %myDir% not exist gradlew.bat file
        goto END
    )

set gradlePath=%myDir%\gradle
if not exist %gradlePath% (
        echo Error: current path: %myDir% not exist gradle folder
        goto END
    )

REM set manifestFile=%myDir%\unity\AndroidManifest.xml
REM if not exist %manifestFile% (
REM         echo Error: current path: %myDir%\unity not exist AndroidManifest.xml file
REM         goto END
REM     )

set path=%myDir%
REM set path=%1
@rem echo unity path: %path%
set lib_path=%path%\unityLibrary
@rem echo path=%path%, lib_path=%lib_path%
if exist %lib_path% (
        @rem echo This is Unity Library!
        @rem 后缀加上 nul 是关闭拷贝成功的提示
        copy /y %localPropFile% %path% >nul
        copy /y %gradlewFile% %path% >nul
        @rem xcpoy 不能直接拷贝整个文件夹，只能单个文件拷贝
        @rem 有可能 报'xcopy' 不是内部或外部命令，也不是可运行的程序
        @rem xcopy %gradlePath% %path% /s/e/h/i
        @rem if %errorlevel% neq 0 (
        @rem    echo "Try add 'C:\Windows\System32' system path"
        @rem    goto END
        @rem )
        if not exist %path%\gradle md %path%\gradle
        if not exist %path%\gradle\wrapper md %path%\gradle\wrapper
        copy /y %myDir%\gradle\wrapper\gradle-wrapper.jar %path%\gradle\wrapper\gradle-wrapper.jar >nul
        copy /y %myDir%\gradle\wrapper\gradle-wrapper.properties %path%\gradle\wrapper\gradle-wrapper.properties >nul
REM         copy /y %manifestFile% %path%\unityLibrary\src\main >nul
    ) else (
        echo Error: please input correct Unity Library path!
        goto END
    )

cd %path%
call gradlew.bat unityLibrary:build && (goto succeed) || goto failed

:succeed
set arrLibSrcFile=%lib_path%\build\outputs\aar\unityLibrary-release.aar
set arrLibTargetPath=%myDir%\launcher\libs

cd %arrLibTargetPath%
@rem 设置unity aar名字
set version=%2
if "%version%"=="" (
    set "unityAARName=unityLibrary-v1.0.00.aar"
) else (
    set "unityAARName=unityLibrary-v%2.aar"
)
@rem echo unity lib aar name-before: %unityAARName%
call :getUnityAARName
@rem echo unity lib aar name-after: %unityAARName%

@rem 拷贝、替换 aar和重命名
copy %arrLibSrcFile% %arrLibTargetPath% >nul
if exist %unityAARName% Del /q %unityAARName%
Ren unityLibrary-release.aar %unityAARName%
@rem 打开文件夹
start explorer %arrLibTargetPath%
echo Build %unityAARName% succeed and copy to target path, please check it...
cd %myDir%
@rem remove unity library from settings.gradle
call :removeUnityModule
goto END

:failed
echo Error: gradle build Unity aar failed!
goto END

:getUnityAARName
for %%i in (*.*) do (
   @rem 避免找不到 findstr 命令，此处直接用全路径
   echo %%i|C:\Windows\System32\findstr.exe "unityLibrary" >nul && (
       @rem echo %%i has Unity
       SET "unityAARName=%%i"
   ) || (
       @rem echo %%i do not has Unity
   )
)
goto:eof

:removeUnityModule
@echo off&setlocal enabledelayedexpansion
for /f "eol=* tokens=*" %%i in (settings.gradle) do (
echo %%i|C:\Windows\System32\findstr.exe "unityLibrary" >nul && (
   echo Found the unity include!
) || (
   set content=%%i
   echo !content!>>$)
)
move $ settings.gradle
@RD /S /Q unityLibrary
goto:eof

:END
cd %myDir%
