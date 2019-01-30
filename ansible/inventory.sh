#!/bin/bash

function print_list()
{

LG=""
LM=""
TR=0
IT=0
IM=1

FILE=inventory

LG+="{\n"
LM+="\t\"_meta\": {\n\t   \"hostvars\": {\n\t\t"

while read LINE; do
  if [[ $LINE == *\[*\]* ]]
  then

# echo ""> test.sem


     if [[ $TR == 1 ]]
     then
       LG+="],\n\t   \"vars\": {}\n\t},\n"
     fi

     LG+="\t"`echo $LINE | sed 's/\[*\([a-zA-Z_]*\).*/"\1": {/'`"\n\t   \"hosts\": ["
     TR=1
     IT=1

#TR = 1 вошли в блок
#IT = 1 первый итем в блоке
#IM = 1 первый итем в мета блоке
#LG - строка вывода основных блоков/групп
#LM - строка вывода для мета информации

  elif [[ $LINE == *" "*"="* ]]
  then

      if [[ $IT == 0 ]]
      then
        LG+=", "
      fi

      if [[ $IM == 0 ]]
      then
        LM+=",\n\t\t"
      fi


      LG+=`echo $LINE | sed 's/\(.*\)* ansible_host=.*/\"\1\"/'`
      
      LM+=`echo $LINE | sed 's/\(.*\)* ansible_host=.*/\"\1\"/'`
      LM+=": { \"ansible_host\" : \""`echo $LINE | sed 's/.*ansible_host=\(.*\)/\1/'`"\" }"

      IM=0
      IT=0
  fi
    
done < $FILE



if [[ $TR == 1 ]]
then
   LG+="],\n\t   \"vars\": {}\n\t},\n"
fi

if [[ $IM == 0 ]]
then
   LM+="\n\t   }\n\t}\n"
fi

LG+="$LM"

LG+="}\n"

echo -e $LG
echo -e $LG > test.json

#echo -e $LM
}

case "$1" in
        --list) print_list ;;
        --host) echo '{"_meta": {"hostvars": {}}}' ;;
         *)  echo "{ }" ;;
esac

