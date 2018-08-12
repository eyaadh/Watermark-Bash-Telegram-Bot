**Source and A Final Note:**

_This is an opensource development built based on bash. Follow the bellow instructions to clone this project._
*Tools used by the bot:*
1. [jq](https://stedolan.github.io/jq/)
2. [curl](https://launchpad.net/ubuntu/xenial/+package/curl)
3. [ImageMagick](https://www.imagemagick.org/script/index.php)

_Once when you are sure that you have all the requirements mentioned above installed on your system, download the latest source and extract it:_
```
wget http://bot.eyaadh.net/wmakre.tar.gz
tar -xvf wmakre.tar.gz
```
_If you are cloning the git repository:_
```
git clone https://github.com/eyaadh/Watermark-Bash-Telegram-Bot.git
```
_Now browse into the directory at which you extracted the compressed file we just downloaded and ammend/add your bot token on .tgconfig file, set the correct permission and run the core script:_
```
cd wmaker/
jq '(.config)|=(.token="your bot token")' .tgconfig > tgconfig.new
mv tgconfig.new .tgconfig
chmod 755 core.bash
./core.bash
```
_I do not have much time to ammend as per any requirements you might put forward, however I will try. Atleast it's free and it does not try to squeez money out of your pocket for a simple process unlike many other bots do. Since the source has already been shared I would suggest that you clone it and ammend it as you desire. However kindly do also have a look at my most favorite porject and always my number one priority _ @roanuedhuru\_bot _I am most of the time available at _ @botlistchat _incase you would like to throw up some sarcastic comments or feedback._

```
DO NOT BLOODY GIVE TO GET! GIVE TO INSPIRE OTHERS TO GIVE!
``` 
_Thanks,  @eyaadh_
