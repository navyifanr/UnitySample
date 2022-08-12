#!/bin/bash

#获取Unity AAR 文件名 (在原来放 AAR 目录下获取，必须在调用前声明，否则会找不到)
getUnityAARFileName(){
  nameList=`ls -1`
  unityAARName="$1"  #默认名字
  while read line
  do
      if [[ "$line" == *unityLibrary* ]]; then
#        echo "存在unity aar"
        unityAARName=$line
      fi
  done <<< "${nameList}"  #注意加{} 是为了避免换行符丢失
  echo "$unityAARName"
}

#remove unity module from settings.gradle
removeUnityModule(){
  # Mac 系统，sed 命令需要增加一个备份文件
  sed -i '.copy' "/unityLibrary/d" "$mydir/settings.gradle"
  rm "$mydir/settings.gradle.copy"
  rm -rf "$mydir/unityLibrary"
}

mydir=$(cd `dirname $0`; pwd)
#echo "当前脚本路径：$mydir"

localPropFile="$mydir/local.properties"
if [ ! -f "$localPropFile" ];then
    echo "error: 当前脚本目录${mydir}不存在local.properties文件"
    exit
fi

sdkPath=""
while read line || [[ -n ${line} ]]
do
    if [[ "$line" =~ ^sdk.dir* ]];then
        sdkPath=$line
        break
    fi
done < $localPropFile

strSplit=(${sdkPath//=/ })
sdkPath=${strSplit[1]}
if [ ! -d "$sdkPath" ];then
    echo "error: ${localPropFile}文件配置的Android sdk路径不对，请配置正确的路径！"
    exit
fi

gradlewFile="$mydir/gradlew"
if [ ! -f "$gradlewFile" ];then
    echo "error: 当前脚本目录${mydir}不存在gradlew文件"
    exit
fi

gradlePath="$mydir/gradle"
if [ ! -d "$gradlePath" ];then
    echo "error: 当前脚本目录${mydir}不存在gradle资源"
    exit
fi

#manifestFile="$mydir/unity/AndroidManifest.xml"
#if [ ! -f "$manifestFile" ];then
#    echo "error: 当前脚本目录${mydir}/unity 不存在AndroidManifest.xml文件"
#    exit
#fi

path="$mydir"
#path="$1"
lib_path="$path/unityLibrary"
#echo "path=$path, lib_path=$lib_path"
if [ -d $lib_path ]
then
    #echo "是Unity工程目录"
    cp -f $localPropFile $path
    cp -f $gradlewFile $path
    cp -rf $gradlePath $path
#    cp -f $manifestFile "$path/unityLibrary/src/main"
else 
    echo "error: 请输入正确的Unity工程目录"
fi

echo "path: $path"
cd $path
./gradlew unityLibrary:build


if [ $? -ne 0 ];then
    echo "error: gradle编译生成arr失败！"
    exit 1;
else
    arrLibSrcFile="${lib_path}/build/outputs/aar/unityLibrary-release.aar"
    arrLibTargetPath="${mydir}/launcher/libs"

    cd $arrLibTargetPath
    #设置 aar 名字
    if [ $# -ge 2 ];then
        defAARName="unityLibrary-v$2.aar"
    else
        defAARName="unityLibrary-v1.0.00.aar"
    fi
    #echo $defAARName
    unityAARName=`getUnityAARFileName "$defAARName"`
    #echo $unityAARName
    # 拷贝、移动和重命名
    cp -f $arrLibSrcFile $arrLibTargetPath
    mv unityLibrary-release.aar $unityAARName
    # Mac 打开指定文件夹
    open $arrLibTargetPath
    echo "生成aar包成功，并已拷贝到指定项目的对应文件夹上，请检查是否正确~"
    removeUnityModule
fi


