#!/bin/bash
# Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


if [ -z "$@" ]; then
  dirs=$(pwd)
else
  dirs=$@
fi

original_wd=$(pwd)

for var in "$dirs"; do

  if [ ! -d $var ] ; then
    echo "$var is not a directory. Skipping"
    continue
  fi

  cd $var

  year=$(date "+%Y")
  last_year=$(($year - 1))

  search="Copyright (c) 1999-${last_year}"
  replacement="Copyright (c) 1999-${year}"

  echo "About to scan $(pwd) for files to replace '$search' with '$replacement'"

  for file in $(grep -R --files-with-matches "$search" .); do
    echo "Replacing date in $file"
    sed -i '' -e "s/$search/$replacement/g" $file
  done

  cd $original_wd
done