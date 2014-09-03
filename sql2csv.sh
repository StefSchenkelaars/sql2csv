#!/bin/bash
# Converts .sql files into .csv files. Make sure mysql and zip are installed.
# on ubuntu: sudo apt-get install mysql-server zip
# This script uses a database called sql_to_csv_convertion
# so make sure you DO NOT HAVE data in a database called sql_to_csv_convertion
#
# written by Stef Schenkelaars Sep - 2014

while true; do
  # Ask for mysql user
  read -p "MySql user: " mysql_user

  # Ask for mysql password
  echo -n "MySql $mysql_user password: "
  read -s mysql_password
  echo

  current_path=$(pwd)

  # Loop through files
  for sql_file in *.sql; do

      echo "-- Converting $sql_file"
      filename="${sql_file%%.*}"

      # Recreate database
      echo "   Importing"
      mysql -u $mysql_user --password=$mysql_root_password -e "drop database if exists sql_to_csv_convertion;" || break;
      mysql -u $mysql_user --password=$mysql_root_password -e "create database sql_to_csv_convertion;" || break;

      # Populate database with file
      mysql -u $mysql_user --password=$mysql_root_password sql_to_csv_convertion < $sql_file || break;

      # Create export folder (only basename of file)
      mkdir "$filename" || break;

      # Make it accessable for mysql
      chmod 777 "$filename" || break;

      # Export into folder
      echo "   Exporting"
      mysqldump -u $mysql_user --password=$mysql_root_password --fields-optionally-enclosed-by='"' --fields-terminated-by=',' --tab ./"$filename" sql_to_csv_convertion || break;

      # Get headers and create combined .csv file
      for txt_file in $filename/*.txt; do
        txt_filename_with_folder="${txt_file%%.*}"
        txt_filename=$(basename "$txt_file") || break;
        txt_basename="${txt_filename%%.*}"
        mysql -u $mysql_user --password=$mysql_root_password -e "SELECT GROUP_CONCAT(COLUMN_NAME SEPARATOR ',') FROM INFORMATION_SCHEMA.COLUMNS WHERE table_schema='sql_to_csv_convertion' and table_name='$txt_basename' INTO OUTFILE '$current_path/$txt_filename_with_folder.header' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '' ESCAPED BY '' LINES TERMINATED BY '\n';" || break;
        cat "$txt_filename_with_folder.header" "$txt_filename_with_folder.txt" > "$txt_filename_with_folder.csv" || break;
      done

      # Remove temporary .header, .txt and .sql files
      rm $filename/*.txt || break;
      rm $filename/*.header || break;
      rm $filename/*.sql || break;

      # Create zip
      zip -r -q $filename.zip $filename/ || break;

      # Reduce permissions
      chmod 755 "$filename" || break;
  done

  # Drop database
  mysql -u root --password=$mysql_root_password -e "drop database if exists sql_to_csv_convertion;" || break;
  break;
done
