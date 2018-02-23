# rvdata2Parserf
This is a ruby script that is a fork of https://gist.github.com/ekoneko/9658609, designed to unpack and repack (or parse or whatever terminology you wish to use) .rvdata2 files associated with RPG Maker.
There are 3 types of files that I have found, Script, Object, and Map. The goal of this script is to be able to handle all 3; with no guarantee that it will 
work or not break anything.
## Installation
To install, first install the rpg-maker-rgss3 gem, https://rubygems.org/gems/rpg-maker-rgss3/versions/1.02.0, with
```
gem install rpg-maker-rgss3
```
Once installed the script *should* work for all objects, but if it is caught in a loop of trying to create a object, then you will have to go
to https://github.com/bluepixelmike/rpg-maker-rgss3/, find the code which corresponds to the object it is trying to create, and copy-paste 
 it into the script itself. 
 ## Console Output
 You will find lots of debugging print and puts statements either not commented out or commented out; I left these in there for your benefit
  if you wish to understand how the code is working, as I have found them to be very useful. Ignore them if you wish or just comment out
  all of the output statements.
## Program Output
This script will output scripts into a folder `./<FileName>_exports/` and output object files into `./<FileName>_exports.yaml`; do not edit these filenames if you 
have not modified the script itself. When repacking it specifically looks at these types of filenames.
## Usage
```
ruby rvdata2Parser.rb 'topdir/dir/dir2/..../fileordir' 'unpack/pack' 'script/object/map'
```
You must type the full filename with the full directory to the file when asking the program to repack or unpack that file.
## Thanks
I would like to thank the following

- ekoneko for providing the inital script
- Stackoverflow user marcus erronius with https://stackoverflow.com/questions/11728120/marshaling-and-undefined-attributes-classes
- HBGames.org users: vgvgf, Raku, and trebor777 for figuring out the implementation of the RPG::Table object http://www.hbgames.org/forums/viewtopic.php?t=49838#

