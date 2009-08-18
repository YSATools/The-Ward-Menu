#!/bin/bash
rm db/devel*.sqlite3
rake db:create
rake db:migrate
